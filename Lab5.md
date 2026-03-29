# Бэкапы
## 1. Настройка бэкапов PostgreSQL с использованием pg_probackup
Начинаем создавать ВМ, сеть default и подсети уже существуют
Создаем 2 ВМ:
```
yc compute instance create `
  --name postgres-main `
  --hostname postgres-main `
  --zone ru-central1-a `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=20G,type=network-hdd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
  --ssh-key C:\Users\дарья\.ssh\bananaflow.pub
```
Ответ:
```
done (1m3s)
id: fhmtt6jael2q9qsb2mmr
folder_id: b1ghlv94m814soortgjf
created_at: "2026-03-29T15:06:39Z"
name: postgres-main
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
  device_name: fhm79b8nf2mbn9pj37kh
  auto_delete: true
  disk_id: fhm79b8nf2mbn9pj37kh
network_interfaces:
  - index: "0"
    mac_address: d0:0d:1d:e9:a6:a7
    subnet_id: e9bt51bbnhvmfnhr16s0
    primary_v4_address:
      address: 10.128.0.9
      one_to_one_nat:
        address: 158.160.119.254
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: postgres-main.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V1
application: {}
```

```
yc compute instance create `
  --name postgres-restore `
  --hostname postgres-restore `
  --zone ru-central1-a `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=20G,type=network-hdd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
  --ssh-key C:\Users\дарья\.ssh\bananaflow.pub
```
Ответ:
```
done (43s)
id: fhmegtp0cbr66b6to8bb
folder_id: b1ghlv94m814soortgjf
created_at: "2026-03-29T15:09:20Z"
name: postgres-restore
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
  device_name: fhm4rbfq53tu8lbeobon
  auto_delete: true
  disk_id: fhm4rbfq53tu8lbeobon
network_interfaces:
  - index: "0"
    mac_address: d0:0d:e8:77:20:62
    subnet_id: e9bt51bbnhvmfnhr16s0
    primary_v4_address:
      address: 10.128.0.15
      one_to_one_nat:
        address: 89.169.141.142
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: postgres-restore.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V1
application: {}
```

Подключаемся к 1 ВМ:
```
ssh -i C:\Users\дарья\.ssh\bananaflow yc-user@158.160.119.254
```
Последовательно выполняем следующие команды:
```
# 1. Обновление системы
sudo apt update && sudo apt upgrade -y

# 2. Установка PostgreSQL 18
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install -y postgresql-18 postgresql-contrib-18

# 3. Проверка PostgreSQL
sudo systemctl status postgresql

# 4. Установка pg_probackup
sudo apt install -y gpg wget
sudo wget -qO - https://repo.postgrespro.ru/pg_probackup/keys/GPG-KEY-PG-PROBACKUP | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] https://repo.postgrespro.ru/pg_probackup/deb/ noble main-noble" > /etc/apt/sources.list.d/pg_probackup.list'
sudo apt update
sudo apt install -y pg-probackup-18

# 5. Создание каталога для бэкапов
sudo mkdir -p /home/backups
sudo chmod 777 /home/backups

# 6. Инициализация pg_probackup
sudo su postgres
pg_probackup-18 init -B /home/backups
pg_probackup-18 add-instance --instance main -D /var/lib/postgresql/18/main -B /home/backups
pg_probackup-18 show-config --instance main -B /home/backups

# 7. Создание тестовой БД и данных
psql -c "CREATE DATABASE loyalty;"
psql loyalty -c "CREATE TABLE customers (id int, name text, bonus int);"
psql loyalty -c "INSERT INTO customers VALUES (1, 'Иван', 100), (2, 'Мария', 250), (3, 'Петр', 75);"
psql loyalty -c "SELECT * FROM customers;"

# 8. Полный бэкап
pg_probackup-18 backup --instance main -b FULL --stream --temp-slot -B /home/backups

# 9. Смотрим ID бэкапа
pg_probackup-18 show -B /home/backups

# 10. Добавляем данные и делаем инкрементальный бэкап
psql loyalty -c "INSERT INTO customers VALUES (4, 'Елена', 500);"
psql loyalty -c "SELECT * FROM customers;"
pg_probackup-18 backup --instance main -b DELTA --stream --temp-slot -B /home/backups

# 11. Смотрим оба бэкапа
pg_probackup-18 show -B /home/backups

# 12. Выходим из postgres
exit

# 13. Упаковываем бэкапы
cd /home
sudo tar -czf backups.tar.gz backups/
sudo chmod 666 backups.tar.gz

# 14. Проверяем, что архив создался
ls -la /home/backups.tar.gz
```

Проверка статуса PG:
<img width="1120" height="220" alt="image" src="https://github.com/user-attachments/assets/4947370e-5402-4e11-b853-8b2b0c478d37" />

Результат создания и наполнения таблицы:
<img width="837" height="170" alt="image" src="https://github.com/user-attachments/assets/b9881892-dbd6-41b9-81a5-28e7312664f3" />

Создание полного бэкапа:
<img width="1391" height="681" alt="image" src="https://github.com/user-attachments/assets/5cc0771b-a95b-425c-96c1-174e983a3abe" />

Изменения в таблице:
<img width="815" height="190" alt="image" src="https://github.com/user-attachments/assets/37101daa-e938-40ca-a86b-64a787bc3c65" />

Инкрементальный бэкап:
<img width="1398" height="731" alt="image" src="https://github.com/user-attachments/assets/f59d83ba-6359-47f5-9f5e-98284a271b03" />

## 2. Восстановление данных на другом кластере
Копируем через локальную машину:
```
scp -i C:\Users\дарья\.ssh\bananaflow yc-user@158.160.119.254:/home/backups.tar.gz C:\Users\дарья\backups.tar.gz
scp -i C:\Users\дарья\.ssh\bananaflow C:\Users\дарья\backups.tar.gz yc-user@89.169.141.142:/tmp/
```
Распаковываем архив на второй ВМ:
```
# Подключаемся ко второй ВМ
ssh -i C:\Users\дарья\.ssh\bananaflow yc-user@89.169.141.142

# Перемещаем и распаковываем
sudo mv /tmp/backups.tar.gz /home/
sudo tar -xzf /home/backups.tar.gz -C /home/

# Назначаем доп.права
sudo chown -R yc-user:yc-user /home/backups
sudo chmod -R 755 /home/backups

# Проверяем структуру
ls -la /home/backups/backups/main/

```
Далее выполняем шаги по установке PG и pg_probackup на второй ВМ (полная аналогия первой ВМ):
```
sudo apt update && sudo apt upgrade -y
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install -y postgresql-18 postgresql-contrib-18
sudo apt install -y gpg wget
sudo wget -qO - https://repo.postgrespro.ru/pg_probackup/keys/GPG-KEY-PG-PROBACKUP | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] https://repo.postgrespro.ru/pg_probackup/deb/ noble main-noble" > /etc/apt/sources.list.d/pg_probackup.list'
sudo apt update
sudo apt install -y pg-probackup-18
```

Восстанавливаем данные на втором PG:
```
# Остановка PostgreSQL и очистка данных
sudo systemctl stop postgresql
sudo rm -rf /var/lib/postgresql/18/main
sudo mkdir -p /var/lib/postgresql/18/main
sudo chown postgres:postgres /var/lib/postgresql/18/main
sudo chmod 700 /var/lib/postgresql/18/main

# Даём права postgres на каталог с бэкапами
sudo chown -R postgres:postgres /home/backups
sudo chmod -R 755 /home/backups

# Восстановление
sudo su postgres
pg_probackup-18 restore --instance main -i 'TCO2M1' -D /var/lib/postgresql/18/main -B /home/backups
exit
sudo systemctl start postgresql
```

Бэкап, перенесенный на другую ВМ:
<img width="1365" height="207" alt="image" src="https://github.com/user-attachments/assets/d2c107a2-d545-4eef-9a14-69a508ee8be0" />

## 3. Проверка, что данные перенеслись корректно
```
# Проверка
sudo -u postgres psql loyalty -c "SELECT * FROM customers;"
```
Восстановленный бэкап на другом PG:
<img width="1428" height="538" alt="image" src="https://github.com/user-attachments/assets/97507b27-3cec-4a02-b331-bb8f523eb607" />

## 4. Снятие бэкапа под нагрузкой с реплики
На мастере (1-ая ВМ):
```
# Добавляем пользователя и слот для репликации
sudo -u postgres psql -c "CREATE ROLE replica WITH REPLICATION LOGIN PASSWORD 'replica_pass';"
sudo -u postgres psql -c "SELECT pg_create_physical_replication_slot('replica_slot');"

# Правим postgresql.conf
sudo nano /etc/postgresql/18/main/postgresql.conf

# Правим pg_hba.conf
sudo nano /etc/postgresql/18/main/pg_hba.conf

# Перезапуск мастера
sudo systemctl restart postgresql
```
Параметры postgresql.conf:
- listen_addresses = '*'
- wal_level = replica
- max_wal_senders = 10
- max_replication_slots = 10
<img width="1037" height="1068" alt="image" src="https://github.com/user-attachments/assets/a2d6ea64-75b3-41a9-8ccf-698a2f1006f1" />

Параметры pg_hba.conf:
- host replication replica 10.128.0.0/24 md5
<img width="1115" height="1083" alt="image" src="https://github.com/user-attachments/assets/1d60fa2c-066e-472e-8e0b-e35475829cce" />

На реплике (2 ВМ):
```
# Останавливаем PostgreSQL
sudo systemctl stop postgresql

# Удаляем всю папку main целиком
sudo rm -rf /var/lib/postgresql/18/main

# Создаём пустую папку с правильными правами
sudo mkdir -p /var/lib/postgresql/18/main
sudo chown postgres:postgres /var/lib/postgresql/18/main
sudo chmod 700 /var/lib/postgresql/18/main

# Проверяем, что папка пуста
sudo ls -la /var/lib/postgresql/18/main/

# Теперь выполняем pg_basebackup
sudo -u postgres pg_basebackup -h 10.128.0.9 -U replica -D /var/lib/postgresql/18/main -P -R -S replica_slot

# Запускаем реплику
sudo systemctl start postgresql
```

На мастере:
```
# Проверяем статус репликации
sudo -u postgres psql -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"

 client_addr |   state   | sync_state
-------------+-----------+------------
 10.128.0.15 | streaming | async
(1 row)
```
Репликация работает

Создаем непрерывную нагрузку на мастер:
```
# Бесконечный цикл вставки через командную строку
while true; do
    sudo -u postgres psql loyalty -c "INSERT INTO customers (id, name, bonus) VALUES (floor(random() * 1000000)::int, 'load_' || random(), random()::int);"
    sleep 0.1
done
```
Пытаемся снять бэкап с реплики:
```
sudo -u postgres pg_probackup-18 backup --instance main -b FULL -B /home/backups --no-sync
# no-sync — не ждать синхронизации, нагрузка постоянная - синхронизация достигается периодически
# можно еще добавить no-validate — не проверять целостность WAL

# Проверяем созданные бэкапы
sudo -u postgres pg_probackup-18 show -B /home/backups
```
Итоговый список бэкапов (последний - корректный):
<img width="1458" height="1024" alt="image" src="https://github.com/user-attachments/assets/d7f19a25-3ce9-4e1f-ae80-85bc22c9837e" />
Последний успешный, который был снят с реплики (до этого были ошибки из-за отсутствия нагрузки на мастер)

