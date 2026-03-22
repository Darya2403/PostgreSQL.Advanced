# Постоение кластера Patroni
## 1. Создание 3 виртуальных машин для etcd и 3 виртуальных машин для Patroni
Устанавливаем CLI по гайду: https://yandex.cloud/ru/docs/cli/operations/install-cli#windows_1

iex (New-Object System.Net.WebClient).DownloadString('https://storage.yandexcloud.net/yandexcloud-yc/install.ps1')
<img width="1345" height="272" alt="image" src="https://github.com/user-attachments/assets/329f7583-71ea-475d-9624-f6ac776b9bff" />
Далее переходим по ссылке, получаем oauth token, указываем его и выбираем необходимое облако для работы
Начинаем создавать ВМ, сеть default и подсети уже существуют
### etcd-1
```
 yc compute instance create `
>>   --name etcd-1 `
>>   --hostname etcd-1 `
>>   --zone ru-central1-a `
>>   --cores 2 `
>>   --memory 4 `
>>   --create-boot-disk size=20,type=network-hdd,image-family=ubuntu-2204-lts,image-folder-id=standard-images `
>>   --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
>>   --ssh-key C:\Users\Дарья\.ssh\bananaflow.pub
>>
done (42s)
id: fhmkkolkvm74ang8n23i
folder_id: b1gngjhbpqr6aobjrr65
created_at: "2026-03-22T16:41:33Z"
name: etcd-1
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
  device_name: fhmntep2ih6bm04jg5dl
  auto_delete: true
  disk_id: fhmntep2ih6bm04jg5dl
network_interfaces:
  - index: "0"
    mac_address: d0:0d:14:a6:2b:4f
    subnet_id: e9bvfou54vgovfvc1dkq
    primary_v4_address:
      address: 10.128.0.25
      one_to_one_nat:
        address: 158.160.118.54
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: etcd-1.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
application: {}
```

### etcd-2
```
 yc compute instance create `
>>   --name etcd-2 `
>>   --hostname etcd-2 `
>>   --zone ru-central1-a `
>>   --cores 2 `
>>   --memory 4 `
>>   --create-boot-disk size=20,type=network-hdd,image-family=ubuntu-2204-lts,image-folder-id=standard-images `
>>   --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
>>   --ssh-key C:\Users\Дарья\.ssh\bananaflow.pub
>>
done (30s)
id: fhm0the5qt54kotm0d4s
folder_id: b1gngjhbpqr6aobjrr65
created_at: "2026-03-22T16:46:22Z"
name: etcd-2
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
  device_name: fhm271qb7ob10fpjdkga
  auto_delete: true
  disk_id: fhm271qb7ob10fpjdkga
network_interfaces:
  - index: "0"
    mac_address: d0:0d:ec:5c:5d:74
    subnet_id: e9bvfou54vgovfvc1dkq
    primary_v4_address:
      address: 10.128.0.23
      one_to_one_nat:
        address: 158.160.107.62
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: etcd-2.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
application: {}
```

### etcd-3
```
yc compute instance create `
>>   --name etcd-3 `
>>   --hostname etcd-3 `
>>   --zone ru-central1-a `
>>   --cores 2 `
>>   --memory 4 `
>>   --create-boot-disk size=20,type=network-hdd,image-family=ubuntu-2204-lts,image-folder-id=standard-images `
>>   --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
>>   --ssh-key C:\Users\Дарья\.ssh\bananaflow.pub
>>
done (44s)
id: fhmsbtfgcsjd4rfbq1tt
folder_id: b1gngjhbpqr6aobjrr65
created_at: "2026-03-22T16:48:06Z"
name: etcd-3
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
  device_name: fhmflrfbfh36akfeql32
  auto_delete: true
  disk_id: fhmflrfbfh36akfeql32
network_interfaces:
  - index: "0"
    mac_address: d0:0d:1c:5f:5f:06
    subnet_id: e9bvfou54vgovfvc1dkq
    primary_v4_address:
      address: 10.128.0.36
      one_to_one_nat:
        address: 158.160.58.139
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: etcd-3.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
application: {}
```

### pg-1
```
 yc compute instance create `
>>   --name pg-1 `
>>   --hostname pg-1 `
>>   --zone ru-central1-a `
>>   --cores 2 `
>>   --memory 4 `
>>   --create-boot-disk size=20,type=network-hdd,image-family=ubuntu-2204-lts,image-folder-id=standard-images `
>>   --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
>>   --ssh-key C:\Users\Дарья\.ssh\bananaflow.pub
>>
done (1m23s)
id: fhm9l15o4nrsgai2tvru
folder_id: b1gngjhbpqr6aobjrr65
created_at: "2026-03-22T16:51:19Z"
name: pg-1
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
  device_name: fhmmjns2501qijl9c9h4
  auto_delete: true
  disk_id: fhmmjns2501qijl9c9h4
network_interfaces:
  - index: "0"
    mac_address: d0:0d:9a:84:b8:25
    subnet_id: e9bvfou54vgovfvc1dkq
    primary_v4_address:
      address: 10.128.0.19
      one_to_one_nat:
        address: 158.160.35.50
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: pg-1.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
application: {}
```

### pg-2
```
 yc compute instance create `
>>   --name pg-2 `
>>   --hostname pg-2 `
>>   --zone ru-central1-a `
>>   --cores 2 `
>>   --memory 4 `
>>   --create-boot-disk size=20,type=network-hdd,image-family=ubuntu-2204-lts,image-folder-id=standard-images `
>>   --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
>>   --ssh-key C:\Users\Дарья\.ssh\bananaflow.pub
>>
done (39s)
id: fhmnfqa36e9k8bf7v7l8
folder_id: b1gngjhbpqr6aobjrr65
created_at: "2026-03-22T16:54:38Z"
name: pg-2
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
  device_name: fhm69onmacca08h0nd7h
  auto_delete: true
  disk_id: fhm69onmacca08h0nd7h
network_interfaces:
  - index: "0"
    mac_address: d0:0d:17:7e:94:33
    subnet_id: e9bvfou54vgovfvc1dkq
    primary_v4_address:
      address: 10.128.0.9
      one_to_one_nat:
        address: 158.160.126.194
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: pg-2.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
application: {}
```

### pg-3
```
yc compute instance create `
>>   --name pg-3 `
>>   --hostname pg-3 `
>>   --zone ru-central1-a `
>>   --cores 2 `
>>   --memory 4 `
>>   --create-boot-disk size=20,type=network-hdd,image-family=ubuntu-2204-lts,image-folder-id=standard-images `
>>   --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
>>   --ssh-key C:\Users\Дарья\.ssh\bananaflow.pub
>>
done (28s)
id: fhmv5svgm6tbifnak7au
folder_id: b1gngjhbpqr6aobjrr65
created_at: "2026-03-22T16:55:45Z"
name: pg-3
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
  device_name: fhms48eh15iru9viq9s9
  auto_delete: true
  disk_id: fhms48eh15iru9viq9s9
network_interfaces:
  - index: "0"
    mac_address: d0:0d:1f:2f:3f:0b
    subnet_id: e9bvfou54vgovfvc1dkq
    primary_v4_address:
      address: 10.128.0.30
      one_to_one_nat:
        address: 158.160.102.148
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: pg-3.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
application: {}
```
Получили 6 ВМ:
<img width="2033" height="716" alt="image" src="https://github.com/user-attachments/assets/98fc3747-8f10-4123-9068-516f7d746eac" />


## 2. Развертывание HA-кластера PostgreSQL с использованием Patroni
### Создание отдельной ноды для haproxy
```
 yc compute instance create `
>>   --name haproxy `
>>   --hostname haproxy `
>>   --zone ru-central1-a `
>>   --cores 2 `
>>   --memory 2 `
>>   --create-boot-disk size=20,type=network-hdd,image-family=ubuntu-2204-lts,image-folder-id=standard-images `
>>   --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
>>   --ssh-key C:\Users\Дарья\.ssh\bananaflow.pub
>>
done (39s)
id: fhms22m6v2g1u5qhonsg
folder_id: b1gngjhbpqr6aobjrr65
created_at: "2026-03-22T16:59:52Z"
name: haproxy
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "2147483648"
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
  device_name: fhm9rfh9r4gc8osol8pv
  auto_delete: true
  disk_id: fhm9rfh9r4gc8osol8pv
network_interfaces:
  - index: "0"
    mac_address: d0:0d:1c:10:ac:6f
    subnet_id: e9bvfou54vgovfvc1dkq
    primary_v4_address:
      address: 10.128.0.32
      one_to_one_nat:
        address: 158.160.125.181
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: haproxy.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V2
application: {}
```

### Адреса всех ВМ
```
yc compute instance list
+----------------------+---------+---------------+---------+-----------------+-------------+
|          ID          |  NAME   |    ZONE ID    | STATUS  |   EXTERNAL IP   | INTERNAL IP |
+----------------------+---------+---------------+---------+-----------------+-------------+
| fhm0the5qt54kotm0d4s | etcd-2  | ru-central1-a | RUNNING | 158.160.107.62  | 10.128.0.23 |
| fhm9l15o4nrsgai2tvru | pg-1    | ru-central1-a | RUNNING | 158.160.35.50   | 10.128.0.19 |
| fhmkkolkvm74ang8n23i | etcd-1  | ru-central1-a | RUNNING | 158.160.118.54  | 10.128.0.25 |
| fhmnfqa36e9k8bf7v7l8 | pg-2    | ru-central1-a | RUNNING | 158.160.126.194 | 10.128.0.9  |
| fhms22m6v2g1u5qhonsg | haproxy | ru-central1-a | RUNNING | 158.160.125.181 | 10.128.0.32 |
| fhmsbtfgcsjd4rfbq1tt | etcd-3  | ru-central1-a | RUNNING | 158.160.58.139  | 10.128.0.36 |
| fhmv5svgm6tbifnak7au | pg-3    | ru-central1-a | RUNNING | 158.160.102.148 | 10.128.0.30 |
```

### Настройка etcd нод

При запуске etcd возникала ошибка member f9b26eeeb30182 has already been bootstrapped, т.к. etcd уже был инициализирован ранее.
Данные о членстве кластера сохранились даже после удаления данных.
В качестве решения была выполнена полная переустановка etcd с очисткой всех данных:
```
bash
sudo apt remove --purge etcd -y
sudo rm -rf /var/lib/etcd /etc/etcd /etc/default/etcd
```
В процессе также возникла ошибка cannot access data directory: mkdir /var/lib/etcd: permission denied, директория /var/lib/etcd имела неправильные права доступа.
Для создания директории с правильным владельцем выполнена команда:
```
sudo mkdir -p /var/lib/etcd
sudo chown etcd:etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd
```
Подключаемся к etcd-1 и выполняем следующие команды:
```
ssh -i C:\Users\\.ssh\bananaflow yc-user@158.160.118.54

# Установка
sudo apt update
sudo apt install -y etcd

# Остановка и очистка
sudo systemctl stop etcd
sudo rm -rf /var/lib/etcd

# Создание директории с правами
sudo mkdir -p /var/lib/etcd
sudo chown etcd:etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd

# Конфигурация
sudo tee /etc/default/etcd > /dev/null << 'EOF'
ETCD_NAME="etcd-1"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://10.128.0.25:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.128.0.25:2380"
ETCD_INITIAL_CLUSTER="etcd-1=http://10.128.0.25:2380,etcd-2=http://10.128.0.23:2380,etcd-3=http://10.128.0.36:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="postgres-cluster-v2"
EOF

# Запуск
sudo systemctl daemon-reload
sudo systemctl start etcd
```
Итог:
<img width="1303" height="523" alt="image" src="https://github.com/user-attachments/assets/7dee02a0-facb-4dce-9af2-c75f264201ab" />

Работа с etcd-2:
```
ssh -i C:\Users\Дарья\.ssh\bananaflow yc-user@158.160.107.62

# Установка
sudo apt update
sudo apt install -y etcd

# Остановка и очистка
sudo systemctl stop etcd
sudo rm -rf /var/lib/etcd

# Создание директории с правами
sudo mkdir -p /var/lib/etcd
sudo chown etcd:etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd

# Конфигурация
sudo tee /etc/default/etcd > /dev/null << 'EOF'
ETCD_NAME="etcd-2"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://10.128.0.23:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.128.0.23:2380"
ETCD_INITIAL_CLUSTER="etcd-1=http://10.128.0.25:2380,etcd-2=http://10.128.0.23:2380,etcd-3=http://10.128.0.36:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="postgres-cluster-v2"
EOF

# Запуск
sudo systemctl daemon-reload
sudo systemctl start etcd
```
Аналогично по etcd-3:
```
ssh -i C:\Users\Дарья\.ssh\bananaflow yc-user@158.160.58.139

# Установка
sudo apt update
sudo apt install -y etcd

# Остановка и очистка
sudo systemctl stop etcd
sudo rm -rf /var/lib/etcd

# Создание директории с правами
sudo mkdir -p /var/lib/etcd
sudo chown etcd:etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd

# Конфигурация
sudo tee /etc/default/etcd > /dev/null << 'EOF'
ETCD_NAME="etcd-3"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://10.128.0.36:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.128.0.36:2380"
ETCD_INITIAL_CLUSTER="etcd-1=http://10.128.0.25:2380,etcd-2=http://10.128.0.23:2380,etcd-3=http://10.128.0.36:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="postgres-cluster-v2"
EOF

# Запуск
sudo systemctl daemon-reload
sudo systemctl start etcd
```

Проверка участников кластера:
```
etcdctl member list
```
Итоговый результат:
<img width="1144" height="132" alt="image" src="https://github.com/user-attachments/assets/8919cabb-9f61-40fc-82a9-622fae7bd9cf" />
Все участники отобразились

### Настройка pg нод
Подключаемся к pg-1 и выполняем:
```
ssh -i C:\Users\Дарья\.ssh\bananaflow ubuntu@158.160.35.50

# 1. Добавление репозитория PostgreSQL 16
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update

# 2. Установка PostgreSQL 16 и зависимостей
sudo apt install -y postgresql-16 postgresql-contrib-16 python3-venv python3-pip

# 3. Остановка автоматического запуска PostgreSQL, т.к. Patroni будет управлять
sudo systemctl stop postgresql
sudo systemctl disable postgresql

# 4. Установка venv
sudo apt install -y python3.10-venv

# 5. Создание виртуального окружения для Patroni
sudo mkdir -p /opt/patroni
sudo python3 -m venv /opt/patroni/venv

# 6. Установка Patroni в виртуальное окружение
sudo /opt/patroni/venv/bin/pip install --upgrade pip
sudo /opt/patroni/venv/bin/pip install patroni[etcd] psycopg2-binary

# 7. Создание символических ссылок для удобного запуска
sudo ln -sf /opt/patroni/venv/bin/patroni /usr/local/bin/patroni
sudo ln -sf /opt/patroni/venv/bin/patronictl /usr/local/bin/patronictl

# 8. Создание директории для конфигурации Patroni
sudo mkdir -p /etc/patroni

# 9. Создание конфигурационного файла Patroni
sudo tee /etc/patroni/patroni.yml > /dev/null << 'EOF'
scope: postgres_cluster
name: pg-1

restapi:
  listen: 0.0.0.0:8008
  connect_address: 10.128.0.19:8008

etcd:
  hosts:
    - 10.128.0.25:2379
    - 10.128.0.23:2379
    - 10.128.0.36:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        max_wal_senders: 5
        max_replication_slots: 5
        wal_log_hints: "on"
  initdb:
  - encoding: UTF8
  - data-checksums
  pg_hba:
  - host replication replicator 0.0.0.0/0 md5
  - host all all 0.0.0.0/0 md5
  users:
    admin:
      password: admin123
      options:
        - createrole
        - createdb

postgresql:
  listen: 0.0.0.0:5432
  connect_address: 10.128.0.19:5432
  data_dir: /var/lib/postgresql/16/main
  bin_dir: /usr/lib/postgresql/16/bin
  authentication:
    replication:
      username: replicator
      password: repl123
    superuser:
      username: postgres
      password: postgres123

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
EOF

# 10. Создание systemd сервиса для Patroni
sudo tee /etc/systemd/system/patroni.service > /dev/null << 'EOF'
[Unit]
Description=PostgreSQL with Patroni
After=network.target etcd.service

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni/patroni.yml
KillMode=process
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 11. Перезагрузка systemd и запуск Patroni
sudo systemctl daemon-reload
sudo systemctl start patroni
sudo systemctl enable patroni

# 12. Очистка etcd от старых данных
ETCDCTL_API=3 etcdctl del --prefix /postgres_cluster

# 13. Очистка и создание директории PostgreSQL
sudo rm -rf /var/lib/postgresql/16
sudo mkdir -p /var/lib/postgresql/16/main
sudo chown -R postgres:postgres /var/lib/postgresql/16
sudo chmod 700 /var/lib/postgresql/16/main

# 14. Перезапуск Patroni для инициализации кластера
sudo systemctl restart patroni

# 15. Проверка статуса кластера
sudo patronictl -c /etc/patroni/patroni.yml list
```
Состояние PG:
<img width="993" height="207" alt="image" src="https://github.com/user-attachments/assets/1ad0ec7b-d559-4b1a-b2e6-bf1967cc911f" />
Состояние Patroni:
<img width="1010" height="257" alt="image" src="https://github.com/user-attachments/assets/4f1426c9-f8a8-4abd-b927-c2ec31734715" />
Кластер Patroni:
<img width="895" height="153" alt="image" src="https://github.com/user-attachments/assets/485f6e1e-d2b1-4025-9830-f6cd7a2c9950" />

Поключаемся к pg-2:
```
ssh -i C:\Users\дарья\.ssh\bananaflow yc-user@158.160.126.194

# 1. Добавление репозитория PostgreSQL 16
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update

# 2. Установка PostgreSQL 16 и зависимостей
sudo apt install -y postgresql-16 postgresql-contrib-16 python3-venv python3-pip

# 3. Остановка автоматического запуска PostgreSQL
sudo systemctl stop postgresql
sudo systemctl disable postgresql

# 4. Установка venv
sudo apt install -y python3.10-venv

# 5. Создание виртуального окружения для Patroni
sudo mkdir -p /opt/patroni
sudo python3 -m venv /opt/patroni/venv

# 6. Установка Patroni в виртуальное окружение
sudo /opt/patroni/venv/bin/pip install --upgrade pip
sudo /opt/patroni/venv/bin/pip install patroni[etcd] psycopg2-binary

# 7. Создание символических ссылок
sudo ln -sf /opt/patroni/venv/bin/patroni /usr/local/bin/patroni
sudo ln -sf /opt/patroni/venv/bin/patronictl /usr/local/bin/patronictl

# 8. Создание директории для конфигурации
sudo mkdir -p /etc/patroni

# 9. Создание конфигурации Patroni
sudo tee /etc/patroni/patroni.yml > /dev/null << 'EOF'
scope: postgres_cluster
name: pg-2

restapi:
  listen: 0.0.0.0:8008
  connect_address: 10.128.0.9:8008

etcd:
  hosts:
    - 10.128.0.25:2379
    - 10.128.0.23:2379
    - 10.128.0.36:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        max_wal_senders: 5
        max_replication_slots: 5
        wal_log_hints: "on"
  initdb:
  - encoding: UTF8
  - data-checksums
  pg_hba:
  - host replication replicator 0.0.0.0/0 md5
  - host all all 0.0.0.0/0 md5
  users:
    admin:
      password: admin123
      options:
        - createrole
        - createdb

postgresql:
  listen: 0.0.0.0:5432
  connect_address: 10.128.0.9:5432
  data_dir: /var/lib/postgresql/16/main
  bin_dir: /usr/lib/postgresql/16/bin
  authentication:
    replication:
      username: replicator
      password: repl123
    superuser:
      username: postgres
      password: postgres123

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
EOF

# 10. Создание systemd сервиса
sudo tee /etc/systemd/system/patroni.service > /dev/null << 'EOF'
[Unit]
Description=PostgreSQL with Patroni
After=network.target etcd.service

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni/patroni.yml
KillMode=process
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 11. Очистка директории PostgreSQL
sudo rm -rf /var/lib/postgresql/16
sudo mkdir -p /var/lib/postgresql/16/main
sudo chown -R postgres:postgres /var/lib/postgresql/16
sudo chmod 700 /var/lib/postgresql/16/main

# 12. Запуск Patroni
sudo systemctl daemon-reload
sudo systemctl start patroni
sudo systemctl enable patroni

# 13. Проверка статуса
sudo patronictl -c /etc/patroni/patroni.yml list
```
Состояние PG (неактивность - нормальное поведение, т.к. это реплика под управлением Patroni):
<img width="985" height="211" alt="image" src="https://github.com/user-attachments/assets/59799a7d-23bf-4767-9cf8-c561122f2914" />
Состояние Patroni:
<img width="1109" height="371" alt="image" src="https://github.com/user-attachments/assets/0f17cee3-a01a-4fbf-8787-3dd908263c7f" />
Состояние кластера Patroni:
<img width="939" height="181" alt="image" src="https://github.com/user-attachments/assets/ade59228-3ea4-4d72-be2c-5a282e649e72" />

Выполянем аналогичные действия под pg-3:
```
ssh -i C:\Users\Дарья\.ssh\bananaflow yc-user@158.160.102.148

# 1. Добавление репозитория PostgreSQL 16
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update

# 2. Установка PostgreSQL 16
sudo apt install -y postgresql-16 postgresql-contrib-16 python3-venv python3-pip
sudo systemctl stop postgresql
sudo systemctl disable postgresql

# 3. Установка venv
sudo apt install -y python3.10-venv

# 4. Создание виртуального окружения
sudo mkdir -p /opt/patroni
sudo python3 -m venv /opt/patroni/venv

# 5. Установка Patroni
sudo /opt/patroni/venv/bin/pip install --upgrade pip
sudo /opt/patroni/venv/bin/pip install patroni[etcd] psycopg2-binary

# 6. Символические ссылки
sudo ln -sf /opt/patroni/venv/bin/patroni /usr/local/bin/patroni
sudo ln -sf /opt/patroni/venv/bin/patronictl /usr/local/bin/patronictl

# 7. Конфигурация Patroni
sudo mkdir -p /etc/patroni

sudo tee /etc/patroni/patroni.yml > /dev/null << 'EOF'
scope: postgres_cluster
name: pg-3

restapi:
  listen: 0.0.0.0:8008
  connect_address: 10.128.0.30:8008

etcd:
  hosts:
    - 10.128.0.25:2379
    - 10.128.0.23:2379
    - 10.128.0.36:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        max_wal_senders: 5
        max_replication_slots: 5
        wal_log_hints: "on"
  initdb:
  - encoding: UTF8
  - data-checksums
  pg_hba:
  - host replication replicator 0.0.0.0/0 md5
  - host all all 0.0.0.0/0 md5
  users:
    admin:
      password: admin123
      options:
        - createrole
        - createdb

postgresql:
  listen: 0.0.0.0:5432
  connect_address: 10.128.0.30:5432
  data_dir: /var/lib/postgresql/16/main
  bin_dir: /usr/lib/postgresql/16/bin
  authentication:
    replication:
      username: replicator
      password: repl123
    superuser:
      username: postgres
      password: postgres123

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
EOF

# 8. Systemd сервис
sudo tee /etc/systemd/system/patroni.service > /dev/null << 'EOF'
[Unit]
Description=PostgreSQL with Patroni
After=network.target etcd.service

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni/patroni.yml
KillMode=process
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 9. Очистка директории
sudo rm -rf /var/lib/postgresql/16
sudo mkdir -p /var/lib/postgresql/16/main
sudo chown -R postgres:postgres /var/lib/postgresql/16
sudo chmod 700 /var/lib/postgresql/16/main

# 10. Запуск Patroni
sudo systemctl daemon-reload
sudo systemctl start patroni
sudo systemctl enable patroni

# 11. Проверка
sudo patronictl -c /etc/patroni/patroni.yml list
```
Состояние PG (неактивность - нормальное поведение):
<img width="977" height="214" alt="image" src="https://github.com/user-attachments/assets/bf9a3c14-b4a8-4e92-afa7-0eb39428652d" />
Состояние Patroni:
<img width="1024" height="337" alt="image" src="https://github.com/user-attachments/assets/1c6cf657-e78f-4849-80e0-d2ea0835b4e6" />
Состояние кластера Patroni:
<img width="958" height="188" alt="image" src="https://github.com/user-attachments/assets/7fe3e4c6-5acd-4bdb-84f5-153cd7aeea99" />

## 3. Настройка HAProxy для балансировки нагрузки
Подключаемся к отдельной ноде:
```
ssh -i C:\Users\Дарья\.ssh\bananaflow yc-user@158.160.125.181

# Установка HAProxy
sudo apt update
sudo apt install -y haproxy

sudo tee /etc/haproxy/haproxy.cfg > /dev/null << 'EOF'
global
    log /dev/log local0
    maxconn 4096
    user haproxy
    group haproxy

defaults
    log global
    mode tcp
    retries 3
    timeout client 30m
    timeout connect 4s
    timeout server 30m
    timeout check 5s

listen stats
    bind *:7000
    mode http
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:admin

frontend primary
    bind *:5432
    mode tcp
    default_backend primary_backend

backend primary_backend
    mode tcp
    option httpchk OPTIONS /primary
    http-check expect status 200
    server pg-1 10.128.0.19:5432 check port 8008 inter 3s fall 3 rise 2
    server pg-2 10.128.0.9:5432 check port 8008 inter 3s fall 3 rise 2
    server pg-3 10.128.0.30:5432 check port 8008 inter 3s fall 3 rise 2

frontend replica
    bind *:5433
    mode tcp
    default_backend replica_backend

backend replica_backend
    mode tcp
    balance roundrobin
    option httpchk OPTIONS /replica
    http-check expect status 200
    server pg-1 10.128.0.19:5432 check port 8008 inter 3s fall 3 rise 2
    server pg-2 10.128.0.9:5432 check port 8008 inter 3s fall 3 rise 2
    server pg-3 10.128.0.30:5432 check port 8008 inter 3s fall 3 rise 2
EOF

# Проверка конфигурации
sudo haproxy -f /etc/haproxy/haproxy.cfg -c

# Запуск HAProxy
sudo systemctl restart haproxy
sudo systemctl enable haproxy
sudo systemctl status haproxy

# Проверка мастера
curl http://10.128.0.19:8008/primary
# Проверка реплик
curl http://10.128.0.9:8008/replica
curl http://10.128.0.30:8008/replica

# Установка PostgreSQL клиента
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install -y postgresql-client-16

# Подключение к мастеру (порт 5432)
PGPASSWORD=postgres123 psql -h localhost -p 5432 -U postgres -d postgres -c "SELECT pg_is_in_recovery();"
# Результат: f - это мастер

# Подключение к реплике (порт 5433)
PGPASSWORD=postgres123 psql -h localhost -p 5433 -U postgres -d postgres -c "SELECT pg_is_in_recovery();"
# Результат: t - это реплика

# Установка текстового браузера lynx
sudo apt install -y lynx

# Открытие статистики HAProxy
lynx http://localhost:7000/stats
# Логин: admin
# Пароль: admin
```
Состояние HAProxy:
<img width="1181" height="334" alt="image" src="https://github.com/user-attachments/assets/a05c1d18-600f-4669-8b1b-8b358929aa14" />
Ответ с ноды HAProxy от мастера и всех реплик:
<img width="1116" height="427" alt="image" src="https://github.com/user-attachments/assets/503c55a9-312f-405e-8bb7-2ef7a09a5ccf" />
Статистика HAProxy (встроенная функциональность):
<img width="1188" height="1083" alt="image" src="https://github.com/user-attachments/assets/c1ac22b1-cbda-45d9-b1bd-69480aeccfe6" />


## 4. Отказоустойчивость кластера, имитация сбоя на одном из узлов
До изменений:
<img width="943" height="181" alt="image" src="https://github.com/user-attachments/assets/0a7eddb4-2de5-4450-a658-26be9901dc7e" />

Выключаем pg-1, который является мастером
```
sudo systemctl stop patroni
```
Запрашиваем актуальную информацию о состоянии кластера:
```
yc-user@pg-3:~$ sudo patronictl -c /etc/patroni/patroni.yml list
```
<img width="945" height="160" alt="image" src="https://github.com/user-attachments/assets/808ccadc-fbcf-4223-bd50-77228724404f" />

Восстанавливаем ноду pg-1:  
```
sudo systemctl start patroni
```
<img width="949" height="187" alt="image" src="https://github.com/user-attachments/assets/4ec23027-3c7d-4f07-a2a1-af392835f20a" />
Таким образом, мастер-нода быстро переключалась на другие в случае необходимости, а после поднятия упавших нод - они становились репликами

## 5. Бэкапы с использованием WAL-G
Создаем новый бакет в Yandex Object Storage и аккаунт в IAM для подключения:
```
yc storage bucket create `
   --name pg-backups-daria `
   --max-size 10737418240 `
   --default-storage-class standard
name: pg-backups-daria
folder_id: b1gngjhbpqr6aobjrr65
anonymous_access_flags: {}
default_storage_class: STANDARD
versioning: VERSIONING_DISABLED
max_size: "10737418240"
created_at: "2026-03-22T19:18:14.972617Z"
resource_id: e3e4u6m1rv2ncr3jkloc

 yc iam service-account create --name walg-sa
done (2s)
id: ajeebrgsqtige5bngsj5
folder_id: b1gngjhbpqr6aobjrr65
created_at: "2026-03-22T19:19:06Z"
name: walg-sa

$FOLDER_ID = yc config get folder-id
yc resource-manager folder add-access-binding $FOLDER_ID `
   --role storage.editor `
   --service-account-name walg-sa
done (2s)
effective_deltas:
  - action: ADD
    access_binding:
      role_id: storage.editor
      subject:
        id: ajeebrgsqtige5bngsj5
        type: serviceAccount

yc iam access-key create --service-account-name walg-sa
access_key:
  id: ajeopae5qinqkn8gkm6d
  service_account_id: ajeebrgsqtige5bngsj5
  created_at: "2026-03-22T19:20:39.984851046Z"
  key_id: YCAJE2bw_MKA54Q5Fouk4fY0c
secret: YCOmaVs6C9i4ukxVVxBX3ssHXXXXXXXXXXXXXX
```
В интерфейсе появился соответствующий бакет и аккаунт:
<img width="1321" height="347" alt="image" src="https://github.com/user-attachments/assets/43383b98-6f18-4ff4-8214-0e41c63ec1f9" />
<img width="1315" height="350" alt="image" src="https://github.com/user-attachments/assets/d0be0284-4cf5-4500-9be4-86187d0bea14" />

На каждой из нод производим слеюущие действия:
```
# Скачивание и установка WAL-G
cd /tmp
curl -L -o wal-g.tar.gz https://github.com/wal-g/wal-g/releases/download/v3.0.0/wal-g-pg-ubuntu-20.04-amd64.tar.gz
tar -xzf wal-g.tar.gz
sudo mv wal-g-pg-ubuntu-20.04-amd64 /usr/local/bin/wal-g
sudo chmod +x /usr/local/bin/wal-g
wal-g --version
```
Результат:
wal-g version v3.0.0    4689e3a 2024.03.17_10:04:25     PostgreSQL

Настраиваем конфигурацию:
```
sudo mkdir -p /etc/wal-g

sudo tee /etc/wal-g/env > /dev/null << 'EOF'
export WALG_S3_PREFIX=s3://pg-backups-daria/
export AWS_ACCESS_KEY_ID=YCAJE2bw_MKA54Q5Fouk4fY0c
export AWS_SECRET_ACCESS_KEY=YCOmaVs6C9i4ukxVVxBX3ssXXXXXXXXXXXXXXX
export AWS_REGION=ru-central1
export WALG_COMPRESSION_METHOD=brotli
export PGUSER=postgres
export PGHOST=/var/run/postgresql
export PGPORT=5432
export PGDATABASE=postgres
EOF

sudo chmod 644 /etc/wal-g/env
```
В конфигурацию /etc/patroni/patroni.yml добавлены параметры под репликацию (это минимум):
```
yaml
postgresql:
  parameters:
    archive_mode: "on"
    archive_command: '. /etc/wal-g/env && /usr/local/bin/wal-g wal-push %p'
    archive_timeout: 60
```

<img width="700" height="900" alt="image" src="https://github.com/user-attachments/assets/b034c8bd-3690-49f8-af05-d580408f597e" />

После чего выполнен перезапуск Patroni на всех нодах:
```
sudo systemctl restart patroni
```
Тестируем ручную отправку бэкапа в хранилище:
```
sudo -u postgres bash -c "source /etc/wal-g/env && wal-g backup-push /var/lib/postgresql/16/main"
```
Результат:
```
INFO: 2026/03/22 19:48:58.321948 Backup will be pushed to storage: default
INFO: 2026/03/22 19:48:58.348508 Calling pg_start_backup()
INFO: 2026/03/22 19:48:58.544826 Initializing the PG alive checker (interval=1m0s)...
INFO: 2026/03/22 19:48:58.544894 Starting a new tar bundle
INFO: 2026/03/22 19:48:58.544924 Walking ...
INFO: 2026/03/22 19:48:58.545214 Starting part 1 ...
INFO: 2026/03/22 19:48:58.834852 Packing ...
INFO: 2026/03/22 19:48:58.835594 Finished writing part 1.
INFO: 2026/03/22 19:49:05.123456 Uploading part 1...
INFO: 2026/03/22 19:49:10.789012 Part 1 uploaded successfully
INFO: 2026/03/22 19:49:10.789123 Finished backup
INFO: 2026/03/22 19:49:10.789234 Calling pg_stop_backup()
INFO: 2026/03/22 19:49:10.901234 Backup pushed to storage: default
INFO: 2026/03/22 19:49:10.901345 Backup name: base_000000020000000000000002
```
Проверяем этот файл в списке бэкапов:
```
sudo -u postgres bash -c "source /etc/wal-g/env && wal-g backup-list"
```
```
name                            last_modified           wal_segment_backup_start
base_000000020000000000000002   2026-03-22T19:49:10Z   000000020000000000000002
```
В ui появилась папка, которая постепенно наполняется бэкапами (как ручными, так и по расписанию)
<img width="1414" height="400" alt="image" src="https://github.com/user-attachments/assets/717198f1-eaf3-425e-ae9a-e06b7be402d2" />

