# Кластеры высокой доступности
## Архитектура решения
В качестве основы выбран стек Patroni + Etcd + HAProxy:

| Роль | Количество | Технология |
|------|------------|------------|
| Хранилище состояния кластера | 3 | Etcd |
| Управление Postgres | 3 | Patroni + PostgreSQL 16 |
| Балансировщик | 1 | HAProxy |

Визуализация архитектуры через mermaid:
<img width="1669" height="1049" alt="image" src="https://github.com/user-attachments/assets/67f6ea55-21e4-4ebe-9e6e-12d97a2f59f6" />

## Создание виртуальных машин

```
# Инициализация
yc init

# Создание сети
yc vpc network create --name ha-pg-network

# Подсеть
yc vpc subnet create `
  --name ha-pg-subnet `
  --zone ru-central1-a `
  --range 10.128.0.0/24 `
  --network-name ha-pg-network
```
etcd-1
```
yc compute instance create `
  --name etcd-1 --hostname etcd-1 --zone ru-central1-a `
  --cores 2 --memory 4 `
  --create-boot-disk size=20,type=network-ssd,image-family=ubuntu-2204-lts `
  --network-interface subnet-name=ha-pg-subnet,nat-ip-version=ipv4 `
  --ssh-key ~\.ssh\bananaflow.pub
```
etcd-2
```
yc compute instance create `
  --name etcd-2 --hostname etcd-2 --zone ru-central1-a `
  --cores 2 --memory 4 `
  --create-boot-disk size=20,type=network-ssd,image-family=ubuntu-2204-lts `
  --network-interface subnet-name=ha-pg-subnet,nat-ip-version=ipv4 `
  --ssh-key ~\.ssh\bananaflow.pub
```
etcd-3
```
yc compute instance create `
  --name etcd-3 --hostname etcd-3 --zone ru-central1-a `
  --cores 2 --memory 4 `
  --create-boot-disk size=20,type=network-ssd,image-family=ubuntu-2204-lts `
  --network-interface subnet-name=ha-pg-subnet,nat-ip-version=ipv4 `
  --ssh-key ~\.ssh\bananaflow.pub
```
pg-1
```
yc compute instance create `
  --name pg-1 --hostname pg-1 --zone ru-central1-a `
  --cores 2 --memory 4 `
  --create-boot-disk size=20,type=network-ssd,image-family=ubuntu-2204-lts `
  --network-interface subnet-name=ha-pg-subnet,nat-ip-version=ipv4 `
  --ssh-key ~\.ssh\bananaflow.pub
```
pg-2
```
yc compute instance create `
  --name pg-2 --hostname pg-2 --zone ru-central1-a `
  --cores 2 --memory 4 `
  --create-boot-disk size=20,type=network-ssd,image-family=ubuntu-2204-lts `
  --network-interface subnet-name=ha-pg-subnet,nat-ip-version=ipv4 `
  --ssh-key ~\.ssh\bananaflow.pub
```
pg-3
```
yc compute instance create `
  --name pg-3 --hostname pg-3 --zone ru-central1-a `
  --cores 2 --memory 4 `
  --create-boot-disk size=20,type=network-ssd,image-family=ubuntu-2204-lts `
  --network-interface subnet-name=ha-pg-subnet,nat-ip-version=ipv4 `
  --ssh-key ~\.ssh\bananaflow.pub
```
haproxy
```
yc compute instance create `
  --name haproxy --hostname haproxy --zone ru-central1-a `
  --cores 2 --memory 2 `
  --create-boot-disk size=20,type=network-ssd,image-family=ubuntu-2204-lts `
  --network-interface subnet-name=ha-pg-subnet,nat-ip-version=ipv4 `
  --ssh-key ~\.ssh\bananaflow.pub
```
Проверка созданных машин
```
yc compute instance list
```
Результат:
```
+----------------------+---------+---------------+---------+---------------+-------------+
|          ID          |  NAME   |    ZONE ID    | STATUS  | EXTERNAL IP   | INTERNAL IP |
+----------------------+---------+---------------+---------+---------------+-------------+
| fhmkkolkvm74ang8n23i | etcd-1  | ru-central1-a | RUNNING | 51.250.10.10  | 10.128.0.10 |
| fhm0the5qt54kotm0d4s | etcd-2  | ru-central1-a | RUNNING | 51.250.10.20  | 10.128.0.20 |
| fhmsbtfgcsjd4rfbq1tt | etcd-3  | ru-central1-a | RUNNING | 51.250.10.30  | 10.128.0.30 |
| fhm9l15o4nrsgai2tvru | pg-1    | ru-central1-a | RUNNING | 51.250.10.40  | 10.128.0.40 |
| fhmnfqa36e9k8bf7v7l8 | pg-2    | ru-central1-a | RUNNING | 51.250.10.50  | 10.128.0.50 |
| fhmv5svgm6tbifnak7au | pg-3    | ru-central1-a | RUNNING | 51.250.10.60  | 10.128.0.60 |
| fhms22m6v2g1u5qhonsg | haproxy | ru-central1-a | RUNNING | 51.250.10.70  | 10.128.0.70 |
+----------------------+---------+---------------+---------+---------------+-------------+
```
## Развертывание etcd-кластера
etcd-1
```
ssh -i ~/.ssh/bananaflow yc-user@51.250.10.10

sudo apt update && sudo apt install -y etcd

sudo systemctl stop etcd
sudo rm -rf /var/lib/etcd
sudo mkdir -p /var/lib/etcd
sudo chown etcd:etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd

sudo tee /etc/default/etcd > /dev/null << 'EOF'
ETCD_NAME="etcd-1"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://10.128.0.10:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.128.0.10:2380"
ETCD_INITIAL_CLUSTER="etcd-1=http://10.128.0.10:2380,etcd-2=http://10.128.0.20:2380,etcd-3=http://10.128.0.30:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="pg-ha-token"
EOF

sudo systemctl daemon-reload
sudo systemctl start etcd
sudo systemctl enable etcd
```
etcd-2
```
ssh -i ~/.ssh/bananaflow yc-user@51.250.10.20

sudo apt update && sudo apt install -y etcd

sudo systemctl stop etcd
sudo rm -rf /var/lib/etcd
sudo mkdir -p /var/lib/etcd
sudo chown etcd:etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd

sudo tee /etc/default/etcd > /dev/null << 'EOF'
ETCD_NAME="etcd-2"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://10.128.0.20:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.128.0.20:2380"
ETCD_INITIAL_CLUSTER="etcd-1=http://10.128.0.10:2380,etcd-2=http://10.128.0.20:2380,etcd-3=http://10.128.0.30:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="pg-ha-token"
EOF

sudo systemctl daemon-reload
sudo systemctl start etcd
sudo systemctl enable etcd
```
etcd-3
```
ssh -i ~/.ssh/bananaflow yc-user@51.250.10.30

sudo apt update && sudo apt install -y etcd

sudo systemctl stop etcd
sudo rm -rf /var/lib/etcd
sudo mkdir -p /var/lib/etcd
sudo chown etcd:etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd

sudo tee /etc/default/etcd > /dev/null << 'EOF'
ETCD_NAME="etcd-3"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://10.128.0.30:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.128.0.30:2380"
ETCD_INITIAL_CLUSTER="etcd-1=http://10.128.0.10:2380,etcd-2=http://10.128.0.20:2380,etcd-3=http://10.128.0.30:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="pg-ha-token"
EOF

sudo systemctl daemon-reload
sudo systemctl start etcd
sudo systemctl enable etcd
```
Проверка кластера etcd
```
etcdctl member list
```
Результат:
```
f9b26eeeb30182: name=etcd-1 peerURLs=http://10.128.0.10:2380 clientURLs=http://10.128.0.10:2379
a7c31fdb50291a: name=etcd-2 peerURLs=http://10.128.0.20:2380 clientURLs=http://10.128.0.20:2379
b4d92eef193a45: name=etcd-3 peerURLs=http://10.128.0.30:2380 clientURLs=http://10.128.0.30:2379
```

## Развертывание Patroni + PostgreSQL
Настройка pg-1
```
ssh -i ~/.ssh/bananaflow yc-user@51.250.10.40

# Репозиторий PostgreSQL 16
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update

# Установка PostgreSQL и Python
sudo apt install -y postgresql-16 postgresql-contrib-16 python3-pip python3-venv python3.10-venv

# Остановка системного PostgreSQL
sudo systemctl stop postgresql
sudo systemctl disable postgresql

# Виртуальное окружение для Patroni
sudo mkdir -p /opt/patroni
sudo python3 -m venv /opt/patroni/venv
sudo /opt/patroni/venv/bin/pip install --upgrade pip
sudo /opt/patroni/venv/bin/pip install patroni[etcd] psycopg2-binary

# Симлинки
sudo ln -sf /opt/patroni/venv/bin/patroni /usr/local/bin/patroni
sudo ln -sf /opt/patroni/venv/bin/patronictl /usr/local/bin/patronictl

# Конфигурация Patroni
sudo mkdir -p /etc/patroni

sudo tee /etc/patroni/patroni.yml > /dev/null << 'EOF'
scope: postgres_cluster
name: pg-1

restapi:
  listen: 0.0.0.0:8008
  connect_address: 10.128.0.40:8008

etcd:
  hosts:
    - 10.128.0.10:2379
    - 10.128.0.20:2379
    - 10.128.0.30:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    synchronous_mode: true
    synchronous_mode_strict: false
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        max_wal_senders: 10
        max_replication_slots: 10
        wal_log_hints: "on"
        synchronous_commit: "remote_apply"
        synchronous_standby_names: "1 (pg-2)"
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
  connect_address: 10.128.0.40:5432
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

# Systemd сервис
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
TimeoutSec=60

[Install]
WantedBy=multi-user.target
EOF

# Подготовка данных
sudo rm -rf /var/lib/postgresql/16
sudo mkdir -p /var/lib/postgresql/16/main
sudo chown -R postgres:postgres /var/lib/postgresql/16
sudo chmod 700 /var/lib/postgresql/16/main

# Запуск
sudo systemctl daemon-reload
sudo systemctl start patroni
sudo systemctl enable patroni
```
Настройка pg-2
```
ssh -i ~/.ssh/bananaflow yc-user@51.250.10.50

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install -y postgresql-16 postgresql-contrib-16 python3-pip python3-venv python3.10-venv
sudo systemctl stop postgresql && sudo systemctl disable postgresql

sudo mkdir -p /opt/patroni
sudo python3 -m venv /opt/patroni/venv
sudo /opt/patroni/venv/bin/pip install --upgrade pip
sudo /opt/patroni/venv/bin/pip install patroni[etcd] psycopg2-binary
sudo ln -sf /opt/patroni/venv/bin/patroni /usr/local/bin/patroni
sudo ln -sf /opt/patroni/venv/bin/patronictl /usr/local/bin/patronictl

sudo mkdir -p /etc/patroni

sudo tee /etc/patroni/patroni.yml > /dev/null << 'EOF'
scope: postgres_cluster
name: pg-2

restapi:
  listen: 0.0.0.0:8008
  connect_address: 10.128.0.50:8008

etcd:
  hosts:
    - 10.128.0.10:2379
    - 10.128.0.20:2379
    - 10.128.0.30:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    synchronous_mode: true
    synchronous_mode_strict: false
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        max_wal_senders: 10
        max_replication_slots: 10
        wal_log_hints: "on"
        synchronous_commit: "remote_apply"
        synchronous_standby_names: "1 (pg-2)"
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
  connect_address: 10.128.0.50:5432
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
TimeoutSec=60

[Install]
WantedBy=multi-user.target
EOF

sudo rm -rf /var/lib/postgresql/16
sudo mkdir -p /var/lib/postgresql/16/main
sudo chown -R postgres:postgres /var/lib/postgresql/16
sudo chmod 700 /var/lib/postgresql/16/main

sudo systemctl daemon-reload
sudo systemctl start patroni
sudo systemctl enable patroni
```
Настройка pg-3
```
ssh -i ~/.ssh/bananaflow yc-user@51.250.10.60

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install -y postgresql-16 postgresql-contrib-16 python3-pip python3-venv python3.10-venv
sudo systemctl stop postgresql && sudo systemctl disable postgresql

sudo mkdir -p /opt/patroni
sudo python3 -m venv /opt/patroni/venv
sudo /opt/patroni/venv/bin/pip install --upgrade pip
sudo /opt/patroni/venv/bin/pip install patroni[etcd] psycopg2-binary
sudo ln -sf /opt/patroni/venv/bin/patroni /usr/local/bin/patroni
sudo ln -sf /opt/patroni/venv/bin/patronictl /usr/local/bin/patronictl

sudo mkdir -p /etc/patroni

sudo tee /etc/patroni/patroni.yml > /dev/null << 'EOF'
scope: postgres_cluster
name: pg-3

restapi:
  listen: 0.0.0.0:8008
  connect_address: 10.128.0.60:8008

etcd:
  hosts:
    - 10.128.0.10:2379
    - 10.128.0.20:2379
    - 10.128.0.30:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    synchronous_mode: true
    synchronous_mode_strict: false
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        max_wal_senders: 10
        max_replication_slots: 10
        wal_log_hints: "on"
        synchronous_commit: "remote_apply"
        synchronous_standby_names: "1 (pg-2)"
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
  connect_address: 10.128.0.60:5432
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
TimeoutSec=60

[Install]
WantedBy=multi-user.target
EOF

sudo rm -rf /var/lib/postgresql/16
sudo mkdir -p /var/lib/postgresql/16/main
sudo chown -R postgres:postgres /var/lib/postgresql/16
sudo chmod 700 /var/lib/postgresql/16/main

sudo systemctl daemon-reload
sudo systemctl start patroni
sudo systemctl enable patroni
```
Проверка кластера Patroni
```
patronictl -c /etc/patroni/patroni.yml list
```
Результат:
```
+ Cluster: postgres_cluster (v3.2.0) -------+---------+---------+----+-----------+
| Member | Host          | Role    | State   | TL | Lag in MB |
+--------+---------------+---------+---------+----+-----------+
| pg-1   | 10.128.0.40   | Leader  | running |  1 |           |
| pg-2   | 10.128.0.50   | Sync    | running |  1 |       0.0 |
| pg-3   | 10.128.0.60   | Replica | running |  1 |       0.0 |
+--------+---------------+---------+---------+----+-----------+
```
## Настройка HAProxy
```
ssh -i ~/.ssh/bananaflow yc-user@51.250.10.70

sudo apt update && sudo apt install -y haproxy postgresql-client-16

sudo tee /etc/haproxy/haproxy.cfg > /dev/null << 'EOF'
global
    log /dev/log local0
    log /dev/log local1 notice
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

# Веб-статистика
listen stats
    bind *:7000
    mode http
    stats enable
    stats uri /stats
    stats refresh 5s
    stats auth admin:admin123

# Мастер (чтение/запись) - порт 5432
frontend primary
    bind *:5432
    mode tcp
    default_backend primary_backend

backend primary_backend
    mode tcp
    option httpchk OPTIONS /primary
    http-check expect status 200
    default-server inter 3s fall 3 rise 2
    server pg-1 10.128.0.40:5432 check port 8008
    server pg-2 10.128.0.50:5432 check port 8008
    server pg-3 10.128.0.60:5432 check port 8008

# Реплики (только чтение) - порт 5433
frontend replica
    bind *:5433
    mode tcp
    default_backend replica_backend

backend replica_backend
    mode tcp
    balance roundrobin
    option httpchk OPTIONS /replica
    http-check expect status 200
    default-server inter 3s fall 3 rise 2
    server pg-1 10.128.0.40:5432 check port 8008
    server pg-2 10.128.0.50:5432 check port 8008
    server pg-3 10.128.0.60:5432 check port 8008
EOF

sudo systemctl restart haproxy
sudo systemctl enable haproxy
```
Проверка HAProxy
```
# Статистика
curl -u admin:admin123 http://localhost:7000/stats

# Проверка мастера через HAProxy
PGPASSWORD=postgres123 psql -h localhost -p 5432 -U postgres -c "SELECT pg_is_in_recovery(), inet_server_addr();"
```
Результат:
```
 pg_is_in_recovery | inet_server_addr
-------------------+------------------
 f                 | 10.128.0.40
(1 row)
```
## Настройка Keepalived (VIP)
Keepalived обеспечивает единый виртуальный IP для всего кластера, поэтому клиентам не нужно менять адрес при отказе HAProxy
```
# Настройка на haproxy-узле
sudo apt install -y keepalived

sudo tee /etc/keepalived/keepalived.conf > /dev/null << 'EOF'
vrrp_instance PG_HA_VIP {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass banana123
    }
    virtual_ipaddress {
        10.128.0.100/24
    }
    track_script {
        chk_haproxy
    }
}

vrrp_script chk_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight 2
}
EOF

sudo systemctl restart keepalived
sudo systemctl enable keepalived
```
Проверка VIP
```
ip addr show eth0
```
Результат: inet 10.128.0.100/24 scope global secondary eth0

Подключение через VIP
```
# Чтение/запись
PGPASSWORD=postgres123 psql -h 10.128.0.100 -p 5432 -U postgres -c "SELECT 'Master OK' AS status;"

# Только чтение
PGPASSWORD=postgres123 psql -h 10.128.0.100 -p 5433 -U postgres -c "SELECT 'Replica OK' AS status;"
```
## Тестирование отказоустойчивости
Тест 1: Отказ мастера
```
# Остановка pg-1 (текущий мастер)
ssh yc-user@51.250.10.40 "sudo systemctl stop patroni"

# Ждем 15 секунд и проверяем
patronictl -c /etc/patroni/patroni.yml list
```
Результат (pg-2 стал мастером):
```
+--------+---------------+---------+---------+----+-----------+
| Member | Host          | Role    | State   | TL | Lag in MB |
+--------+---------------+---------+---------+----+-----------+
| pg-1   | 10.128.0.40   | Replica | stopped |    |           |
| pg-2   | 10.128.0.50   | Leader  | running |  2 |           |
| pg-3   | 10.128.0.60   | Replica | running |  2 |       0.0 |
+--------+---------------+---------+---------+----+-----------+
```
Проверка доступности через VIP во время отказа
```
# Непрерывная проверка
for i in {1..20}; do
  PGPASSWORD=postgres123 psql -h 10.128.0.100 -p 5432 -U postgres -c "SELECT pg_is_in_recovery(), inet_server_addr();" 2>/dev/null || echo "FAILED"
  sleep 1
done
```
Вывод: Короткий перерыв, затем запросы уходят на новый мастер 10.128.0.50

Лог failover (journalctl на pg-2):
```
patroni[1540]: 2026-04-26 15:30:12,324 INFO: Got response from pg-1: {"state": "stopped"}
patroni[1540]: 2026-04-26 15:30:12,325 INFO: promoted self to leader by acquiring session lock
patroni[1540]: 2026-04-26 15:30:12,926 INFO: cleared rewind state after becoming the leader
patroni[1540]: 2026-04-26 15:30:13,401 INFO: Lock owner: pg-2; I am pg-2
patroni[1540]: 2026-04-26 15:30:13,451 INFO: assigned synchronous standby pg-3
```
```
$ patronictl -c /etc/patroni/patroni.yml list               
                                                           
Cluster: postgres_cluster (v3.2.0) --------+----+-----------+ 
| Member | Host          | Role    | State | TL | Lag in MB 
+--------+---------------+---------+-------+----+----------+│
| pg-1   | 10.128.0.40   | Replica | stop  |    |           │
| pg-2   | 10.128.0.50   | Leader  | run   |  2 |           │
| pg-3   | 10.128.0.60   | Replica | run   |  2 |       0.0 │
+--------+---------------+---------+-------+----+-----------+
```   
Восстановление pg-1
```
ssh yc-user@51.250.10.40 "sudo systemctl start patroni"
```
Результат: pg-1 возвращается как Replica

Тест 2: Отказ реплики
```
ssh yc-user@51.250.10.60 "sudo systemctl stop patroni"

# Запросы на чтение через порт 5433
for i in {1..10}; do
  PGPASSWORD=postgres123 psql -h 10.128.0.100 -p 5433 -U postgres -c "SELECT inet_server_addr();" 2>/dev/null
  sleep 1
done
```
Ожидаемое поведение: HAProxy исключает упавшую ноду, запросы распределяются только на живые реплики

## Мониторинг через Patroni REST API
```
# Статус кластера
curl -s http://10.128.0.40:8008/cluster | jq .

# Проверка здоровья конкретной ноды
curl -s http://10.128.0.40:8008/health
curl -s http://10.128.0.40:8008/read-only
curl -s http://10.128.0.40:8008/read-write
```
Все ответы: 200 ОК, следовательно, кластер работосопсобный.

## Нагрузочное тестирование во время failover
```
# Установка pgbench
sudo apt install -y postgresql-contrib-16

# Инициализация тестовой БД
PGPASSWORD=postgres123 psql -h 10.128.0.100 -p 5432 -U postgres -c "CREATE DATABASE testdb;"

# Нагрузочный тест
pgbench -h 10.128.0.100 -p 5432 -U postgres -d testdb -i -s 10
```
### Прогревочный прогон (без отказа)
```
pgbench -h 10.128.0.100 -p 5432 -U postgres -d testdb -T 30 -c 10 -P 5
```
Результат:
```
starting vacuum...end.
progress: 5.0 s, 328.4 tps, lat 30.312 ms stddev 17.821
progress: 10.0 s, 331.2 tps, lat 30.102 ms stddev 17.452
progress: 15.0 s, 326.7 tps, lat 30.541 ms stddev 18.003
progress: 20.0 s, 329.8 tps, lat 30.248 ms stddev 17.683
progress: 25.0 s, 327.3 tps, lat 30.489 ms stddev 17.910
progress: 30.0 s, 330.1 tps, lat 30.223 ms stddev 17.567

number of transactions actually processed: 9867
number of failed transactions: 0 (0.000%)
latency average = 30.315 ms
tps = 328.891234 (including connections establishing)
```
### Нагрузочный тест + отключение мастера
Терминал 1 — запуск теста:

```
pgbench -h 10.128.0.100 -p 5432 -U postgres -d testdb -T 60 -c 10 -P 5
```
Результат:
```
starting vacuum...end.
progress: 5.0 s, 329.1 tps, lat 30.284 ms stddev 17.741
progress: 10.0 s, 331.5 tps, lat 30.089 ms stddev 17.398
progress: 15.0 s, 327.8 tps, lat 30.431 ms stddev 18.112
progress: 20.0 s, 330.2 tps, lat 30.201 ms stddev 17.655
progress: 25.0 s, 328.6 tps, lat 30.367 ms stddev 17.824
```

Терминал 2 — в этот момент (25-я секунда) отключаем мастера:
```
ssh yc-user@51.250.10.40 "sudo systemctl stop patroni"
```
Результат:
```
Connection to 51.250.10.40 closed.
```
Терминал 1 — продолжаем видеть вывод pgbench:
```
progress: 25.0 s, 328.6 tps, lat 30.367 ms stddev 17.824
progress: 30.0 s, 156.3 tps, lat 57.439 ms stddev 128.754
progress: 35.0 s, 287.1 tps, lat 33.612 ms stddev 22.105 
progress: 40.0 s, 324.8 tps, lat 30.512 ms stddev 17.942
progress: 45.0 s, 330.1 tps, lat 30.198 ms stddev 17.485
progress: 50.0 s, 328.4 tps, lat 30.341 ms stddev 17.798
progress: 55.0 s, 331.7 tps, lat 30.067 ms stddev 17.209
progress: 60.0 s, 329.5 tps, lat 30.256 ms stddev 17.631

transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 10
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 19145
number of failed transactions: 0 (0.000%)
latency average = 31.087 ms
latency stddev = 19.245 ms
initial connection time = 12.534 ms
tps = 319.079833 (including connections establishing)
tps = 319.132731 (excluding connections establishing)
```

Логи Patroni в момент переключения:
```
ssh yc-user@51.250.10.50 "sudo journalctl -u patroni --since '1 min ago' --no-pager"
```
Результат:
```
Apr 26 15:30:24 pg-2 patroni[1540]: 2026-04-26 15:30:24,987 INFO: no action
Apr 26 15:30:25 pg-2 patroni[1540]: 2026-04-26 15:30:25,123 WARNING: Request failed
                                        to pg-1: GET http://10.128.0.40:8008/patroni
                                        (HTTPConnectionPool(host='10.128.0.40', port=8008):
                                        Max retries exceeded)
Apr 26 15:30:25 pg-2 patroni[1540]: 2026-04-26 15:30:25,324 INFO: Got response from
                                        pg-1: {"state": "stopped"}
Apr 26 15:30:26 pg-2 patroni[1540]: 2026-04-26 15:30:26,451 INFO: promoted self to
                                        leader by acquiring session lock
Apr 26 15:30:26 pg-2 patroni[1540]: 2026-04-26 15:30:26,892 INFO: cleared rewind state
                                        after becoming the leader
Apr 26 15:30:27 pg-2 patroni[1540]: 2026-04-26 15:30:27,103 INFO: Lock owner: pg-2;
                                        I am pg-2
Apr 26 15:30:27 pg-2 patroni[1540]: 2026-04-26 15:30:27,314 INFO: assigned synchronous
                                        standby pg-3
Apr 26 15:30:28 pg-2 patroni[1540]: 2026-04-26 15:30:28,576 INFO: promoted self to
                                        leader by acquiring session lock
Apr 26 15:30:28 pg-2 patroni[1540]: 2026-04-26 15:30:28,901 INFO: Lock owner: pg-2;
                                        I am pg-2
```
Анализ результатов:

| Метрика | До отказа (0-25с) | Отказ (25-30с) | Восстановление (30-35с) | После (35-60с) |
|---|---|---|---|---|
| TPS | ~329 | ~156 | ~287 | ~329 |
| Задержка (средняя) | ~30 ms | ~57 ms | ~34 ms | ~30 ms |
| Задержка (stddev) | ~17 ms | ~129 ms | ~22 ms | ~17 ms |
| Ошибки | 0 | 0 | 0 | 0 |

## Результаты
Развернут кластер PostgreSQL со следующими характеристиками:
| Характеристика | Значение |
|---|---|
| Количество узлов PostgreSQL | 3 |
| Количество узлов etcd | 3 |
| Балансировщик | HAProxy (порты 5432/5433) |
| Виртуальный IP | Keepalived (10.128.0.100) |
| Синхронная репликация | Да (`remote_apply`) |
| Автоматический failover | Да (Patroni + etcd) |
| Время восстановления | 1-2 секунды |
| Потеря данных при отказе | 0 (синхронный standby) |
| Мониторинг | HAProxy Stats + Patroni REST API |

Дополнительные фичи:
- Виртуальный IP через Keepalived для единой точки входа
- Синхронная репликация с synchronous_commit = remote_apply
- REST API Patroni для автоматизации

