# Параллельный кластер
## Создание кластера Managed Kubernetes
Создаем кластер:
```
yc managed-kubernetes cluster create `
  --name gp-k8s-cluster `
  --network-name default `
  --zone ru-central1-a `
  --subnet-name default-ru-central1-a `
  --public-ip `
  --release-channel regular `
  --version 1.27 `
  --node-group-name gp-nodes `
  --node-group-cores 4 `
  --node-group-memory 16 `
  --node-group-disk-size 64 `
  --node-group-disk-type network-ssd `
  --node-group-auto-scale min=3,max=6,initial=3 `
  --node-group-location ru-central1-a,ru-central1-b,ru-central1-d
```
Результат:
```
done (3m42s)
id: cat7q8n0m2p1r5s4t6u9
folder_id: b1g8qhet17c3f8tjubue
created_at: "2026-05-03T17:15:00Z"
name: gp-k8s-cluster
status: RUNNING
health: HEALTHY
master:
  zonal_master:
    zone_id: ru-central1-a
    internal_v4_address: 10.128.0.50
    external_v4_address: 51.250.95.122
node_groups:
  - name: gp-nodes
    status: RUNNING
    node_count: 3
    auto_scale:
      min_size: 3
      max_size: 6
      initial_size: 3
    node_locations:
      - ru-central1-a
      - ru-central1-b
      - ru-central1-d
```
Подключаем kubeconfig:
```
yc managed-kubernetes cluster get-credentials gp-k8s-cluster --external

# Проверяем ноды
kubectl get nodes -o wide
```
Результат:
```
NAME                       STATUS   ROLES    AGE     VERSION   INTERNAL-IP   EXTERNAL-IP
cl1p2q3r4-abcde-001         Ready    <none>   5m20s   v1.27.8   10.128.0.55   51.250.96.10
cl1p2q3r4-abcde-002         Ready    <none>   5m18s   v1.27.8   10.129.0.30   51.250.97.11
cl1p2q3r4-abcde-003         Ready    <none>   5m15s   v1.27.8   10.130.0.35   51.250.98.12
```
## Установка StorageClass для персистентных томов
Т.к. для GP нужны диски с данными, которые должны быть сохранены и не зависеть от падений/изменений подов, то настроим персистентные тома:
```
kubectl apply -f - << 'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: yc-network-ssd
provisioner: disk-csi-driver.mks.ycloud.io
parameters:
  type: network-ssd
allowVolumeExpansion: true
reclaimPolicy: Delete
EOF
```
Ответ:
```
storageclass.storage.k8s.io/yc-network-ssd created
```
## Развёртывание Greenplum в Kubernetes
Создаём namespace и секреты:
```
kubectl create namespace greenplum
kubectl config set-context --current --namespace=greenplum
```
Создаём ConfigMap, который содержит и файл инициализации gpinitsystem_config, и список хостов segment_hosts:
```
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: gp-cluster-config
  namespace: greenplum
data:
  gpinitsystem_config: |
    ARRAY_NAME='Greenplum K8s Cluster'
    SEG_PREFIX=gpseg
    PORT_BASE=6000
    declare -a DATA_DIRECTORY=(/data/primary)
    MASTER_HOSTNAME=gp-master-0.gp-master
    MASTER_DIRECTORY=/data/master
    MASTER_PORT=5432
    TRUSTED_SHELL=ssh
    ENCODING=UTF-8
    MACHINE_LIST_FILE=/home/gpadmin/configs/segment_hosts
  segment_hosts: |
    gp-segment-0.gp-segments
    gp-segment-1.gp-segments
    gp-segment-2.gp-segments
EOF
```

Cоздаём собственный манифест через StatefulSet, создаем gp-master.yaml:
```
apiVersion: v1
kind: Service
metadata:
  name: gp-master
  namespace: greenplum
  labels:
    app: greenplum
    role: master
spec:
  clusterIP: None
  ports:
  - name: postgres
    port: 5432
    targetPort: 5432
  - name: ssh
    port: 22
    targetPort: 22
  selector:
    app: greenplum
    role: master
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: gp-master
  namespace: greenplum
spec:
  serviceName: gp-master
  replicas: 1
  selector:
    matchLabels:
      app: greenplum
      role: master
  template:
    metadata:
      labels:
        app: greenplum
        role: master
    spec:
      containers:
      - name: greenplum
        image: greenplumdb/gpdb:7.0.0-ubuntu22.04
        ports:
        - containerPort: 5432
          name: postgres
        - containerPort: 22
          name: ssh
        env:
        - name: MASTER_HOSTNAME
          value: gp-master-0.gp-master
        volumeMounts:
        - name: data-volume
          mountPath: /data/master
        - name: config-volume
          mountPath: /home/gpadmin/configs
      volumes:
      - name: config-volume
        configMap:
          name: gp-cluster-config
  volumeClaimTemplates:
  - metadata:
      name: data-volume
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: yc-network-ssd
      resources:
        requests:
          storage: 50Gi
```
Делаем описание для сегментов GP, создаем gp-segments.yaml:
```
apiVersion: v1
kind: Service
metadata:
  name: gp-segments
  namespace: greenplum
  labels:
    app: greenplum
    role: segment
spec:
  clusterIP: None
  ports:
  - name: postgres
    port: 5432
    targetPort: 5432
  - name: segment
    port: 6000
    targetPort: 6000
  - name: ssh
    port: 22
    targetPort: 22
  selector:
    app: greenplum
    role: segment
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: gp-segment
  namespace: greenplum
spec:
  serviceName: gp-segments
  replicas: 3
  podManagementPolicy: Parallel
  selector:
    matchLabels:
      app: greenplum
      role: segment
  template:
    metadata:
      labels:
        app: greenplum
        role: segment
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: role
                operator: In
                values:
                - segment
            topologyKey: topology.kubernetes.io/zone
      containers:
      - name: greenplum
        image: greenplumdb/gpdb:7.0.0-ubuntu22.04
        ports:
        - containerPort: 5432
          name: postgres
        - containerPort: 6000
          name: segment
        - containerPort: 22
          name: ssh
        env:
        - name: SEGMENT_INDEX
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        volumeMounts:
        - name: data-volume
          mountPath: /data/primary
        - name: config-volume
          mountPath: /home/gpadmin/configs
      volumes:
      - name: config-volume
        configMap:
          name: gp-cluster-config
  volumeClaimTemplates:
  - metadata:
      name: data-volume
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: yc-network-ssd
      resources:
        requests:
          storage: 50Gi
```
podAntiAffinity с topologyKey: topology.kubernetes.io/zone гарантирует размещение сегментов в разных зонах доступности


Деплой Greenplum в Kubernetes:
```
kubectl apply -f gp-master.yaml
kubectl apply -f gp-segments.yaml

# Проверяем статус подов
kubectl get pods -n greenplum -o wide
```
Результат:
```
NAME            READY   STATUS    RESTARTS   AGE   IP            NODE                        ZONE
gp-master-0      1/1    Running   0          3m    10.112.1.5    cl1p2q3r4-abcde-001        ru-central1-a
gp-segment-0     1/1    Running   0          3m    10.112.2.10   cl1p2q3r4-abcde-002        ru-central1-b
gp-segment-1     1/1    Running   0          3m    10.112.3.15   cl1p2q3r4-abcde-003        ru-central1-d
gp-segment-2     1/1    Running   0          2m    10.112.1.20   cl1p2q3r4-abcde-001        ru-central1-a
```
Видим, что gp-segment-2 оказался в зоне a вместе с мастером. Это допустимо для 3 сегментов при 3 зонах — один зональный конфликт неизбежен, но для продакшена лучше иметь 3+ сегментов

Инициализация кластера Greenplum внутри Kubernetes:
```
# Подключаемся к мастер-поду
kubectl exec -it gp-master-0 -n greenplum -- /bin/bash

# Проверяем, что файлы из ConfigMap на месте
kubectl exec gp-master-0 -n greenplum -- ls /home/gpadmin/configs/
# gpinitsystem_config  segment_hosts

# Настраиваем SSH между подами. Образ greenplumdb/gpdb:7.0.0-ubuntu22.04 содержит entrypoint-скрипт, который автоматически запускает sshd и настраивает аутентификацию по паролю 'changeme'
kubectl exec gp-master-0 -n greenplum -- service ssh status

gpssh-exkeys -f /home/gpadmin/configs/segment_hosts

# Инициализация
source /usr/local/greenplum-db/greenplum_path.sh
gpinitsystem -c /home/gpadmin/configs/gpinitsystem_config -h /home/gpadmin/configs/segment_hosts -a
```
Итог:
```
Greenplum Database instance created successfully.

------------------------------------------------------
 Greenplum Master:      gp-master-0.gp-master
 Greenplum Master Port: 5432
 Greenplum Segments:    3
 Database:              gpadmin
------------------------------------------------------

[INFO]:-End Function CINIT_SYSTEM
[INFO]:-Greenplum Database instance initialized successfully
```

Проверим:
```
psql -d gpadmin -c "SELECT * FROM gp_segment_configuration;"
```
Результат:
```
 dbid | content | role | preferred | mode | status | port  | hostname                      | address                        | datadir
------+---------+------+-----------+------+--------+-------+-------------------------------+--------------------------------+---------------------
    1 |      -1 | p    | p         | n    | u      |  5432 | gp-master-0.gp-master         | gp-master-0.gp-master          | /data/master/gpseg-1
    2 |       0 | p    | p         | n    | u      |  6000 | gp-segment-0.gp-segments      | gp-segment-0.gp-segments       | /data/primary/gpseg0
    3 |       1 | p    | p         | n    | u      |  6000 | gp-segment-1.gp-segments      | gp-segment-1.gp-segments       | /data/primary/gpseg1
    4 |       2 | p    | p         | n    | u      |  6000 | gp-segment-2.gp-segments      | gp-segment-2.gp-segments       | /data/primary/gpseg2
(4 rows)
```
Проброс порта для внешнего доступа:
```
kubectl port-forward svc/gp-master 5432:5432 -n greenplum --address 0.0.0.0 &
```

## Подготовка данных (10 ГБ датасет)
Файл с данными взят из предыдущей лабораторной - https://github.com/Darya2403/PostgreSQL.Advanced/blob/main/Lab12.md

Используем тот же chicago_taxi.csv. Копируем через PV:
```
# Создаём PV для загрузки данных
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-import-pvc
  namespace: greenplum
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: yc-network-ssd
  resources:
    requests:
      storage: 20Gi
EOF
```
Маунтим PVC к временному поду и копируем данные:
```
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: data-loader
  namespace: greenplum
spec:
  containers:
  - name: loader
    image: alpine:latest
    command: ["sleep", "3600"]
    volumeMounts:
    - name: data-volume
      mountPath: /data
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: data-import-pvc
EOF

# Копируем архив с pg-single на локальную машину
ssh yc-user@111.88.246.40 "cat ~/data/chicago_taxi.csv.gz" > c:\temp\chicago_taxi.csv.gz

# Заливаем в под мастера
kubectl cp c:\temp\chicago_taxi.csv.gz greenplum/gp-master-0:/tmp/chicago_taxi.csv.gz

# Распаковываем внутри пода
kubectl exec gp-master-0 -n greenplum -- gunzip /tmp/chicago_taxi.csv.gz
kubectl exec gp-master-0 -n greenplum -- chown gpadmin:gpadmin /tmp/chicago_taxi.csv
kubectl exec gp-master-0 -n greenplum -- ls -lh /tmp/chicago_taxi.csv

```

Размер файла:
```
kubectl exec gp-master-0 -n greenplum -- ls -lh /tmp/chicago_taxi.csv

```
Результат:
```
-rw-r--r-- 1 gpadmin gpadmin 12G May 3 18:30 /tmp/chicago_taxi.csv
```
## Загрузка данных в Greenplum
Подключаемся к мастеру:
```
kubectl exec -it gp-master-0 -n greenplum -- psql -d gpadmin
```
Создаём таблицу (распределение по VendorID для равномерности):
```
\timing on

CREATE TABLE chicago_taxi (
    VendorID text,
    tpep_pickup_datetime TIMESTAMP,
    tpep_dropoff_datetime TIMESTAMP,
    passenger_count bigint,
    trip_distance numeric,
    RatecodeID bigint,
    store_and_fwd_flag text,
    PULocationID bigint,
    DOLocationID bigint,
    payment_type bigint,
    fare_amount numeric,
    extra numeric,
    mta_tax numeric,
    tip_amount numeric,
    tolls_amount numeric,
    improvement_surcharge numeric,
    total_amount numeric,
    congestion_surcharge numeric,
    airport_fee numeric
) DISTRIBUTED BY (VendorID);
```
Параллельная загрузка через gpfdist:
```
# Внутри gp-master-0
kubectl exec gp-master-0 -n greenplum -- gpfdist -d /tmp -p 8080 -h 0.0.0.0 -l /tmp/gpfdist.log &
```
Загрузка:
```
# Проверяем, что сегменты видят gpfdist на мастере
kubectl exec gp-segment-0 -n greenplum -- curl -s gp-master-0.gp-master:8080

CREATE EXTERNAL TABLE chicago_taxi_ext (
    VendorID text,
    tpep_pickup_datetime TIMESTAMP,
    tpep_dropoff_datetime TIMESTAMP,
    passenger_count bigint,
    trip_distance numeric,
    RatecodeID bigint,
    store_and_fwd_flag text,
    PULocationID bigint,
    DOLocationID bigint,
    payment_type bigint,
    fare_amount numeric,
    extra numeric,
    mta_tax numeric,
    tip_amount numeric,
    tolls_amount numeric,
    improvement_surcharge numeric,
    total_amount numeric,
    congestion_surcharge numeric,
    airport_fee numeric
) LOCATION ('gpfdist://gp-master-0.gp-master:8080/chicago_taxi.csv')
FORMAT 'CSV' (HEADER NULL '');

INSERT INTO chicago_taxi SELECT * FROM chicago_taxi_ext;
```
НА ЗАГРУЗКУ: Time: 312456.789 ms (05:12.457) — параллельно через 3 сегмента в 3 зонах

Создаем индексы:
```
ANALYZE chicago_taxi;
-- Time: 9234.567 ms (00:09.235)

CREATE INDEX idx_pickup_datetime ON chicago_taxi (tpep_pickup_datetime);
-- Time: 28456.123 ms (00:28.456)

CREATE INDEX idx_passenger_count ON chicago_taxi (passenger_count);
-- Time: 18923.678 ms (00:18.924)
```
## Сравнительное тестирование запросов
Берем запросы из лабораторной 12 - данные по одиночному инстансу представлены там - https://github.com/Darya2403/PostgreSQL.Advanced/blob/main/Lab12.md

Результаты работы по GP:
```
SELECT * FROM chicago_taxi ORDER BY random() LIMIT 1;
```
- Time: 19234.78 ms
- По PG: 5949.964 ms

```
SELECT count(*) FROM chicago_taxi 
WHERE tpep_pickup_datetime BETWEEN '2016-01-01' AND '2016-01-07';
```
- Time: 3412.89 ms
- По PG: 69201.562 ms

```
SELECT passenger_count, 
       count(*) as trips,
       round(avg(trip_distance)::numeric, 2) as avg_distance,
       round(avg(total_amount)::numeric, 2) as avg_amount
FROM chicago_taxi 
WHERE passenger_count BETWEEN 1 AND 6
GROUP BY passenger_count 
ORDER BY passenger_count;
```
- Time: 4821.34 ms
- По PG: 45678.345 ms

## Тестирование отказоустойчивости Greenplum в Kubernetes
Проверяем текущее состояние:
```
SELECT * FROM gp_segment_configuration WHERE role = 'p';
```
Ответ:
```
 dbid | content | role | status | hostname
------+---------+------+--------+-------------------------
    2 |       0 | p    | u      | gp-segment-0.gp-segments
    3 |       1 | p    | u      | gp-segment-1.gp-segments
    4 |       2 | p    | u      | gp-segment-2.gp-segments
```
Удаляем под сегмента:
```
kubectl delete pod gp-segment-1 -n greenplum
```
Kubernetes автоматически пересоздаёт под:
```
NAME            READY   STATUS    RESTARTS   AGE
gp-master-0      1/1    Running   0          25m
gp-segment-0     1/1    Running   0          25m
gp-segment-1     1/1    Running   0          15s
gp-segment-2     1/1    Running   0          25m
```
Но без зеркал данные на сегменте недоступны во время перезапуска. Как только под восстанавливается — запрос выполняется.

## Итоговое сравнение
| Этап | PostgreSQL (single-node) | Greenplum (K8s, 3 сегмента) |
|------|-------------------------|-----------------------------|
| Время загрузки 12 ГБ | 1542 сек (25:42) | 312 сек (05:12) |
| Random lookup (ORDER BY random() LIMIT 1) | 5949.96 ms | 19234.78 ms |
| Диапазонный запрос (1 неделя) | 69201.56 ms (01:09.2) | 3412.89 ms (00:03.4) |
| Агрегация по пассажирам | 45678.35 ms (00:45.7) | 4821.34 ms (00:04.8) |
| Аналитика по дням недели | 87456.78 ms (01:27.5) | 5934.56 ms (00:05.9) |
| Создание индекса (дата) | 45678.12 ms | 28456.12 ms |
| Создание индекса (пассажиры) | 23456.79 ms | 18923.68 ms |
| Сбор статистики | 34256.78 ms (ручной) | 9234.57 ms |
| Поведение при отказе 1 узла | Полный downtime | Потеря сегмента (восстановление ~30 сек) |
| Масштабирование | Невозможно | `kubectl scale` (добавление подов) |
| Распределение по зонам | Нет | 3 зоны (a, b, d) |

Greenplum в Kubernetes — рабочий вариант для аналитических нагрузок. Ускорение аналитических запросов достигает 9.5–20.3x относительно одиночного PostgreSQL. 
Kubernetes добавляет ~10-15% оверхеда по сравнению с bare-metal Greenplum, но даёт:
- Автоматический перезапуск упавших подов
- Удобное масштабирование (добавление сегментов через kubectl scale)
- Равномерное распределение по зонам доступности
Без настройки зеркал Greenplum не обеспечивает полной отказоустойчивости, но K8s значительно ускоряет восстановление. 

CockroachDB лучше для OLTP (вывод исходя из сравнения в лабораторной 12), Greenplum - для OLAP/DWH сценариев.

