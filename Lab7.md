# PostgreSQL в Minikube
## 1. Развертывание PostgreSQL через манифест
### Создание ВМ и ее настройка
Сеть default и подсети уже существуют. Создаем ВМ:
```
yc compute instance create `
   --name postgres `
   --hostname postgres `
   --zone ru-central1-a `
   --cores 2 `
   --memory 4 `
   --create-boot-disk size=20,type=network-hdd,image-id=fd81gsj7pb9oi8ks3cvo `
   --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
   --ssh-key :\sers\дарья\.ssh\bananaflow.pub
```
Ответ:
```
done (2m35s)
id: fhmj8htcr7ore0a6vmh4
folder_id: b1gre261b41nem0okrlr
created_at: "2026-04-05T15:32:26Z"
name: postgres
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "4294967296"
  cores: "2"
  core_fraction: "100"
status: RUNNING
metadata_options:
  gce_http_endpoint: ENABLED
  aws_v1_http_endpoint: ENABLED
  gce_http_token: ENABLED
  aws_v1_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fhmd9kctfriivka4ipiu
  auto_delete: true
  disk_id: fhmd9kctfriivka4ipiu
network_interfaces:
  - index: "0"
    mac_address: d0:0d:13:44:7a:cd
    subnet_id: e9bb0pftrb755sbchmj6
    primary_v4_address:
      address: 10.128.0.17
      one_to_one_nat:
        address: 62.84.116.179
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: postgres.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V1
application: {}
```
Подключаемся под ssh:
```
ssh -i c:\users\дарья\.ssh\bananaflow yc-user@62.84.116.179
```
Выполняем следующие команды:
```
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker

# Установка kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Установка Minikube
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/local/bin/minikube

# Установка Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh

# Установка PostgreSQL клиента
sudo apt install -y postgresql-client
```
### Запуск minikube
```
# Запуск кластера с драйвером docker
minikube start --driver=docker --cpus=2 --memory=3072

# Проверка статуса
minikube status
kubectl get nodes
```
Результат:

<img width="560" height="278" alt="image" src="https://github.com/user-attachments/assets/ee6a693d-e896-459e-8716-ebfc5737766f" />

### Создание Secret, Deployment и Service для PostgreSQL
Создаем три Secret, Service и Deployment через манифест. Это минимальный набор для запуска приложения в кластере.
- Secret - хранит пароль и логин. Ссылаемся на них в Deployment через env.valueFrom
- Deployment - управляет подом PostgreSQL; создает, перезапускает, обновляет контейнер
- Service - дает стабильный адрес для подключения. Создаем ClusterIP сервис на порту 5432

В текущем манифесте Deployment используем emptyDir — это временное хранилище, которое удаляется при перезапуске пода. Поэтому для БД это не очень подходит.
Развертывание с PersistentVolume будет выполнено далее с помощью helm.

```
# Создаем директорию для манифестов
mkdir ~/postgres-k8s
cd ~/postgres-k8s

# Создаем файл с манифестами
cat > postgres-deployment.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  POSTGRES_USER: banana_user
  POSTGRES_PASSWORD: banana_pass_123
  POSTGRES_DB: banana_db
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:14-alpine
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: POSTGRES_USER
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: POSTGRES_PASSWORD
            - name: POSTGRES_DB
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: POSTGRES_DB
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgres-storage
          emptyDir: {}
EOF

# Применяем конфигурацию
kubectl apply -f postgres-deployment.yaml
```

### Проверка, что база данных поднимается и отвечает на подключения
```
# Проверяем созданные ресурсы
kubectl get secrets
kubectl get svc
kubectl get deployments
```
<img width="843" height="337" alt="image" src="https://github.com/user-attachments/assets/77112397-78d3-4469-b896-d7d709aada48" />


Проверим под:
```
yc-user@postgres:~/postgres-k8s$ kubectl get pods
NAME                                   READY   STATUS    RESTARTS   AGE
postgres-deployment-6f59c6d848-2ssp5   1/1     Running   0          108s
yc-user@postgres:~/postgres-k8s$ kubectl describe pod -l app=postgres
Name:             postgres-deployment-6f59c6d848-2ssp5
Namespace:        default
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       Sun, 05 Apr 2026 15:48:45 +0000
Labels:           app=postgres
                  pod-template-hash=6f59c6d848
Annotations:      <none>
Status:           Running
IP:               10.244.0.3
IPs:
  IP:           10.244.0.3
Controlled By:  ReplicaSet/postgres-deployment-6f59c6d848
Containers:
  postgres:
    Container ID:   docker://f15be3275cc4c28b95382f845741d7cbdc1c0bad32372e64aeeb46160d0b1902
    Image:          postgres:14-alpine
    Image ID:       docker-pullable://postgres@sha256:64ce25a0bb68e598edc3944f2f58f39d1e8641755baa4ba5f7ddfa142ed85c63
    Port:           5432/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sun, 05 Apr 2026 15:48:57 +0000
    Ready:          True
    Restart Count:  0
    Environment:
      POSTGRES_USER:      <set to the key 'POSTGRES_USER' in secret 'postgres-secret'>      Optional: false
      POSTGRES_PASSWORD:  <set to the key 'POSTGRES_PASSWORD' in secret 'postgres-secret'>  Optional: false
      POSTGRES_DB:        <set to the key 'POSTGRES_DB' in secret 'postgres-secret'>        Optional: false
    Mounts:
      /var/lib/postgresql/data from postgres-storage (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-sj8rt (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
Volumes:
  postgres-storage:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:
    SizeLimit:  <unset>
  kube-api-access-sj8rt:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  116s  default-scheduler  Successfully assigned default/postgres-deployment-6f59c6d848-2ssp5 to minikube
  Normal  Pulling    116s  kubelet            spec.containers{postgres}: Pulling image "postgres:14-alpine"
  Normal  Pulled     106s  kubelet            spec.containers{postgres}: Successfully pulled image "postgres:14-alpine" in 10.002s (10.002s including waiting). Image size: 272360631 bytes.
  Normal  Created    104s  kubelet            spec.containers{postgres}: Container created
  Normal  Started    104s  kubelet            spec.containers{postgres}: Container started
```
Подключаемся к PostgreSQL:
```
# Пробрасываем порт в фоне
kubectl port-forward service/postgres-service 5432:5432 &

# Подключаемся к БД
psql -h localhost -p 5432 -U banana_user -d banana_db -W

# Делаем SELECT после успешного входа
SELECT 'PostgreSQL is running!' AS status;
```
<img width="977" height="381" alt="image" src="https://github.com/user-attachments/assets/8506b3c1-e04e-4ff3-9bca-4aa89a6e46ed" />

### Масштабирование
Масштабируемся до 3 подов:
```
kubectl scale deployment postgres-deployment --replicas=3
kubectl get pods
```

Результат масштабирования:

<img width="1011" height="180" alt="image" src="https://github.com/user-attachments/assets/cb8dd23a-1268-4908-9d44-17304cb27d36" />

Основная проблема масштабирования через обычный Deployment с replicas: 3 заключается в том, что все три пода будут пытаться работать как самостоятельные мастер-ноды, каждая со своей копией данных на временном хранилище. Для баз данных правильно использовать StatefulSet, который обеспечивает стабильные имена подов (postgres-0, postgres-1, postgres-2), постоянные тома (PVC) и предсказуемый порядок запуска. Именно поэтому попробуем использовать Helm-чарт Bitnami, который как раз разворачивает PostgreSQL с правильной архитектурой: один primary и несколько read replicas на базе StatefulSet, что позволяет безопасно масштабировать нагрузку на чтение.

## 2. Развертывание PostgreSQL через Helm
Развернем PostgreSQL через Helm с использованием StatefulSet и настроим архитектуру replication (1 primary + 2 read replicas), что обеспечит не только масштабируемость, но и согласованность данных в отличие от простого replicaCount: 3

```
# Удаляем старый deployment
kubectl delete deployment postgres-deployment

# Удаляем старый service
kubectl delete service postgres-service

# Создаем helm-values.yaml, где прописываем настройки чарта
cat > ~/postgres-k8s/helm-values.yaml << 'EOF'
architecture: replication

primary:
  replicaCount: 1
  persistence:
    size: 1Gi

readReplicas:
  replicaCount: 2
  persistence:
    size: 1Gi

auth:
  username: banana_user
  password: banana_pass_123
  database: banana_db
  replicationPassword: replica_pass_123

postgresql:
  image:
    tag: 14.11.0
EOF

# Устанавливаем helm чарт с PostreSQL с values, заданными выше (https://artifacthub.io/packages/helm/bitnami/postgresql/14.0.0)
helm install my-release oci://registry-1.docker.io/bitnamicharts/postgresql \
  -f ~/postgres-k8s/helm-values.yaml

# Смотрим статус подов
kubectl get pods

# Смотрим Helm релизы
helm list

# Смотрим StatefulSet
kubectl get statefulset

# Смотрим сервисы
kubectl get svc
```
Результат:

<img width="1188" height="490" alt="image" src="https://github.com/user-attachments/assets/eec1d99e-0ae7-423a-8c5e-9d4af0078950" />

Заходим на под и выполняем SELECT:
```
kubectl exec -it my-release-postgresql-primary-0 -- psql -U banana_user -d banana_db
SELECT 'PostgreSQL is running!' AS status;
```
<img width="1042" height="247" alt="image" src="https://github.com/user-attachments/assets/30ca0d93-c15b-43a1-bac6-9a77ede01ae0" />


