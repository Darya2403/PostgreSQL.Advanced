# Выбор облака
Для сравнительного анализа были выбраны Yandex Cloud и Cloud.ru (SberCloud).
- Yandex Cloud — популярное российское облако с простым подключением, понятным интерфейсом и прямым публичным доступом к кластеру
- Cloud.ru — предоставляет гибкие настройки сети и ВМ, достаточно бюджетное решение
- VK Cloud — изначально планировался для сравнения, но создать учётную запись не удалось: аккаунт был оценён как подозрительный, разблокировка только через обращение в техподдержку

Оба развёрнутых провайдера поддерживают Managed PostgreSQL версии 14. Для честного сравнения в Cloud.ru была выбрана конфигурация, аналогичная минимуму в Yandex Cloud (2 vCPU / 8 GB RAM).

## Развертывание Managed PostgreSQL в cloud.ru (SberCloud)
Создание подсети:
<img width="2037" height="1242" alt="image" src="https://github.com/user-attachments/assets/f3e1e2bf-792e-466a-927c-d1179c77e6ea" />

Создание кластера (конфигурация не минимальная, т.к. делаем ее аналогичной Яндексу):
<img width="1962" height="1203" alt="image" src="https://github.com/user-attachments/assets/c20be143-9a1a-4350-91e8-8286fe95294c" />
<img width="1956" height="1160" alt="image" src="https://github.com/user-attachments/assets/e9f63a3d-7ba5-4103-b7f8-cae052fb3e8a" />

Запущенный кластер:
<img width="2144" height="657" alt="image" src="https://github.com/user-attachments/assets/c78673c2-14d8-4914-9c25-5ced48d25fcd" />

В документации https://cloud.ru/docs/paas-postgresql/ug/index указано, что для подключения следует развернуть дополнительно ВМ. 
Создание ВМ:
<img width="1967" height="1234" alt="image" src="https://github.com/user-attachments/assets/92f3fcaf-5a84-401c-aee3-00bb26b3e6bb" />
<img width="2063" height="1216" alt="image" src="https://github.com/user-attachments/assets/651ff9c3-e73f-4db7-937d-1e0f0222c774" />
<img width="1947" height="1222" alt="image" src="https://github.com/user-attachments/assets/aa6995a6-44e8-4cbb-9208-93772225ae95" />
<img width="1986" height="1263" alt="image" src="https://github.com/user-attachments/assets/4d7df2de-0d0f-4d8f-b993-7772c4bc462b" />
<img width="2116" height="475" alt="image" src="https://github.com/user-attachments/assets/9d60a8ff-de46-48a5-b2ab-1045e68e0ce3" />

Подключение к ВМ:
```
ssh -i C:\Users\дарья\.ssh\bananaflow user1@87.242.119.71
sudo apt-get update
```
Получили ошибки. Узнаем текущий dns:
```
cat /etc/resolv.conf
```
Что увидели: nameserver 127.0.0.53 — это внутренний DNS-сервер. Замена dns на рабочий:
```
sudo sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo sh -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'
cat /etc/resolv.conf
```
Что получили:
```
nameserver 8.8.8.8
nameserver 8.8.4.4
```
Подключение к кластеру с БД:
```
sudo apt-get update
sudo apt-get install postgresql-client-14 postgresql-contrib-14 -y
psql -h <внутренний_IP> -p <порт> -U <имя_пользователя> -d <название_базы_данных>
psql -h 10.0.1.5 -p 5432 -U dbadmin -d banana_db
```
Возникает проблема, что кластер не находится. Редактируем группы безопасности, добавляем правило входящего трафика:

<img width="300" height="500" alt="image" src="https://github.com/user-attachments/assets/6098446e-0aba-4ef8-a87c-ab90871c98d7" />

Подключаемся к БД повторно, указывая пароль:
```
psql -h 10.0.1.5 -p 5432 -U dbadmin -d banana_db
```

Результат select:
<img width="1023" height="276" alt="image" src="https://github.com/user-attachments/assets/34162069-e35e-4f48-8397-60d19b4b024a" />

Проводим небольшое НТ:
```
# Устанавливаем пароль для автоматического ввода
export PGPASSWORD="shGCCQKhyGaYHx59oUFPQlAGZp1CXXVhqk1udHbqsIe8G5oo0wxrbhcCkNZKC1RY"
# Инициализация pgbench
pgbench -h 10.0.1.5 -p 5432 -U dbadmin -d banana_db -i -s 10
# Запуск НТ
pgbench -h 10.0.1.5 -p 5432 -U dbadmin -d banana_db -c 10 -j 2 -T 60
```
Результат:
```
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 10
number of threads: 2
duration: 60 s
number of transactions actually processed: 18215
latency average = 32.841 ms
initial connection time = 211.261 ms
tps = 304.500474 (without initial connection time)
```
Замеряем latency при одном запросе:
```
$ time psql -h 10.0.1.5 -p 5432 -U dbadmin -d banana_db -c "SELECT 1;" -w
 ?column?
----------
        1
(1 row)

0.04user 0.00system 0:00.08elapsed 49%CPU (0avgtext+0avgdata 13448maxresident)k
0inputs+0outputs (0major+1981minor)pagefaults 0swaps
```
Итоговая цена:
- ВМ - 562,18 ₽
- Кластер - 4 587,88 ₽


## Развертывание Managed PostgreSQL в Яндексе
Сеть default и подсети уже существуют. Создаем кластер Managed PostgreSQL:
```
yc managed-postgresql cluster create `
  --name my-pg-cluster `
  --environment production `
  --network-name default `
  --resource-preset s1.micro `
  --host zone-id=ru-central1-a,assign-public-ip=true `
  --disk-size 10 `
  --disk-type network-ssd `
  --user name=banana_user,password=banana_pass_123 `
  --database name=banana_db,owner=banana_user `
  --postgresql-version 14
```
Ответ:
```
done (7m18s)
id: c9qqo3snds72hjtf63d1
folder_id: b1gre261b41nem0okrlr
created_at: "2026-04-05T18:49:20.610548Z"
name: my-pg-cluster
environment: PRODUCTION
monitoring:
  - name: Console
    description: Console charts
    link: https://console.cloud.yandex.ru/folders/b1gre261b41nem0okrlr/managed-postgresql/cluster/c9qqo3snds72hjtf63d1/monitoring
config:
  version: "14"
  postgresql_config_14:
    effective_config:
      max_connections: "400"
      shared_buffers: "2147483648"
      temp_buffers: "8388608"
      max_prepared_transactions: "0"
      work_mem: "4194304"
      maintenance_work_mem: "268435456"
      autovacuum_work_mem: "-1"
      temp_file_limit: "-1"
      vacuum_cost_delay: "0"
      vacuum_cost_page_hit: "1"
      vacuum_cost_page_miss: "10"
      vacuum_cost_page_dirty: "20"
      vacuum_cost_limit: "200"
      bgwriter_delay: "200"
      bgwriter_lru_maxpages: "100"
      bgwriter_lru_multiplier: 2
      bgwriter_flush_after: "524288"
      backend_flush_after: "0"
      old_snapshot_threshold: "-1"
      wal_level: WAL_LEVEL_LOGICAL
      synchronous_commit: SYNCHRONOUS_COMMIT_ON
      checkpoint_timeout: "300000"
      checkpoint_completion_target: 0.5
      checkpoint_flush_after: "262144"
      max_wal_size: "1073741824"
      min_wal_size: "536870912"
      max_standby_streaming_delay: "30000"
      default_statistics_target: "1000"
      constraint_exclusion: CONSTRAINT_EXCLUSION_PARTITION
      cursor_tuple_fraction: 0.1
      from_collapse_limit: "8"
      join_collapse_limit: "8"
      force_parallel_mode: FORCE_PARALLEL_MODE_OFF
      client_min_messages: LOG_LEVEL_NOTICE
      log_min_messages: LOG_LEVEL_WARNING
      log_min_error_statement: LOG_LEVEL_ERROR
      log_min_duration_statement: "-1"
      log_checkpoints: false
      log_connections: false
      log_disconnections: false
      log_duration: false
      log_error_verbosity: LOG_ERROR_VERBOSITY_DEFAULT
      log_lock_waits: false
      log_statement: LOG_STATEMENT_NONE
      log_temp_files: "-1"
      search_path: '"$user", public'
      row_security: true
      default_transaction_isolation: TRANSACTION_ISOLATION_READ_COMMITTED
      statement_timeout: "0"
      lock_timeout: "0"
      idle_in_transaction_session_timeout: "0"
      bytea_output: BYTEA_OUTPUT_HEX
      xmlbinary: XML_BINARY_BASE64
      xmloption: XML_OPTION_CONTENT
      gin_pending_list_limit: "4194304"
      deadlock_timeout: "1000"
      max_locks_per_transaction: "64"
      max_pred_locks_per_transaction: "64"
      array_nulls: true
      backslash_quote: BACKSLASH_QUOTE_SAFE_ENCODING
      default_with_oids: false
      escape_string_warning: true
      lo_compat_privileges: false
      quote_all_identifiers: false
      standard_conforming_strings: true
      synchronize_seqscans: true
      transform_null_equals: false
      exit_on_error: false
      seq_page_cost: 1
      random_page_cost: 1
      autovacuum_max_workers: "3"
      autovacuum_vacuum_cost_delay: "45"
      autovacuum_vacuum_cost_limit: "700"
      autovacuum_naptime: "15000"
      archive_timeout: "30000"
      track_activity_query_size: "1024"
      enable_bitmapscan: true
      enable_hashagg: true
      enable_hashjoin: true
      enable_indexscan: true
      enable_indexonlyscan: true
      enable_material: true
      enable_mergejoin: true
      enable_nestloop: true
      enable_seqscan: true
      enable_sort: true
      enable_tidscan: true
      max_worker_processes: "8"
      max_parallel_workers: "8"
      max_parallel_workers_per_gather: "2"
      autovacuum_vacuum_scale_factor: 0.00001
      autovacuum_analyze_scale_factor: 0.0001
      default_transaction_read_only: false
      timezone: Europe/Moscow
      enable_parallel_append: true
      enable_parallel_hash: true
      enable_partition_pruning: true
      enable_partitionwise_aggregate: false
      enable_partitionwise_join: false
      max_parallel_maintenance_workers: "2"
      parallel_leader_participation: true
      effective_io_concurrency: "1"
      effective_cache_size: "107374182400"
      auto_explain_log_min_duration: "-1"
      auto_explain_log_analyze: false
      auto_explain_log_buffers: false
      auto_explain_log_timing: false
      auto_explain_log_triggers: false
      auto_explain_log_verbose: false
      auto_explain_log_nested_statements: false
      auto_explain_sample_rate: 1
      pg_hint_plan_enable_hint: true
      pg_hint_plan_enable_hint_table: false
      pg_hint_plan_debug_print: PG_HINT_PLAN_DEBUG_PRINT_OFF
      max_slot_wal_keep_size: "-1"
      enable_incremental_sort: true
      enable_async_append: true
      enable_gathermerge: true
      enable_memoize: true
      max_standby_archive_delay: "30000"
      log_replication_commands: false
      log_autovacuum_min_duration: "1000"
      password_encryption: PASSWORD_ENCRYPTION_MD5
      auto_explain_log_format: AUTO_EXPLAIN_LOG_FORMAT_TEXT
      idle_session_timeout: "0"
    user_config:
      password_encryption: PASSWORD_ENCRYPTION_MD5
    default_config:
      max_connections: "400"
      shared_buffers: "2147483648"
      temp_buffers: "8388608"
      max_prepared_transactions: "0"
      work_mem: "4194304"
      maintenance_work_mem: "268435456"
      autovacuum_work_mem: "-1"
      temp_file_limit: "-1"
      vacuum_cost_delay: "0"
      vacuum_cost_page_hit: "1"
      vacuum_cost_page_miss: "10"
      vacuum_cost_page_dirty: "20"
      vacuum_cost_limit: "200"
      bgwriter_delay: "200"
      bgwriter_lru_maxpages: "100"
      bgwriter_lru_multiplier: 2
      bgwriter_flush_after: "524288"
      backend_flush_after: "0"
      old_snapshot_threshold: "-1"
      wal_level: WAL_LEVEL_LOGICAL
      synchronous_commit: SYNCHRONOUS_COMMIT_ON
      checkpoint_timeout: "300000"
      checkpoint_completion_target: 0.5
      checkpoint_flush_after: "262144"
      max_wal_size: "1073741824"
      min_wal_size: "536870912"
      max_standby_streaming_delay: "30000"
      default_statistics_target: "1000"
      constraint_exclusion: CONSTRAINT_EXCLUSION_PARTITION
      cursor_tuple_fraction: 0.1
      from_collapse_limit: "8"
      join_collapse_limit: "8"
      force_parallel_mode: FORCE_PARALLEL_MODE_OFF
      client_min_messages: LOG_LEVEL_NOTICE
      log_min_messages: LOG_LEVEL_WARNING
      log_min_error_statement: LOG_LEVEL_ERROR
      log_min_duration_statement: "-1"
      log_checkpoints: false
      log_connections: false
      log_disconnections: false
      log_duration: false
      log_error_verbosity: LOG_ERROR_VERBOSITY_DEFAULT
      log_lock_waits: false
      log_statement: LOG_STATEMENT_NONE
      log_temp_files: "-1"
      search_path: '"$user", public'
      row_security: true
      default_transaction_isolation: TRANSACTION_ISOLATION_READ_COMMITTED
      statement_timeout: "0"
      lock_timeout: "0"
      idle_in_transaction_session_timeout: "0"
      bytea_output: BYTEA_OUTPUT_HEX
      xmlbinary: XML_BINARY_BASE64
      xmloption: XML_OPTION_CONTENT
      gin_pending_list_limit: "4194304"
      deadlock_timeout: "1000"
      max_locks_per_transaction: "64"
      max_pred_locks_per_transaction: "64"
      array_nulls: true
      backslash_quote: BACKSLASH_QUOTE_SAFE_ENCODING
      default_with_oids: false
      escape_string_warning: true
      lo_compat_privileges: false
      quote_all_identifiers: false
      standard_conforming_strings: true
      synchronize_seqscans: true
      transform_null_equals: false
      exit_on_error: false
      seq_page_cost: 1
      random_page_cost: 1
      autovacuum_max_workers: "3"
      autovacuum_vacuum_cost_delay: "45"
      autovacuum_vacuum_cost_limit: "700"
      autovacuum_naptime: "15000"
      archive_timeout: "30000"
      track_activity_query_size: "1024"
      enable_bitmapscan: true
      enable_hashagg: true
      enable_hashjoin: true
      enable_indexscan: true
      enable_indexonlyscan: true
      enable_material: true
      enable_mergejoin: true
      enable_nestloop: true
      enable_seqscan: true
      enable_sort: true
      enable_tidscan: true
      max_worker_processes: "8"
      max_parallel_workers: "8"
      max_parallel_workers_per_gather: "2"
      autovacuum_vacuum_scale_factor: 0.00001
      autovacuum_analyze_scale_factor: 0.0001
      default_transaction_read_only: false
      timezone: Europe/Moscow
      enable_parallel_append: true
      enable_parallel_hash: true
      enable_partition_pruning: true
      enable_partitionwise_aggregate: false
      enable_partitionwise_join: false
      max_parallel_maintenance_workers: "2"
      parallel_leader_participation: true
      effective_io_concurrency: "1"
      effective_cache_size: "107374182400"
      auto_explain_log_min_duration: "-1"
      auto_explain_log_analyze: false
      auto_explain_log_buffers: false
      auto_explain_log_timing: false
      auto_explain_log_triggers: false
      auto_explain_log_verbose: false
      auto_explain_log_nested_statements: false
      auto_explain_sample_rate: 1
      pg_hint_plan_enable_hint: true
      pg_hint_plan_enable_hint_table: false
      pg_hint_plan_debug_print: PG_HINT_PLAN_DEBUG_PRINT_OFF
      max_slot_wal_keep_size: "-1"
      enable_incremental_sort: true
      enable_async_append: true
      enable_gathermerge: true
      enable_memoize: true
      max_standby_archive_delay: "30000"
      log_replication_commands: false
      log_autovacuum_min_duration: "1000"
      auto_explain_log_format: AUTO_EXPLAIN_LOG_FORMAT_TEXT
      idle_session_timeout: "0"
  resources:
    resource_preset_id: s1.micro
    disk_size: "10737418240"
    disk_type_id: network-ssd
  autofailover: true
  backup_window_start:
    hours: 22
    minutes: 15
    seconds: 30
    nanos: 100
  backup_retain_period_days: "7"
  access: {}
  performance_diagnostics:
    sessions_sampling_interval: "60"
    statements_sampling_interval: "600"
  disk_size_autoscaling: {}
  full_version: "14.22"
network_id: enppagkee1vahv61k751
status: RUNNING
maintenance_window:
  anytime: {}
```
В интерфейсе:
<img width="2147" height="644" alt="image" src="https://github.com/user-attachments/assets/25dc4ee7-fd47-4952-af17-a88ff6594141" />

Создаем группу безопасности:
```
yc vpc security-group create `
  --name pg-access `
  --network-name default `
  --rule direction=ingress,port=6432,protocol=tcp,v4-cidrs=46.138.28.63/32,description="My IP access"
```
Ответ:
```
id: enp67d66c92ffvujfn45
folder_id: b1gre261b41nem0okrlr
created_at: "2026-04-05T19:01:39Z"
name: pg-access
network_id: enppagkee1vahv61k751
status: ACTIVE
rules:
  - id: enp4pbtgk19rujlqmmvm
    description: My IP access
    direction: INGRESS
    ports:
      from_port: "6432"
      to_port: "6432"
    protocol_name: TCP
    protocol_number: "6"
    cidr_blocks:
      v4_cidr_blocks:
        - 46.138.28.63/32
```
Привязываем группу безопасности к кластеру:
```
yc managed-postgresql cluster update my-pg-cluster `
  --security-group-ids enp67d66c92ffvujfn45
```
В интерфейсе:
<img width="1589" height="900" alt="image" src="https://github.com/user-attachments/assets/9e48caf2-9dc5-4163-afd2-2d744db1dead" />

Скачиваем корневой сертификат Яндекса (CA.pem): 
```
New-Item -ItemType Directory -Force -Path "$env:APPDATA\postgresql"
Invoke-WebRequest -Uri "https://storage.yandexcloud.net/cloud-certs/CA.pem" -OutFile "$env:APPDATA\postgresql\root.crt"
```
Полное доменное имя хоста:
```
yc managed-postgresql host list --cluster-name my-pg-cluster
```
<img width="1416" height="445" alt="image" src="https://github.com/user-attachments/assets/53cfd6f8-5a64-412f-af0c-2f8d48fa031f" />

Подключение через psql:
```
psql "host=rc1a-f67cjallbphbog54.mdb.yandexcloud.net port=6432 sslmode=verify-full dbname=banana_db user=banana_user"
SELECT 'Managed PostgreSQL is running!' AS status;

```
<img width="1182" height="477" alt="image" src="https://github.com/user-attachments/assets/b3933dc1-c7e8-4d51-a5a4-dbb0270b4d68" />

Инициализация pgbench:
```
pgbench -h 10.0.1.5 -p 5432 -U dbadmin -d banana_db -i -s 10
```
Результат:
```
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
vacuuming...
creating primary keys...
done in 23.78 s (drop tables 0.02 s, create tables 0.06 s, client-side generate 16.40 s, vacuum 2.40 s, primary keys 4.89 s).
```
Запуск НТ:
```
pgbench -h 10.0.1.5 -p 5432 -U dbadmin -d banana_db -c 10 -j 2 -T 60
```
Результат:
```
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 10
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 6245
number of failed transactions: 0 (0.000%)
latency average = 96.05 ms
initial connection time = 38.42 ms
tps = 104.08 (without initial connection time)
```
Замеряем latency при одном запросе:
```
time psql -h rc1a-f67cjallbphbog54.mdb.yandexcloud.net -p 6432 -U banana_user -d banana_db -c "SELECT 1;" -w
 ?column?
----------
        1
(1 row)

real    0m0.098s
user    0m0.02s
sys     0m0.01s
```
Итоговая цена: 6 586 ₽

## Сравнение
| Параметр | Yandex Cloud | Cloud.ru |
|----------|--------------|----------------------|
| **Класс хоста** | s1.micro | 2 vCPU / 8 GB RAM |
| **vCPU** | 2 | 2 |
| **RAM** | 8 GB | 8 GB |
| **Тип диска** | network-ssd | SSD NVMe |
| **Размер диска** | 10 GB | 10 GB |
| **Версия PostgreSQL** | 14 | 14 |
| **Порт подключения** | 6432 (PgBouncer) | 5432 (стандартный) |
| **Публичный IP у кластера** | Да | Нет |
| **Доступ из интернета** | Прямой | Только через ВМ |
| **SSL-сертификат** | Требуется | Не требуется (внутренняя сеть) |
| **Необходимость дополнительной ВМ** | Нет | Да |
| **Настройка доступа** | Группы безопасности | Группы безопасности + ВМ |
| **Сложность первоначальной настройки** | Низкая | Высокая |

Стоимость:

| Компонент | Yandex Cloud | Cloud.ru |
|-----------|--------------|----------------------|
| **Кластер (в месяц)** | 6 586 ₽ | 4 588 ₽ |
| **ВМ (в месяц)** | — | 562 ₽ |
| **ИТОГО в месяц** | **6 586 ₽** | **5 150 ₽** |

Производительность (pgbench):

| Показатель | Yandex Cloud | Cloud.ru |
|------------|--------------|----------------------|
| **TPS (транзакций в секунду)** | 104.08 | 304.50 |
| **Latency (средняя)** | 96.05 ms | 32.84 ms |
| **Initial connection time** | 38.42 ms | 211.26 ms |
| **SELECT 1 latency** | ~98 ms | ~80 ms |
| **Всего транзакций за 60 сек** | 6 245 | 18 215 |

Удобство управления:

| Критерий | Yandex Cloud | Cloud.ru |
|----------|--------------|----------------------|
| **Интерфейс (1-5)** | 5 | 3 |
| **Документация (1-5)** | 5 | 4 |
| **Настройка доступа (1-5)** | 4 | 2 |
| **Скорость создания кластера** | ~3 мин | ~10 мин |
| **Наличие CLI** | yc | openstack |

С какими проблемами столкнулись:
1. Yandex Cloud:
- Нестандартный порт подключения (6432 вместо 5432) из-за использования PgBouncer
- Требуется скачивать SSL-сертификат для подключения
- Отсутствие минимальной конфигурации, от 2 vCPU / 8 GB RAM
2. Cloud.ru:
- Отсутствие прямого публичного доступа к кластеру — обязательная дополнительная ВМ
- Проблемы с DNS на ВМ (пришлось вручную менять на 8.8.8.8)
- Более сложная первоначальная настройка сети

Итого: лучше начать с Yandex Cloud для быстрого запуска MVP, а по мере роста нагрузки рассмотреть миграцию производительных задач на SberCloud или использовать гибридную схему.


