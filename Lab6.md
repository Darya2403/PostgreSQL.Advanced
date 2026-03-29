# Гонка за производительностью
## 1. Развертывание инстанса PostgreSQL на виртуальной машине в Яндекс.Облаке
Сеть default и подсети уже существуют. Создаем ВМ:
```
yc compute instance create `
  --name postgres `
  --hostname postgres `
  --zone ru-central1-a `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=20G,type=network-hdd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 `
  --ssh-key C:\Users\дарья\.ssh\bananaflow.pub
```
Ответ:
```
done (40s)
id: fhm6829v0p4ftl2lnttn
folder_id: b1ghlv94m814soortgjf
created_at: "2026-03-29T18:15:52Z"
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
  device_name: fhmmmi9av1csp5p62ntp
  auto_delete: true
  disk_id: fhmmmi9av1csp5p62ntp
network_interfaces:
  - index: "0"
    mac_address: d0:0d:64:09:3f:06
    subnet_id: e9bt51bbnhvmfnhr16s0
    primary_v4_address:
      address: 10.128.0.24
      one_to_one_nat:
        address: 158.160.47.152
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

Подключаемся к ВМ:
```
ssh -i C:\Users\дарья\.ssh\bananaflow yc-user@158.160.47.152
```

Устанавливаем PG:
```
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка PostgreSQL 18
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install -y postgresql-18 postgresql-contrib-18

# 3. Проверка PostgreSQL
sudo systemctl status postgresql
```
<img width="981" height="239" alt="image" src="https://github.com/user-attachments/assets/a9ba296d-cf3c-49af-828b-3ad21240725d" />

## 2. Тестирование производительности с помощью pgbench
```
# Переключаемся на пользователя postgres
sudo -i -u postgres

# Инициализируем тестовую БД со встроенными таблицами pgbench
# -s 10 = scale factor 10 → ~1 млн строк в основной таблице
pgbench -i -s 10 -d postgres
```
Ответ:
```
postgres@postgres:~$ pgbench -i -s 10 -d postgres
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
vacuuming...
creating primary keys...
done in 3.57 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 2.60 s, vacuum 0.17 s, primary keys 0.80 s).
```

Запускаем базовый тест, с которым будем проводить сравнение:
- 10 одновременных подключений (клиентов) к БД
- 2 потока для обработки этих 10 клиентов
- тест длится 30 секунд
```
postgres@postgres:~$ pgbench -c 10 -j 2 -T 30 -d postgres
pgbench (18.3 (Ubuntu 18.3-1.pgdg24.04+1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 10
number of threads: 2
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 27909
number of failed transactions: 0 (0.000%)
latency average = 10.751 ms
initial connection time = 25.565 ms
tps = 930.102849 (without initial connection time)
```
## 3. Оптимизация настроек для максимальной производительности PostgreSQL
### Отключение Transparent Huge Pages
Transparent Huge Pages (THP) - механизм ядра Linux, который автоматически объединяет маленькие страницы памяти (4 КБ) в большие (2 МБ), чтобы уменьшить накладные расходы на управление памятью.

```
# Проверка текущего состояния
cat /sys/kernel/mm/transparent_hugepage/enabled

# Создание сервиса для отключения
sudo nano /etc/systemd/system/disable-thp.service

# Активация
sudo systemctl daemon-reload
sudo systemctl enable disable-thp.service
sudo systemctl start disable-thp.service

# Проверка
cat /sys/kernel/mm/transparent_hugepage/enabled
```
Получили [never]

Наполнение /etc/systemd/system/disable-thp.service:
```
[Unit]
Description=Disable Transparent Huge Pages
[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
```
<img width="889" height="436" alt="image" src="https://github.com/user-attachments/assets/fa887827-2cff-4d22-8adf-48a2cd7e250c" />

Запуск теста:
```
postgres@postgres:~$ pgbench -c 10 -j 2 -T 30 -d postgres
pgbench (18.3 (Ubuntu 18.3-1.pgdg24.04+1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 10
number of threads: 2
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 33825
number of failed transactions: 0 (0.000%)
latency average = 8.865 ms
initial connection time = 22.700 ms
tps = 1127.977285 (without initial connection time)
```
Видим сильный прирост по производительности за счет отключения THP

### Изменение shared_buffers
shared_buffers — это параметр конфигурации в СУБД PostgreSQL, определяющий объем оперативной памяти, которую сервер базы данных использует для кэширования данных

Проверяем текущие настройки:
```
postgres@postgres:~$ psql -c "SHOW shared_buffers;"
 shared_buffers
----------------
 128MB
(1 row)

```
Выполняем следующие команды для изменения:
```
# Устанавливаем shared_buffers = 1GB (25% от 4 ГБ RAM)
psql -c "ALTER SYSTEM SET shared_buffers = '1GB';"

# Выходим из пользователя postgres
exit

# Перезагружаем PostgreSQL
sudo systemctl restart postgresql

# Возвращаемся к пользователю postgres
sudo -i -u postgres
```
Настройки применились:
```
postgres@postgres:~$ psql -c "SHOW shared_buffers;"
 shared_buffers
----------------
 1GB
(1 row)
```

Запускаем тестирование:
```
postgres@postgres:~$ pgbench -c 10 -j 2 -T 30 -d postgres
pgbench (18.3 (Ubuntu 18.3-1.pgdg24.04+1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 10
number of threads: 2
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 39770
number of failed transactions: 0 (0.000%)
latency average = 7.541 ms
initial connection time = 23.955 ms
tps = 1326.039018 (without initial connection time)
```
Вновь видим улучшение по производительности
- До: 128 МБ (дефолт) → часто обращался к диску
- После: 1 ГБ → больше данных в памяти → меньше дисковых операций → быстрее

### Изменение work_mem
work_mem — память, выделяемая на одну операцию сортировки, хеша или GROUP BY. Умножается на количество одновременных операций, поэтому меняем очень осторожно
Проверяем текущее значение:
```
postgres@postgres:~$ psql -c "SHOW work_mem;"
 work_mem
----------
 4MB
(1 row)
```
Выполняем изменения:
```
psql -c "ALTER SYSTEM SET work_mem = '16MB';"
psql -c "SELECT pg_reload_conf();"
```
Настройки применились:
```
postgres@postgres:~$ psql -c "SHOW work_mem;"
 work_mem
----------
 16MB
(1 row)
```
Запускаем тест:
```
postgres@postgres:~$ pgbench -c 10 -j 2 -T 30 -d postgres
pgbench (18.3 (Ubuntu 18.3-1.pgdg24.04+1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 10
number of threads: 2
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 39065
number of failed transactions: 0 (0.000%)
latency average = 7.679 ms
initial connection time = 24.864 ms
tps = 1302.289342 (without initial connection time)
```
На результат почти не повлияло.
Встроенный pgbench делает в основном UPDATE ... WHERE id = ? — никаких сортировок, хешей или GROUP BY.
work_mem выделяется на каждую сортировку/хеш отдельно. Если их нет в запросе — память не используется.
Также мало одновременных сложных запросов, при 10 клиентах и простых запросах лимит work_mem просто не достигается

### Изменение effective_cache_size
effective_cache_size — не выделяет память, а просто «подсказывает» планировщику, сколько памяти доступно для кэширования в ОС + PostgreSQL.
Это влияет на выбор плана запроса: если планировщик думает, что кэш большой — он чаще выбирает индексные сканирования вместо последовательных

Проверяем текущее значение:
```
postgres@postgres:~$ psql -c "SHOW effective_cache_size;"
 effective_cache_size
----------------------
 4GB
(1 row)
```
Выполняем следующие команды:
```
psql -c "ALTER SYSTEM SET effective_cache_size = '2GB';"
psql -c "SELECT pg_reload_conf();"
```
Результат изменений:
```
postgres@postgres:~$ psql -c "SHOW effective_cache_size;"
 effective_cache_size
----------------------
 2GB
(1 row)
```
Проводим тест:
```
postgres@postgres:~$ pgbench -c 10 -j 2 -T 30 -d postgres
pgbench (18.3 (Ubuntu 18.3-1.pgdg24.04+1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 10
number of threads: 2
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 42475
number of failed transactions: 0 (0.000%)
latency average = 7.060 ms
initial connection time = 25.805 ms
tps = 1416.346806 (without initial connection time)
```
Заметный прирост по сравнению с последним тестом. 
Планировщик получил более реалистичную оценку доступного кэша и начал чаще выбирать индексные сканирования вместо последовательных

### Изменение  effective_io_concurrency
effective_io_concurrency — подсказка планировщику, сколько параллельных операций ввода-вывода может выполнять дисковая подсистема.
Текущее значение:
```
postgres@postgres:~$ psql -c "SHOW effective_io_concurrency;"
 effective_io_concurrency
--------------------------
 16
(1 row)
```
Изменения:
```
psql -c "ALTER SYSTEM SET effective_io_concurrency = 100;"
psql -c "SELECT pg_reload_conf();"
```
Результат:
```
postgres@postgres:~$ psql -c "SHOW effective_io_concurrency;"
 effective_io_concurrency
--------------------------
 100
(1 row)
```
Запускаем тест:
```
postgres@postgres:~$ pgbench -c 10 -j 2 -T 30 -d postgres
pgbench (18.3 (Ubuntu 18.3-1.pgdg24.04+1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 10
number of threads: 2
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 43766
number of failed transactions: 0 (0.000%)
latency average = 6.852 ms
initial connection time = 23.992 ms
tps = 1459.327814 (without initial connection time)
```
Снова получили рост.
PostgreSQL теперь знает, что диск может выполнять ~100 параллельных операций чтения. 
Планировщик чаще использует Bitmap Heap Scan и параллельное предвыборку данных → меньше простоев в ожидании диска

### Изменение random_page_cost
random_page_cost — «стоимость» случайного чтения страницы с диска относительно последовательного.
Текущее значение:
```
postgres@postgres:~$ psql -c "SHOW random_page_cost;"
 random_page_cost
------------------
 4
(1 row)
```
Изменения:
```
psql -c "ALTER SYSTEM SET random_page_cost = 2.0;"
psql -c "SELECT pg_reload_conf();"
```
Результат:
```
postgres@postgres:~$ psql -c "SHOW random_page_cost;"
 random_page_cost
------------------
 2
(1 row)
```
Запускаем тест:
```
postgres@postgres:~$ pgbench -c 10 -j 2 -T 30 -d postgres
pgbench (18.3 (Ubuntu 18.3-1.pgdg24.04+1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 10
number of threads: 2
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 46995
number of failed transactions: 0 (0.000%)
latency average = 6.382 ms
initial connection time = 25.097 ms
tps = 1566.899037 (without initial connection time)
```
Заметный прирост.
Планировщик получил более реалистичную оценку стоимости случайного чтения для HDD. Теперь он:
- Чаще выбирает индексные сканирования для точечных запросов
- Реже ошибается в оценке стоимости планов
- Лучше балансирует между Index Scan и Seq Scan

### checkpoint_completion_target
checkpoint_completion_target — определяет, как плавно записывать данные на диск во время checkpoint.
```
postgres@postgres:~$ psql -c "SHOW checkpoint_completion_target;"
 checkpoint_completion_target
------------------------------
 0.9
(1 row)
```
В PG 18 значения выставлено и так оптимальным, ранее по дефолту было 0,5. Изменения для повышения производительности не требуются

### Иные настройки
Есть и более агрессивные настройки, но их применение абсолютно нецелесообразно:
- synchronous_commit = off
-- Плюсы: коммиты мгновенные, +10-30% TPS
-- Минусы: потеря последних транзакций при сбое питания
- fsync = off  
-- Плюсы: максимум скорости записи
-- Минусы: риск полной коррупции данных при крахе
- full_page_writes = off
-- Плюсы: меньше записи в WAL
-- Минусы: риск повреждения страниц при сбое
- work_mem = 256MB (на 4 ГБ RAM)
-- Плюсы: быстрые сортировки
-- Минусы: при одновременных сортировках OOM killer

В реальных БД можно подумать о следующих действиях (не все из этого подойдет):
- Включение логирования запросов >100 мс
  ```
  psql -c "ALTER SYSTEM SET log_min_duration_statement = 100;"
  psql -c "SELECT pg_reload_conf();"
  ```
- Проверка pg_stat_activity, pg_stat_statements
- Использовать pgBouncer для пулинга соединений
- Изменение default_statistics_target. Увеличивает точность статистики для планировщика, более оптимальные планы запросов, но сбор статистики будет чуть дольше
- Изменение maintenance_work_mem. Память для операций обслуживания: VACUUM, CREATE INDEX, ALTER TABLE. Не влияет на обычные запросы, но ускоряет фоновые задачи
- min_wal_size / max_wal_size: управляет размером WAL-файлов. Большие значения → реже чекпоинты → меньше пиков I/O, но больше места на диске, дольше восстановление после сбоя
- Настройка autovacuum
и т.д.

## 4. Сравнение производительности
| Этап | Настройка | Значение | TPS | Δ к базе | Δ к пред. | Latency (ms) | Δ latency |
|------------------|-----------|----------|-----|----------|-----------|--------------|-----------|
| **1. БАЗОВЫЙ** | — | — | **930.10** | 0% | — | 10.751 | 0% | Точка отсчёта |
| **2. Системный** | transparent_hugepages | never | **1127.98** | **+21.3%** | +21.3% | 8.865 | -17.5% |
| **3. Память** | shared_buffers | 1GB | **1326.04** | **+42.6%** | +17.6% | 7.541 | -29.9% |
| **4. Память** | work_mem | 16MB | **1302.29** | +40.0% | -1.8% | 7.679 | +1.8% |
| **5. Планировщик** | effective_cache_size | 2GB | **1416.35** | **+52.3%** | +8.8% | 7.060 | -34.3% |
| **6. Диск** | effective_io_concurrency | 100 | **1459.33** | **+56.9%** | +3.0% | 6.852 | -36.3% |
| **7. Планировщик** | random_page_cost | 2.0 | **1566.90** | **+68.5%** | +7.4% | 6.382 | -40.6% |
| **8. Чекпоинты** | checkpoint_completion_target | 0.9 | без изменений | — | — | — | — |
