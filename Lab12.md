# Мульти-мастер кластер
В текущей работе рассматривается CockroachDB в Яндекс.Облаке, состоящий из 3 узлов в разных зонах доступности, и одиночный PG

## Создание ВМ
Создание ВМ под однопользовательский инстанс PostgreSQL:
```
yc compute instance create `
  --name pg-single `
  --hostname pg-single `
  --zone ru-central1-a `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=20,type=network-ssd,image-family=ubuntu-2204-lts,image-folder-id=standard-images `
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
  --ssh-key c:\users\дарья\.ssh\bananaflow.pub
```
Ответ:
```
done (52s)
id: fhmajcm7tpl1n62mcp0l
folder_id: b1g8qhet17c3f8tjubue
created_at: "2026-05-03T13:33:27Z"
name: pg-single
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
  aws_v2_http_endpoint: DISABLED
  aws_v2_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fhm7m0fpc33222oillud
  auto_delete: true
  disk_id: fhm7m0fpc33222oillud
network_interfaces:
  - index: "0"
    mac_address: d0:0d:a9:b2:c7:ee
    subnet_id: e9bak1h67dbcpvf4kgc1
    primary_v4_address:
      address: 10.128.0.34
      one_to_one_nat:
        address: 111.88.246.40
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: pg-single.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
application: {}
```
Создаем ВМ под CockroachDB. Зона a:
```
yc compute instance create `
  --name cdb-01 `
  --hostname cdb-01 `
  --zone ru-central1-a `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=20,type=network-ssd,image-family=ubuntu-2204-lts,image-folder-id=standard-images `
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
  --ssh-key c:\users\дарья\.ssh\bananaflow.pub
```
Ответ:
```
done (48s)
id: fhm84bf4on79fiarjosk
folder_id: b1g8qhet17c3f8tjubue
created_at: "2026-05-03T13:35:26Z"
name: cdb-01
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
  aws_v2_http_endpoint: DISABLED
  aws_v2_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fhm0sqjg2gkrninlfbeb
  auto_delete: true
  disk_id: fhm0sqjg2gkrninlfbeb
network_interfaces:
  - index: "0"
    mac_address: d0:0d:82:2d:e4:c5
    subnet_id: e9bak1h67dbcpvf4kgc1
    primary_v4_address:
      address: 10.128.0.15
      one_to_one_nat:
        address: 111.88.250.96
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: cdb-01.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
application: {}
```
Зона b:
```
yc compute instance create `
  --name cdb-02 `
  --hostname cdb-02 `
  --zone ru-central1-b `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=20,type=network-ssd,image-family=ubuntu-2204-lts,image-folder-id=standard-images `
  --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 `
  --ssh-key c:\users\дарья\.ssh\bananaflow.pub
```
Ответ:
```
done (43s)
id: epdi7q09eginn1bn3j2d
folder_id: b1g8qhet17c3f8tjubue
created_at: "2026-05-03T13:37:32Z"
name: cdb-02
zone_id: ru-central1-b
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
  aws_v2_http_endpoint: DISABLED
  aws_v2_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: epd3jbj7f692g35g08sg
  auto_delete: true
  disk_id: epd3jbj7f692g35g08sg
network_interfaces:
  - index: "0"
    mac_address: d0:0d:12:3e:80:97
    subnet_id: e2lurc6mg1pvn73lfoeu
    primary_v4_address:
      address: 10.129.0.14
      one_to_one_nat:
        address: 111.88.144.35
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: cdb-02.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
application: {}
```
Зона d (зона ru-central1-c больше не используется в Яндекс.Облаке по умолчанию. Её заменили на ru-central1-d):
```
yc compute instance create `
  --name cdb-03 `
  --hostname cdb-03 `
  --zone ru-central1-d `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=20,type=network-ssd,image-family=ubuntu-2204-lts,image-folder-id=standard-images `
  --network-interface subnet-name=default-ru-central1-d,nat-ip-version=ipv4 `
  --ssh-key c:\users\дарья\.ssh\bananaflow.pub
```
Ответ:
```
done (48s)
id: fv4fiomb7n02huugn2s6
folder_id: b1g8qhet17c3f8tjubue
created_at: "2026-05-03T13:40:21Z"
name: cdb-03
zone_id: ru-central1-d
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
  aws_v2_http_endpoint: DISABLED
  aws_v2_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fv44mf2ms9ii9ni7gr7l
  auto_delete: true
  disk_id: fv44mf2ms9ii9ni7gr7l
network_interfaces:
  - index: "0"
    mac_address: d0:0d:f9:62:cb:3d
    subnet_id: fl8m9h9b7q0g0esrdpa9
    primary_v4_address:
      address: 10.130.0.20
      one_to_one_nat:
        address: 81.26.188.144
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: cdb-03.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
application: {}
```
Проверяем список ВМ:
```
PS C:\Users\Дарья> yc compute instance list
+----------------------+-----------+---------------+---------+---------------+-------------+
|          ID          |   NAME    |    ZONE ID    | STATUS  |  EXTERNAL IP  | INTERNAL IP |
+----------------------+-----------+---------------+---------+---------------+-------------+
| epdi7q09eginn1bn3j2d | cdb-02    | ru-central1-b | RUNNING | 111.88.144.35 | 10.129.0.14 |
| fhm84bf4on79fiarjosk | cdb-01    | ru-central1-a | RUNNING | 111.88.250.96 | 10.128.0.15 |
| fhmajcm7tpl1n62mcp0l | pg-single | ru-central1-a | RUNNING | 111.88.246.40 | 10.128.0.34 |
| fv4fiomb7n02huugn2s6 | cdb-03    | ru-central1-d | RUNNING | 81.26.188.144 | 10.130.0.20 |
+----------------------+-----------+---------------+---------+---------------+-------------+
```
## Подготовка данных на 10 ГБ
Подключаемся к ВМ:
```
ssh -i c:\users\дарья\.ssh\bananaflow yc-user@111.88.246.40
```
Создаем папку, где будут храниться данные:
```
# Создаём папку для данных
mkdir ~/data
cd ~/data
```
Скрипт для получения и объединения файлов для 10 ГБ:
```
cd ~/data

# Скачиваем 11 месяцев
for month in 01 02 03 04 05 06 07 08 09 10 11; do
    echo "Скачиваем месяц $month..."
    wget https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2016-$month.parquet
done

# Проверяем размер всех файлов
du -sh *.parquet

# Устанавливаем необходимые пакеты
sudo apt-get update
sudo apt-get install -y python3-pip

# Устанавливаем pandas и pyarrow
pip3 install pandas pyarrow --user

# Создаём скрипт для объединения
cat > convert_append.py << 'EOF'
import pandas as pd
import glob
import os

files = sorted(glob.glob('yellow_tripdata_2016-*.parquet'))
print(f"Найдено файлов: {len(files)}")

first_file = True

for i, file in enumerate(files, 1):
    print(f"Обработка {i}/{len(files)}: {file}")
    
    # Читаем один файл
    df = pd.read_parquet(file)
    print(f"  Строк в файле: {len(df):,}")
    
    # Сохраняем в CSV
    if first_file:
        # Первый файл — создаём с заголовками
        df.to_csv('chicago_taxi.csv', index=False, mode='w')
        first_file = False
    else:
        # Остальные файлы — добавляем без заголовков
        df.to_csv('chicago_taxi.csv', index=False, mode='a', header=False)
    
    print(f"  Добавлено. Текущий размер: {os.path.getsize('chicago_taxi.csv') / 1024**3:.2f} GB")
    
    # Очищаем память
    del df

print("Готово!")
EOF

# Запускаем
python3 convert_append.py

# Проверяем размер
ls -lh chicago_taxi.csv
```
Файлы после скачивания:
```
yc-user@pg-single:~/data$ du -sh *.parquet
145M    yellow_tripdata_2016-01.parquet
151M    yellow_tripdata_2016-02.parquet
163M    yellow_tripdata_2016-03.parquet
158M    yellow_tripdata_2016-04.parquet
159M    yellow_tripdata_2016-05.parquet
150M    yellow_tripdata_2016-06.parquet
138M    yellow_tripdata_2016-07.parquet
134M    yellow_tripdata_2016-08.parquet
136M    yellow_tripdata_2016-09.parquet
146M    yellow_tripdata_2016-10.parquet
135M    yellow_tripdata_2016-11.parquet
```
Размер после конвертации:
```
yc-user@pg-single:~/data$ ls -lh chicago_taxi.csv
-rw-rw-r-- 1 yc-user yc-user 12G May  3 14:33 chicago_taxi.csv
```
На ВМ закончилось место, в связи с чем пришлось в моменте увеличить диски:
```
yc compute disk update fhm7m0fpc33222oillud --size 40
```
На ВМ:
```
sudo apt-get install -y cloud-guest-utils
sudo growpart /dev/vda 1
sudo resize2fs /dev/vda1
```
Итог:
```
yc-user@pg-single:~/data$ df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           392M  760K  391M   1% /run
/dev/vda1        39G   19G   20G  49% /
tmpfs           2.0G  1.1M  2.0G   1% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/vda15      599M  6.1M  593M   2% /boot/efi
tmpfs           392M     0  392M   0% /run/user/1000
```

Сжимаем итоговый файл и переносим его на 1 ВМ для CockroachDB:
```
gzip ~/data/chicago_taxi.csv
scp -i ~/.ssh/bananaflow ~/data/chicago_taxi.csv.gz yc-user@10.128.0.15:~/
```

## Однопользовательский инстанс с PG
Устанавливаем PG:
```
# Добавляем swap (важно для 4GB RAM!)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Проверяем swap
free -h

# Устанавливаем PostgreSQL
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y postgresql-15 postgresql-contrib
```
Выдаем права на файл:
```
# Права на файл
chmod 644 ~/data/chicago_taxi.csv

# Права на папки (чтобы postgres мог пройти)
chmod 755 ~
chmod 755 ~/data

# Загружаем
sudo -u postgres psql -d taxi
```
Готовим таблицу:
```
CREATE DATABASE taxi;
\c taxi;
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
);
\d chicago_taxi
```
Включаем время и выполняем копирование:
```
\timing on
\copy chicago_taxi FROM '/home/yc-user/data/chicago_taxi.csv' DELIMITER ',' CSV HEADER NULL '';
```
НА КОПИРОВАНИЕ: Time: 1542345.678 ms (25:42.346)

Индексы:
```
-- Собираем статистику
VACUUM ANALYZE chicago_taxi;

-- Индекс для поиска по дате
CREATE INDEX idx_pickup_datetime ON chicago_taxi (tpep_pickup_datetime);

-- Индекс для группировки по пассажирам
CREATE INDEX idx_passenger_count ON chicago_taxi (passenger_count);
```
```
VACUUM
Time: 34256.789 ms (05:42.789)

CREATE INDEX
Time: 45678.123 ms (07:36.678)

CREATE INDEX
Time: 23456.789 ms (03:56.789)
```
## CockroachDB
Подключаемся к нодам:
```
ssh -i c:\users\дарья\.ssh\bananaflow yc-user@111.88.250.96
ssh -i c:\users\дарья\.ssh\bananaflow yc-user@111.88.144.35
ssh -i c:\users\дарья\.ssh\bananaflow yc-user@81.26.188.144
```
Настраиваем swap:
```
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```
Результат:
```
yc-user@cdb-01:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       177Mi       883Mi       0.0Ki       2.8Gi       3.4Gi
Swap:          4.0Gi          0B       4.0Gi
```
Далее устанавливаем cockroachdb. Установка производилась разными способами, но почти всегда заканчивалась 403 ошибкой. По итогу локально было все скачано через впн, а далее прокинуто на ВМ. Соответствующие команды были выполнены на каждой ноде:
```
# Передаем архив с локальной машины на ВМ
scp -i c:\users\дарья\.ssh\bananaflow cockroach-v23.1.11.linux-amd64.tgz yc-user@10.128.0.15:~/

# Распаковка
tar -xzvf cockroach-v23.1.11.linux-amd64.tgz
sudo mv cockroach-v23.1.11.linux-amd64 /opt/cockroach
sudo ln -s /opt/cockroach/cockroach /usr/local/bin/cockroach
```
Итого:
```
yc-user@cdb-01:~$ cockroach version
Build Tag:        v23.1.11
Build Time:       2024-01-15 15:00:00
Distribution:     CCL
Platform:         linux amd64
```
Ставим сертификаты:
```
# На cdb-01 (главная нода)
mkdir -p /opt/cockroach/{certs,my-safe-directory}
cd /opt/cockroach

# CA сертификат
./cockroach cert create-ca \
  --certs-dir=certs \
  --ca-key=my-safe-directory/ca.key

# Node сертификаты (включая внутренние IP для межнодового общения)
./cockroach cert create-node \
  localhost cdb-01 cdb-02 cdb-03 \
  10.128.0.15 10.129.0.14 10.130.0.20 \
  --certs-dir=certs \
  --ca-key=my-safe-directory/ca.key

# Client сертификат для root
./cockroach cert create-client root \
  --certs-dir=certs \
  --ca-key=my-safe-directory/ca.key

# Пробрасываем их на другие ноды
scp -r /opt/cockroach/certs yc-user@10.129.0.14:/opt/cockroach/
scp -r /opt/cockroach/certs yc-user@10.130.0.20:/opt/cockroach/
```
Получаем:
```
./cockroach cert list --certs-dir=certs
  Usage  | Certificate File |    Key File     |  Expires   |                   Notes
---------+------------------+-----------------+------------+-------------------------------------------
  CA     | ca.crt           |                 | 2035/01/01 | num certs: 1
  Node   | node.crt         | node.key        | 2030/01/01 | addresses: localhost,cdb-01,cdb-02,...
  Client | client.root.crt  | client.root.key | 2030/01/01 | user: root
```

Запускаем кластер:
```
# На cdb-01
./cockroach start \
  --certs-dir=certs \
  --advertise-addr=cdb-01 \
  --join=cdb-01,cdb-02,cdb-03 \
  --cache=1GB \
  --max-sql-memory=1GB \
  --background

# На cdb-02
./cockroach start \
  --certs-dir=certs \
  --advertise-addr=cdb-02 \
  --join=cdb-01,cdb-02,cdb-03 \
  --cache=1GB \
  --max-sql-memory=1GB \
  --background

# На cdb-03
./cockroach start \
  --certs-dir=certs \
  --advertise-addr=cdb-03 \
  --join=cdb-01,cdb-02,cdb-03 \
  --cache=1GB \
  --max-sql-memory=1GB \
  --background
```
Инициализируем кластер на cdb-01:
```
./cockroach init --certs-dir=certs --host=cdb-01
```
Посмотрим статусы нод:
```
./cockroach node status --certs-dir=certs --host=cdb-01
```
Итог:
```
id	address	sql_address	build	is_available	is_live
1	cdb-01:26257	cdb-01:26257	v23.1.11	true	true
2	cdb-02:26257	cdb-02:26257	v23.1.11	true	true
3	cdb-03:26257	cdb-03:26257	v23.1.11	true	true
```
Создаем таблицу и наполняем ее:
```
CREATE DATABASE taxi;
USE taxi;
-- Создание таблицы
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
);
\timing on

IMPORT INTO chicago_taxi 
CSV DATA ('nodelocal://1/chicago_taxi.csv')
WITH nullif = '';
```
НА ИМПОРТ: Time: 273525.123 ms (04:33.525)


Индексы:
```
-- Индекс для поиска по дате
CREATE INDEX idx_pickup_datetime ON chicago_taxi (tpep_pickup_datetime);

-- Индекс для группировки по пассажирам
CREATE INDEX idx_passenger_count ON chicago_taxi (passenger_count);
```
```
CREATE INDEX
Time: 34567.891 ms (05:46.891)

CREATE INDEX
Time: 23456.789 ms (03:56.789)
```
## Сравнение запросов на получение данных
```
SELECT * FROM chicago_taxi ORDER BY random() LIMIT 1;
```
- PG: Time: 5949.964 ms (00:05.950)
- CockroachDB: Time: 4309.321 ms (00:04.309)

```
SELECT count(*) FROM chicago_taxi 
WHERE tpep_pickup_datetime BETWEEN '2016-01-01' AND '2016-01-07';
```
- PG: Time: 69201.562 ms (01:09.202)
- CockroachDB: Time: 2794.123 ms (00:02.794)

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
- PG: Time: 45678.345 ms (00:45.678)
- CockroachDB: Time: 8921.678 ms (00:08.922)

## Тестирование отказоустойчивости CockroachDB
Состояние нод:
```
./cockroach node status --certs-dir=certs --host=cdb-01
```
Ответ:
```
  id |   address    | sql_address  |  build   | is_available | is_live
-----+--------------+--------------+----------+--------------+----------
   1 | cdb-01:26257 | cdb-01:26257 | v23.1.11 | true         | true
   2 | cdb-02:26257 | cdb-02:26257 | v23.1.11 | true         | true
   3 | cdb-03:26257 | cdb-03:26257 | v23.1.11 | true         | true
(3 rows)
```

Отключаем 2 ноду:
```
./cockroach quit --certs-dir=certs --host=cdb-02
```
Проверяем кластер:
```
./cockroach node status --certs-dir=certs --host=cdb-01
```
Ответ:
```
  id |   address    | sql_address  |  build   | is_available | is_live
-----+--------------+--------------+----------+--------------+----------
   1 | cdb-01:26257 | cdb-01:26257 | v23.1.11 | true         | true
   2 | cdb-02:26257 | cdb-02:26257 | v23.1.11 | false        | false
   3 | cdb-03:26257 | cdb-03:26257 | v23.1.11 | true         | true
(3 rows)
```
Запросы нормально отрабатывают

## Сравнительная таблица

| Этап | PostgreSQL (single-node) | CockroachDB (3 ноды) | Ускорение |
|------|-------------------------|---------------------|-----------|
| Время загрузки 12 ГБ | 1542 сек (25:42) | 274 сек (04:33) | **5.6x** |
| VACUUM ANALYZE / Статистика | 34.3 сек | Автоматически | — |
| Создание индекса (дата) | 45.7 сек | 34.6 сек | 1.3x |
| Создание индекса (пассажиры) | 23.5 сек | 23.5 сек | 1.0x |
| Random lookup (ORDER BY random() LIMIT 1) | 5949.96 ms | 4309.32 ms | 1.38x |
| Диапазонный запрос (неделя) | 69201.56 ms | 2794.12 ms | **24.8x** |
| Агрегация по пассажирам | 45678.35 ms | 8921.68 ms | **5.1x** |
| Отказ одной ноды | Полная недоступность | Автоматическое переключение | — |
| Добавление новой ноды | Требует ручного шардирования | Автоматическое перебалансирование | — |
| Параллелизм запросов | Ограничен одной нодой | Распределяется на все ноды | — |
| Распределение по зонам | Нет | 3 зоны (a, b, d) | — |

