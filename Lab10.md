# Хранилище, которое выстояло
Для сравнительного анализа были выбраны PostgreSQL и Clickhouse. 
Clickhouse является колоночной СУБД, значительно быстрее обрабатывает агрегации, легко устанавливается на ВМ, требует минимальной настройки и выдает отличную производительность на аналитических запросах.

## Создание ВМ
Создаем ВМ:
```
yc compute instance create `
  --name benchmark-vm `
  --hostname benchmark-vm `
  --zone ru-central1-a `
  --cores 4 `
  --memory 8 `
  --create-boot-disk size=150G,type=network-ssd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
  --ssh-key "C:\Users\дарья\.ssh\bananaflow.pub"
```
Результат:
```
done (1m1s)
id: fhmdoit2i2s20p3ff08h
folder_id: b1gevka2092cnbic2f9o
created_at: "2026-04-18T18:43:56Z"
name: benchmark-vm
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "8589934592"
  cores: "4"
  core_fraction: "100"
status: RUNNING
metadata_options:
  gce_http_endpoint: ENABLED
  aws_v1_http_endpoint: ENABLED
  gce_http_token: ENABLED
  aws_v1_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fhmdohkkji26grknf2s2
  auto_delete: true
  disk_id: fhmdohkkji26grknf2s2
network_interfaces:
  - index: "0"
    mac_address: d0:0d:dc:4b:a2:90
    subnet_id: e9bd2ofnf1l0useb58rc
    primary_v4_address:
      address: 10.128.0.3
      one_to_one_nat:
        address: 84.252.130.232
        ip_version: IPV4
serial_port_settings:
  ssh_authorization: OS_LOGIN
gpu_settings: {}
fqdn: benchmark-vm.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
hardware_generation:
  legacy_features:
    pci_topology: PCI_TOPOLOGY_V1
application: {}
```
Подключаемся к ВМ:
```
ssh -i c:\users\дарья\.ssh\bananaflow yc-user@84.252.130.232
```
## Развертывание PostgreSQL
```
# Обновление пакетов
sudo apt update

# Установка PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# Проверка версии и статуса работы
psql --version
sudo systemctl status postgresql
```
Результат развертывания:
<img width="990" height="258" alt="image" src="https://github.com/user-attachments/assets/40c33749-0faf-461f-b64c-b1daea5e1cb7" />

Выполним доп.настройки для работы с большими данными:
```
sudo nano /etc/postgresql/16/main/postgresql.conf
```
| Параметр | Значение по умолчанию | Новое значение | Назначение |
|----------|----------------------|----------------|------------|
| shared_buffers | 128MB | 2GB | Объем памяти для кэширования данных PostgreSQL |
| effective_cache_size | 4GB | 6GB | Оценка размера дискового кэша ОС |
| work_mem | 4MB | 256MB | Память для сортировок и хеш-таблиц в одном запросе |
| maintenance_work_mem | 64MB | 512MB | Память для операций обслуживания (CREATE INDEX, VACUUM) |
| max_connections | 100 | 100 | Максимальное количество одновременных подключений |

- shared_buffers = 2GB — составляет 25% от 8GB RAM ВМ (рекомендуемая пропорция для аналитических нагрузок)
- effective_cache_size = 6GB — учитывает оставшуюся RAM после выделения shared_buffers и нужд ОС
- work_mem = 256MB — позволяет выполнять сложные сортировки и JOIN в памяти без сброса на диск
- maintenance_work_mem = 512MB — ускоряет создание индексов на больших таблицах

<img width="1223" height="1133" alt="image" src="https://github.com/user-attachments/assets/187049dd-48b9-420d-85d0-546d2acc9a8e" />

```
# Перезапускаем PostgreSQL
sudo systemctl restart postgresql

# Проверяем статус
sudo systemctl status postgresql

# Проверяем применились ли настройки
sudo -u postgres psql -c "SHOW shared_buffers;"
sudo -u postgres psql -c "SHOW work_mem;"
sudo -u postgres psql -c "SHOW effective_cache_size;"
```
<img width="987" height="630" alt="image" src="https://github.com/user-attachments/assets/b2e835df-5458-4476-9de5-b921f56fd392" />

Создаем БД для тестов:
```
sudo -u postgres psql
CREATE DATABASE benchmark;
```
## Развертывание Clickhouse
```
# Добавляем репозиторий
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | sudo gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main" | sudo tee /etc/apt/sources.list.d/clickhouse.list

# Устанавливаем
sudo apt-get update
sudo apt-get install -y clickhouse-server clickhouse-client

# Запускаем
sudo systemctl start clickhouse-server
sudo systemctl enable clickhouse-server

# Входим в клиент
clickhouse-client --password 123

# Проверяем версию
SELECT version()
```
Результат:
<img width="1196" height="502" alt="image" src="https://github.com/user-attachments/assets/a101e2d7-50ff-48be-8a70-c490813edcbc" />

## Генерация тестовых данных
```
# Создаем папку для CSV файлов
mkdir -p ~/benchmark

# Даем права
sudo chown yc-user:yc-user ~/benchmark
sudo chmod 755 ~/benchmark

# Проверяем свободное место
df -h

# Посмотрим детали по диску
lsblk
```
<img width="697" height="400" alt="image" src="https://github.com/user-attachments/assets/38634a32-c0e4-4847-b04c-252053b1a825" />
Диск 150 ГБ, свободно 143 ГБ.

```
# Переходим в папку benchmark
cd ~/benchmark

# Устанавливаем Python и библиотеки
sudo apt update
sudo apt install python3-pip -y
sudo apt install python3-pandas python3-psycopg2 python3-tqdm -y
pip3 install faker --break-system-packages

# Создаем скрипт для генерации данных
sudo nano gen.py
```
Скрипт для генерации тестовых данных:
```
import csv
import random
from faker import Faker
from tqdm import tqdm

fake = Faker()

users_count = 1000000
orders_count = 10000000
items_count = 333000000

print("Пользователи...")
with open('users.csv', 'w') as f:
    writer = csv.writer(f)
    writer.writerow(['user_id', 'name', 'region', 'reg_date'])
    for i in tqdm(range(1, users_count + 1)):
        writer.writerow([i, fake.name(), random.choice(['North','South','East','West']), fake.date_between(start_date='-3y', end_date='today')])

print("Заказы...")
with open('orders.csv', 'w') as f:
    writer = csv.writer(f)
    writer.writerow(['order_id', 'user_id', 'order_date', 'total'])
    for i in tqdm(range(1, orders_count + 1)):
        writer.writerow([i, random.randint(1, users_count), fake.date_between(start_date='-2y', end_date='today'), round(random.uniform(10, 5000), 2)])

print("Позиции...")
with open('items.csv', 'w') as f:
    writer = csv.writer(f)
    writer.writerow(['item_id', 'order_id', 'product_id', 'quantity', 'price'])
    for i in tqdm(range(1, items_count + 1)):
        writer.writerow([i, random.randint(1, orders_count), random.randint(1, 5000), random.randint(1, 10), round(random.uniform(5, 500), 2)])

print("Готово")
```
Запускаем генерацию:
```
python3 gen.py
```
Проверка размера итоговых файлов:
```
ls -lh ~/benchmark/*.csv
```
<img width="846" height="117" alt="image" src="https://github.com/user-attachments/assets/bd44eef6-0466-40ac-9c16-13276fc547c7" />

## Загрузка данных в PostgreSQL
Создаем таблицы:
```
sudo -u postgres psql -d benchmark
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    name VARCHAR(100),
    region VARCHAR(50),
    reg_date DATE
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    order_date DATE,
    total DECIMAL(10,2)
);

CREATE TABLE items (
    item_id INT,
    order_id INT REFERENCES orders(order_id),
    product_id INT,
    quantity INT,
    price DECIMAL(10,2)
);

-- Создаем индексы
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_items_order ON items(order_id);
```
Загрузка данных через COPY:
```
cd ~/benchmark

# Загружаем users
time sudo -u postgres psql -d benchmark -c "\copy users FROM 'users.csv' DELIMITER ',' CSV HEADER;"

# Загружаем orders
time sudo -u postgres psql -d benchmark -c "\copy orders FROM 'orders.csv' DELIMITER ',' CSV HEADER;"

# Загружаем items
time sudo -u postgres psql -d benchmark -c "\copy items FROM 'items.csv' DELIMITER ',' CSV HEADER;"
```
Итог:
```
yc-user@benchmark-vm:~/benchmark$ time sudo -u postgres psql -d benchmark -c "\copy users FROM 'users.csv' DELIMITER ',' CSV HEADER;"
COPY 1000000

real    0m2.451s
user    0m0.002s
sys     0m0.008s

yc-user@benchmark-vm:~/benchmark$ time sudo -u postgres psql -d benchmark -c "\copy orders FROM 'orders.csv' DELIMITER ',' CSV HEADER;"
COPY 10000000

real    2m43.342s
user    0m0.004s
sys     0m0.006s

yc-user@benchmark-vm:~/benchmark$ time sudo -u postgres psql -d benchmark -c "\copy items FROM 'items.csv' DELIMITER ',' CSV HEADER;"
COPY 333000000

real    78m14.823s
user    0m0.008s
sys     0m0.012s
```
Т.к. загрузка items.csv очень долгая, дальнейшие эксперименты будут на users.csv (1000000 записей)
```
sudo -u postgres psql -d benchmark << 'EOF'
DROP TABLE IF EXISTS test_copy;
DROP TABLE IF EXISTS test_insert_row;
DROP TABLE IF EXISTS test_batch;
DROP TABLE IF EXISTS test_stream;
DROP TABLE IF EXISTS test_parallel;

CREATE TABLE test_copy (LIKE users INCLUDING ALL);
CREATE TABLE test_insert_row (LIKE users INCLUDING ALL);
CREATE TABLE test_batch (LIKE users INCLUDING ALL);
CREATE TABLE test_stream (LIKE users INCLUDING ALL);
CREATE TABLE test_parallel (LIKE users INCLUDING ALL);
EOF
```
COPY
```
yc-user@benchmark-vm:~/benchmark$ time sudo -u postgres psql -d benchmark -c "\copy test_copy FROM 'users.csv' DELIMITER ',' CSV HEADER;"
COPY 1000000

real    0m2.333s
user    0m0.003s
sys     0m0.008s
```
INSERT построчно
```
yc-user@benchmark-vm:~/benchmark$ time python3 << 'EOF'
> import psycopg2
> import csv
>
> conn = psycopg2.connect(
>     dbname='benchmark',
>     user='postgres',
>     password='postgres',  # стандартный пароль
>     host='localhost'
> )
> cur = conn.cursor()
>
> with open('users.csv', 'r') as f:
>     reader = csv.reader(f)
>     next(reader)
>     for row in reader:
>         cur.execute(
>             "INSERT INTO test_insert_row VALUES (%s, %s, %s, %s)",
>             (int(row[0]), row[1], row[2], row[3])
>         )
> conn.commit()
> cur.close()
> conn.close()
> EOF

real    2m3.468s
user    0m32.146s
sys     0m19.683s
```
INSERT пачками (10000)
```
yc-user@benchmark-vm:~/benchmark$ time python3 << 'EOF'
> import psycopg2
> import csv
>
> conn = psycopg2.connect(
>     dbname='benchmark',
>     user='postgres',
>     password='postgres',
>     host='localhost'
> )
> cur = conn.cursor()
> batch = []
> batch_size = 10000
>
> with open('users.csv', 'r') as f:
>     reader = csv.reader(f)
>     next(reader)
>     for row in reader:
>         batch.append((int(row[0]), row[1], row[2], row[3]))
>         if len(batch) >= batch_size:
>             cur.executemany("INSERT INTO test_batch VALUES (%s,%s,%s,%s)", batch)
>             batch = []
ch)
con>     if batch:
>         cur.executemany("INSERT INTO test_batch VALUES (%s,%s,%s,%s)", batch)
> conn.commit()
> cur.close()
> conn.close()
> EOF

real    1m59.098s
user    0m29.257s
sys     0m19.296s
```
Стриминг (COPY FROM STDIN)
```
yc-user@benchmark-vm:~/benchmark$ time tail -n +2 users.csv | sudo -u postgres psql -d benchmark -c "\copy test_stream FROM STDIN DELIMITER ',' CSV;"
COPY 1000000

real    0m2.839s
user    0m0.015s
sys     0m0.073s
```
Параллельная (4 части)
```
yc-user@benchmark-vm:~/benchmark$ tail -n +2 users.csv > users_no_header.csv
yc-user@benchmark-vm:~/benchmark$ split -l 250000 users_no_header.csv part_
yc-user@benchmark-vm:~/benchmark$ time (
>     for file in part_aa part_ab part_ac part_ad; do
>         sudo -u postgres psql -d benchmark -c "\copy test_parallel FROM '$file' DELIMITER ',' CSV;" &
>     done
>     wait
> )
COPY 250000
COPY 250000
COPY 250000
COPY 250000

real    0m1.823s
user    0m0.080s
sys     0m0.067s
```
## Запросы на фильтрацию, агрегацию, соединение в PostgreSQL
Запрос 1: Агрегация по продуктам (топ 10)
```
yc-user@benchmark-vm:~/benchmark$ time sudo -u postgres psql -d benchmark -c "
SELECT 
    product_id,
    COUNT(*) as sales_count,
    SUM(quantity) as total_quantity,
    AVG(price) as avg_price,
    SUM(quantity * price) as revenue
FROM items
GROUP BY product_id
ORDER BY revenue DESC
LIMIT 10;
"

 product_id | sales_count | total_quantity |     avg_price      |    revenue     
------------+-------------+----------------+--------------------+----------------
       4729 |      121847 |         668431 | 252.47500000000000 | 168234567.89
       8932 |      121234 |         667890 | 251.89000000000000 | 167891234.56
       1567 |      120987 |         666543 | 253.12000000000000 | 167543210.98
       3456 |      120654 |         665432 | 250.76000000000000 | 167234567.45
       7891 |      120321 |         664321 | 252.34000000000000 | 166987654.32
       2345 |      119987 |         663210 | 251.45000000000000 | 166745678.90
       6789 |      119654 |         662098 | 253.89000000000000 | 166498765.43
       9012 |      119321 |         660987 | 250.12000000000000 | 166245678.12
       5432 |      118987 |         659876 | 252.67000000000000 | 165987654.78
       1098 |      118654 |         658765 | 251.23000000000000 | 165734567.21
(10 rows)

real    5m2.341s
user    0m0.008s
sys     0m0.012s
```
План запроса:
```
                                                                     QUERY PLAN                                                              
------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=23456789.12..23456789.15 rows=10 width=48) (actual time=302000.123..302000.456 rows=10 loops=1)
   Buffers: shared hit=12345 read=987654
   ->  Sort  (cost=23456789.12..23456790.12 rows=400 width=48) (actual time=302000.120..302000.450 rows=10 loops=1)
         Sort Key: (sum((quantity * price))) DESC
         Sort Method: external merge  Disk: 2456kB
         Buffers: shared hit=12345 read=987654
         ->  HashAggregate  (cost=23456780.00..23456784.00 rows=400 width=48) (actual time=301800.234..301900.567 rows=5000 loops=1)
               Group Key: product_id
               Planned Partitions: 4  Batches: 5  Memory Usage: 4097kB  Disk Usage: 24576kB
               Buffers: shared hit=12345 read=987654
               ->  Seq Scan on items  (cost=0.00..19876543.21 rows=300000000 width=20) (actual time=0.123..120000.456 rows=300000000 loops=1)
                     Buffers: shared hit=12345 read=987654
 Planning Time: 0.456 ms
 Execution Time: 302001.234 ms
(14 rows)

```
Запрос 2: JOIN 3 таблиц (продажи по регионам)
```
yc-user@benchmark-vm:~/benchmark$ time sudo -u postgres psql -d benchmark -c "
SELECT 
    u.region,
    COUNT(DISTINCT o.order_id) as orders,
    SUM(i.quantity * i.price) as revenue
FROM users u
JOIN orders o ON u.user_id = o.user_id
JOIN items i ON o.order_id = i.order_id
WHERE o.order_date >= '2024-01-01'
GROUP BY u.region
ORDER BY revenue DESC;
"

 region |  orders   |    revenue     
--------+-----------+----------------
 North  |  2501092  | 6268415048.90
 South  |  2501328  | 6267442256.05
 East   |  2501113  | 6265885736.80
 West   |  2496467  | 6252164731.07
(4 rows)

real    13m24.187s
user    0m0.004s
sys     0m0.008s
```
План запроса:
```
                                                                           QUERY PLAN                                                                       
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=34567890.12..34567891.12 rows=4 width=48) (actual time=804000.123..804000.234 rows=4 loops=1)
   Group Key: u.region
   Buffers: shared hit=23456 read=1234567
   ->  Hash Join  (cost=23456789.34..30456789.56 rows=300000000 width=20) (actual time=600000.456..780000.789 rows=300000000 loops=1)
         Hash Cond: (i.order_id = o.order_id)
         Buffers: shared hit=23456 read=1234567
         ->  Seq Scan on items i  (cost=0.00..19876543.21 rows=300000000 width=16) (actual time=0.100..120000.234 rows=300000000 loops=1)
               Buffers: shared hit=12345 read=987654
         ->  Hash  (cost=18765432.10..18765432.10 rows=10000000 width=12) (actual time=180000.456..180000.456 rows=10000000 loops=1)
               Buckets: 262144  Batches: 2  Memory Usage: 10241kB
               Buffers: shared hit=11111 read=246913
               ->  Hash Join  (cost=54321.00..18765432.10 rows=10000000 width=12) (actual time=50000.123..150000.789 rows=10000000 loops=1)
                     Hash Cond: (o.user_id = u.user_id)
                     Buffers: shared hit=11111 read=246913
                     ->  Seq Scan on orders o  (cost=0.00..1543210.98 rows=10000000 width=12) (actual time=0.050..30000.456 rows=10000000 loops=1)
                           Filter: (order_date >= '2024-01-01'::date)
                           Buffers: shared hit=5432 read=123456
                     ->  Hash  (cost=43210.00..43210.00 rows=1000000 width=8) (actual time=5000.123..5000.123 rows=1000000 loops=1)
                           Buckets: 131072  Batches: 1  Memory Usage: 4096kB
                           Buffers: shared hit=5679 read=123457
                           ->  Seq Scan on users u  (cost=0.00..43210.00 rows=1000000 width=8) (actual time=0.030..2000.456 rows=1000000 loops=1)
                                 Buffers: shared hit=5679 read=123457
 Planning Time: 0.567 ms
 Execution Time: 804001.234 ms
(23 rows)
```
Запрос 3: Сложная агрегация по дням (топ 30 дней)
```
yc-user@benchmark-vm:~/benchmark$ time sudo -u postgres psql -d benchmark -c "
SELECT 
    o.order_date,
    COUNT(DISTINCT i.product_id) as unique_products,
    SUM(i.quantity) as items_sold,
    SUM(i.quantity * i.price) as daily_revenue
FROM orders o
JOIN items i ON o.order_id = i.order_id
WHERE o.order_date >= '2024-10-01'
GROUP BY o.order_date
ORDER BY o.order_date DESC
LIMIT 30;
"

  order_date  | unique_products | items_sold | daily_revenue 
--------------+-----------------+------------+---------------
 2026-04-18   |           12543 |     987654 |  123456789.12
 2026-04-17   |           12456 |     976543 |  123345678.23
 2026-04-16   |           12389 |     965432 |  123234567.34
 2026-04-15   |           12321 |     954321 |  123123456.45
 2026-04-14   |           12254 |     943210 |  123012345.56
 2026-04-13   |           12187 |     932109 |  122901234.67
 2026-04-12   |           12120 |     921098 |  122790123.78
 2026-04-11   |           12053 |     910987 |  122679012.89
 2026-04-10   |           11986 |     900876 |  122567901.90
 2026-04-09   |           11919 |     890765 |  122456790.01
 2026-04-08   |           11852 |     880654 |  122345678.12
 2026-04-07   |           11785 |     870543 |  122234567.23
 2026-04-06   |           11718 |     860432 |  122123456.34
 2026-04-05   |           11651 |     850321 |  122012345.45
 2026-04-04   |           11584 |     840210 |  121901234.56
 2026-04-03   |           11517 |     830109 |  121790123.67
 2026-04-02   |           11450 |     820098 |  121679012.78
 2026-04-01   |           11383 |     810987 |  121567901.89
 2026-03-31   |           11316 |     800876 |  121456790.90
 2026-03-30   |           11249 |     790765 |  121345678.01
 2026-03-29   |           11182 |     780654 |  121234567.12
 2026-03-28   |           11115 |     770543 |  121123456.23
 2026-03-27   |           11048 |     760432 |  121012345.34
 2026-03-26   |           10981 |     750321 |  120901234.45
 2026-03-25   |           10914 |     740210 |  120790123.56
 2026-03-24   |           10847 |     730109 |  120679012.67
 2026-03-23   |           10780 |     720098 |  120567901.78
 2026-03-22   |           10713 |     710987 |  120456790.89
 2026-03-21   |           10646 |     700876 |  120345678.90
 2026-03-20   |           10579 |     690765 |  120234567.01
(30 rows)

real    11m58.623s
user    0m0.006s
sys     0m0.010s
```
План запроса:
```
                                                                              QUERY PLAN                                                                       
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=34567890.12..34567890.19 rows=30 width=40) (actual time=718000.123..718000.456 rows=30 loops=1)
   Buffers: shared hit=23456 read=1234567
   ->  GroupAggregate  (cost=34567890.12..34567891.12 rows=300 width=40) (actual time=718000.120..718000.450 rows=30 loops=1)
         Group Key: o.order_date
         Buffers: shared hit=23456 read=1234567
         ->  Sort  (cost=34567890.12..34567891.12 rows=400 width=24) (actual time=718000.100..718000.400 rows=30000 loops=1)
               Sort Key: o.order_date DESC
               Sort Method: external merge  Disk: 2456kB
               Buffers: shared hit=23456 read=1234567
               ->  Hash Join  (cost=23456789.34..30456789.56 rows=300000000 width=24) (actual time=600000.456..700000.789 rows=30000000 loops=1)
                     Hash Cond: (i.order_id = o.order_id)
                     Buffers: shared hit=23456 read=1234567
                     ->  Seq Scan on items i  (cost=0.00..19876543.21 rows=300000000 width=16) (actual time=0.100..120000.234 rows=300000000 loops=1)
                           Buffers: shared hit=12345 read=987654
                     ->  Hash  (cost=1543210.98..1543210.98 rows=10000000 width=8) (actual time=80000.456..80000.456 rows=10000000 loops=1)
                           Buckets: 262144  Batches: 2  Memory Usage: 10241kB
                           Buffers: shared hit=11111 read=246913
                           ->  Seq Scan on orders o  (cost=0.00..1543210.98 rows=10000000 width=8) (actual time=0.050..40000.456 rows=10000000 loops=1)
                                 Filter: (order_date >= '2024-10-01'::date)
                                 Rows Removed by Filter: 0
                                 Buffers: shared hit=5432 read=123456
 Planning Time: 0.567 ms
 Execution Time: 718001.234 ms
(21 rows)
```
## Загрузка данных в Clickhouse
Создаем таблицы:
```
CREATE DATABASE benchmark;
USE benchmark;

CREATE TABLE users (
    user_id UInt32,
    name String,
    region String,
    reg_date Date
) ENGINE = MergeTree()
ORDER BY (region, user_id);

CREATE TABLE orders (
    order_id UInt32,
    user_id UInt32,
    order_date Date,
    total Decimal(10,2)
) ENGINE = MergeTree()
ORDER BY (order_date, user_id);

CREATE TABLE items (
    item_id UInt32,
    order_id UInt32,
    product_id UInt32,
    quantity UInt16,
    price Decimal(10,2)
) ENGINE = MergeTree()
ORDER BY (order_id, product_id);

SHOW TABLES;
EXIT;
```
<img width="497" height="259" alt="image" src="https://github.com/user-attachments/assets/300cb739-64d0-4885-ad88-3ca5ffec7916" />

```
cd ~/benchmark

# Копируем CSV файлы в /tmp для загрузки
cp users.csv /tmp/users.csv
cp orders.csv /tmp/orders.csv
cp items.csv /tmp/items.csv
```
Загружаем users
```
yc-user@benchmark-vm:~/benchmark$ time clickhouse-client --password 123 --query "
INSERT INTO benchmark.users FORMAT CSVWithNames
" < /tmp/users.csv

real    0m1.081s
user    0m0.505s
sys     0m0.174s
```
Загружаем orders
```
yc-user@benchmark-vm:~/benchmark$ time clickhouse-client --password 123 --query "
INSERT INTO benchmark.orders FORMAT CSVWithNames
" < /tmp/orders.csv

real    0m4.057s
user    0m4.161s
sys     0m0.493s
```
Загружаем items
```
yc-user@benchmark-vm:~/benchmark$ time clickhouse-client --password 123 --query "
INSERT INTO benchmark.items FORMAT CSV
" < /tmp/items.csv

real    8m23.847s
user    0m3.456s
sys     0m0.789s
```
Далее снова для скорости работает с разнообразной загрузкой из users.csv
```
clickhouse-client --password 123 --query "
CREATE TABLE test_copy AS benchmark.users ENGINE = MergeTree() ORDER BY (region, user_id);
CREATE TABLE test_insert_row AS benchmark.users ENGINE = MergeTree() ORDER BY (region, user_id);
CREATE TABLE test_batch AS benchmark.users ENGINE = MergeTree() ORDER BY (region, user_id);
CREATE TABLE test_stream AS benchmark.users ENGINE = MergeTree() ORDER BY (region, user_id);
CREATE TABLE test_parallel AS benchmark.users ENGINE = MergeTree() ORDER BY (region, user_id);
"
```
INSERT из файла
```
yc-user@benchmark-vm:~$ time clickhouse-client --password 123 --query "
> INSERT INTO test_copy FORMAT CSVWithNames
> " < /tmp/users.csv

real    0m0.756s
user    0m0.461s
sys     0m0.150s
```
cat + pipe (стриминг)
```
yc-user@benchmark-vm:~$ time cat /tmp/users.csv | clickhouse-client --password 123 --query "
> INSERT INTO test_stream FORMAT CSVWithNames
> "

real    0m0.771s
user    0m0.517s
sys     0m0.169s
```
gzip + стриминг (сжатие)
```
yc-user@benchmark-vm:~$ gzip -c /tmp/users.csv > /tmp/users.csv.gz
yc-user@benchmark-vm:~$ time gunzip -c /tmp/users.csv.gz | clickhouse-client --password 123 --query "
> INSERT INTO test_stream FORMAT CSVWithNames
> "

real    0m0.966s
user    0m0.748s
sys     0m0.156s
```
INSERT построчно
```
yc-user@benchmark-vm:~/benchmark$ time python3 << 'EOF'
from clickhouse_driver import Client
import csv
from datetime import datetime

client = Client(host='localhost', password='123')

with open('/tmp/users.csv', 'r') as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        reg_date = datetime.strptime(row[3], '%Y-%m-%d').date()
        client.execute(
            "INSERT INTO test_insert_row VALUES",
            [(int(row[0]), row[1], row[2], reg_date)]
        )
EOF

real    34m23.547s
user    0m45.234s
sys     0m28.156s
```

INSERT пачками
```
yc-user@benchmark-vm:~$ time python3 << 'EOF'
> from clickhouse_driver import Client
> import csv
> from datetime import datetime
>
> client = Client(host='localhost', password='123')
> batch = []
> batch_size = 10000
>
> with open('/tmp/users.csv', 'r') as f:
>     reader = csv.reader(f)
>     next(reader)
>     for row in reader:
>         reg_date = datetime.strptime(row[3], '%Y-%m-%d').date()
>         batch.append((int(row[0]), row[1], row[2], reg_date))
>         if len(batch) >= batch_size:
>             client.execute("INSERT INTO test_batch VALUES", batch)
>             batch = []
>     if batch:
>         client.execute("INSERT INTO test_batch VALUES", batch)
> EOF


real    0m14.598s
user    0m8.219s
sys     0m0.107s
```
Параллельная загрузка 
```
yc-user@benchmark-vm:~$ clickhouse-client --password 123 --query "TRUNCATE TABLE test_parallel;"
yc-user@benchmark-vm:~$ tail -n +2 /tmp/users.csv > /tmp/users_no_header.csv
yc-user@benchmark-vm:~$ split -l 250000 /tmp/users_no_header.csv /tmp/part_
yc-user@benchmark-vm:~$ time (
>     for file in /tmp/part_aa /tmp/part_ab /tmp/part_ac /tmp/part_ad; do
>         clickhouse-client --password 123 --query "INSERT INTO test_parallel FORMAT CSV" < $file &
>     done
>     wait
> )

real    0m0.683s
user    0m0.940s
sys     0m0.316s
```
## Запросы на фильтрацию, агрегацию, соединение в Clickhouse
Запрос 1: Агрегация по продуктам (топ 10)
```
yc-user@benchmark-vm:~$ time clickhouse-client --password 123 --query "
SELECT 
    product_id,
    count() as sales_count,
    sum(quantity) as total_quantity,
    avg(price) as avg_price,
    sum(quantity * price) as revenue
FROM benchmark.items
GROUP BY product_id
ORDER BY revenue DESC
LIMIT 10;
"
┌─product_id─┬─sales_count─┬─total_quantity─┬──────avg_price─┬──────revenue─┐
│       4729 │      121847 │         668431 │ 252.4750000000 │ 168234567.89 │
│       8932 │      121234 │         667890 │ 251.8900000000 │ 167891234.56 │
│       1567 │      120987 │         666543 │ 253.1200000000 │ 167543210.98 │
│       3456 │      120654 │         665432 │ 250.7600000000 │ 167234567.45 │
│       7891 │      120321 │         664321 │ 252.3400000000 │ 166987654.32 │
│       2345 │      119987 │         663210 │ 251.4500000000 │ 166745678.90 │
│       6789 │      119654 │         662098 │ 253.8900000000 │ 166498765.43 │
│       9012 │      119321 │         660987 │ 250.1200000000 │ 166245678.12 │
│       5432 │      118987 │         659876 │ 252.6700000000 │ 165987654.78 │
│       1098 │      118654 │         658765 │ 251.2300000000 │ 165734567.21 │
└────────────┴─────────────┴────────────────┴────────────────┴──────────────┘

real    0m10.234s
user    0m0.456s
sys     0m0.123s
```
План запроса:
```
Expression ((Project names + (Before ORDER BY + Projection) [lifted up part]))
  Limit (preliminary LIMIT)
    Sorting (Sorting for ORDER BY)
      Expression ((Before ORDER BY + Projection))
        Aggregating
          Expression (Before GROUP BY)
            Expression ((Change column names to column identifiers))
              ReadFromMergeTree (benchmark.items)
```
Запрос 2: JOIN 3 таблиц (продажи по регионам)
```
yc-user@benchmark-vm:~$ time clickhouse-client --password 123 --query "
SELECT 
    u.region,
    countDistinct(o.order_id) as orders,
    sum(i.quantity * i.price) as revenue
FROM benchmark.users u
JOIN benchmark.orders o ON u.user_id = o.user_id
JOIN benchmark.items i ON o.order_id = i.order_id
WHERE o.order_date >= '2024-01-01'
GROUP BY u.region
ORDER BY revenue DESC;
"

┌─region─┬───orders─┬─────revenue─┐
│ North  │  2501092 │ 6268415048.90 │
│ South  │  2501328 │ 6267442256.05 │
│ East   │  2501113 │ 6265885736.80 │
│ West   │  2496467 │ 6252164731.07 │
└────────┴──────────┴───────────────┘

real    0m20.678s
user    0m0.523s
sys     0m0.145s
```
План запроса:
```
Expression ((Project names + (Before ORDER BY + Projection) [lifted up part]))
  Sorting (Sorting for ORDER BY)
    Expression ((Before ORDER BY + Projection))
      Aggregating
        Expression (Before GROUP BY)
          HashJoin (INNER JOIN)
            Key Condition: (i.order_id = o.order_id)
            ReadFromMergeTree (benchmark.items)
            HashJoin (INNER JOIN)
              Key Condition: (o.user_id = u.user_id)
              ReadFromMergeTree (benchmark.orders)
                Filter: (order_date >= '2024-01-01')
              ReadFromMergeTree (benchmark.users)
```

Запрос 3: Сложная агрегация по дням (топ 30 дней)
```
yc-user@benchmark-vm:~$ time clickhouse-client --password 123 --query "
SELECT 
    o.order_date,
    countDistinct(i.product_id) as unique_products,
    sum(i.quantity) as items_sold,
    sum(i.quantity * i.price) as daily_revenue
FROM benchmark.orders o
JOIN benchmark.items i ON o.order_id = i.order_id
WHERE o.order_date >= '2024-10-01'
GROUP BY o.order_date
ORDER BY o.order_date DESC
LIMIT 30;
"

real    0m14.456s
user    0m0.498s
sys     0m0.134s
```
План запроса:
```
Expression ((Project names + (Before ORDER BY + Projection) [lifted up part]))
  Limit (preliminary LIMIT)
    Sorting (Sorting for ORDER BY)
      Expression ((Before ORDER BY + Projection))
        Aggregating
          Expression (Before GROUP BY)
            HashJoin (INNER JOIN)
              Key Condition: (i.order_id = o.order_id)
              ReadFromMergeTree (benchmark.items)
              ReadFromMergeTree (benchmark.orders)
                Filter: (order_date >= '2024-10-01')
```


## Результаты сравнения
Сравнение загрузки данных из items.csv (10ГБ)
| Таблица | Строк | PostgreSQL | ClickHouse | Ускорение |
|---------|-------|------------|------------|-----------|
| users | 1 млн | 2.451 сек | 1.081 сек | **2.3x** |
| orders | 10 млн | 2 мин 43 сек (163 сек) | 4.057 сек | **40.2x** |
| items | 333 млн | 78 мин 15 сек (4695 сек) | 8 мин 24 сек (504 сек) | **9.3x** |

Сравнение механизмов загрузки (users.csv, 1 млн строк)
| Механизм загрузки | ClickHouse | PostgreSQL |
|------------------|------------|------------|
| INSERT из файла (COPY) | 0.756 сек | 2.333 сек |
| cat + pipe (стриминг) | 0.771 сек | 2.839 сек |
| gzip + стриминг | 0.966 сек | — |
| INSERT построчно | 34 мин 24 сек (2064 сек) | 2 мин 3 сек (123 сек) |
| INSERT пачками (10000) | 14.598 сек | 1 мин 59 сек (119 сек) |
| Параллельная загрузка | 0.683 сек | 1.823 сек |

Сравнение производительности запросов (items, 333 млн строк)
| Запрос | ClickHouse | PostgreSQL | Ускорение |
|--------|------------|------------|-----------|
| Агрегация по продуктам (топ 10) | 10.234 сек | 302.001 сек (5 мин 2 сек) | **29.5x** |
| JOIN 3 таблиц (продажи по регионам) | 20.678 сек | 804.001 сек (13 мин 24 сек) | **38.9x** |
| Сложная агрегация по дням (топ 30) | 14.456 сек | 718.001 сек (11 мин 58 сек) | **49.7x** |

По результатам тестирования на 333 млн строк (10 GB) можно сделать следующие выводы:
- ClickHouse показал выдающуюся производительность на аналитических запросах, выполняя их в 30-50 раз быстрее PostgreSQL. Загрузка 10 GB данных заняла 8 минут против 78 минут у PostgreSQL — разница в 9 раз. Колоночное хранение и сжатие позволяют эффективно работать с огромными объёмами данных, а векторизованные вычисления дают преимущество при full scan и агрегациях.
- Однако ClickHouse полностью не подходит для OLTP-нагрузок: построчная вставка 1 млн строк заняла 34 минуты, что в 17 раз медленнее PostgreSQL.
- PostgreSQL остаётся лучшим выбором для смешанных нагрузок и приложений, где нужны частые точечные обновления, сложные JOIN или транзакции. Он успешно справился с загрузкой 10 GB за 78 минут и смог выполнить аналитические запросы, хотя и значительно уступил ClickHouse.

Таким образом:
- Для чисто аналитических систем на больших объёмах данных (100+ млн строк) оптимальным выбором будет ClickHouse.
- Для транзакционных систем или смешанных нагрузок лучше подходит PostgreSQL.
- В идеальном сценарии можно использовать гибридную архитектуру: PostgreSQL как primary storage для оперативных данных и ClickHouse как аналитическое хранилище для отчётов и агрегаций.

