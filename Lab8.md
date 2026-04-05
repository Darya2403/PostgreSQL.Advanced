# Managed Service for PostgreSQL
## Развертывание Managed PostgreSQL в Yandex Cloud
### Создание кластера
Сеть default и подсети уже существуют. Создаем кластер Managed PostgreSQL:
| Параметр | Значение | Описание |
|----------|----------|----------|
| `--name` | `my-pg-cluster` | Имя кластера |
| `--environment` | `production` | Продуктивное окружение |
| `--network-name` | `default` | Имя сети |
| `--resource-preset` | `s1.micro` | Минимальные параметры кластера |
| `--host zone-id` | `ru-central1-a` | Зона доступности |
| `--host assign-public-ip` | `true` | Публичный IP включён |
| `--disk-size` | `10` | Размер диска (GB) |
| `--disk-type` | `network-ssd` | Тип диска (SSD) |
| `--user` | `banana_user` | Имя пользователя БД |
| `--user password` | `banana_pass_123` | Пароль |
| `--database` | `banana_db` | Имя базы данных |
| `--postgresql-version` | `14` | Версия PostgreSQL |
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

В интерфейсе появилось следующее:
<img width="2147" height="644" alt="image" src="https://github.com/user-attachments/assets/25dc4ee7-fd47-4952-af17-a88ff6594141" />
<img width="2135" height="728" alt="image" src="https://github.com/user-attachments/assets/8ac67e8d-4660-4587-8753-7571570db93e" />
<img width="2144" height="615" alt="image" src="https://github.com/user-attachments/assets/104be347-7dda-41c7-92e2-9fbdc9aae3ab" />
<img width="2154" height="641" alt="image" src="https://github.com/user-attachments/assets/a46d6664-86ef-4b88-ac46-ef0f7a1a42cf" />


### Настройка доступа со своего IP адреса
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
В интерфейсе появилась группа безопасности:
<img width="1589" height="900" alt="image" src="https://github.com/user-attachments/assets/9e48caf2-9dc5-4163-afd2-2d744db1dead" />

### SSL-сертификат
Managed PostgreSQL в Yandex Cloud требует обязательного шифрования соединения. 
Скачиваем корневой сертификат Яндекса (CA.pem) и сохраняем его в папку %APPDATA%\postgresql\root.crt. 
psql автоматически найдет этот файл и использует для проверки сертификата сервера

```
New-Item -ItemType Directory -Force -Path "$env:APPDATA\postgresql"
Invoke-WebRequest -Uri "https://storage.yandexcloud.net/cloud-certs/CA.pem" -OutFile "$env:APPDATA\postgresql\root.crt"
```
### FQDN хоста
Необходимо узнать полное доменное имя хоста
```
yc managed-postgresql host list --cluster-name my-pg-cluster
```
<img width="1416" height="445" alt="image" src="https://github.com/user-attachments/assets/53cfd6f8-5a64-412f-af0c-2f8d48fa031f" />

### Подключение через psql
```
psql "host=rc1a-f67cjallbphbog54.mdb.yandexcloud.net port=6432 sslmode=verify-full dbname=banana_db user=banana_user"
SELECT 'Managed PostgreSQL is running!' AS status;

```
<img width="1182" height="477" alt="image" src="https://github.com/user-attachments/assets/b3933dc1-c7e8-4d51-a5a4-dbb0270b4d68" />

### Автомасштабирование
Создаем окно обслуживания - по расписанию (воскресенье в 3 часа ночи)
```
yc managed-postgresql cluster update my-pg-cluster --maintenance-window type=weekly,day=sun,hour=3
```
В интерфейсе:
<img width="1048" height="338" alt="image" src="https://github.com/user-attachments/assets/21573aaf-631a-4c0f-a15f-6be47abff2f8" />

Далее настраиваем автомасштабированиие и увеличиваем размер диска:

- disk-size-limit	20 - максимальный размер диска (в GB). Больше этого диски не вырастет
- planned-usage-threshold	80 - при заполнении диска на 80% — плановое увеличение
- emergency-usage-threshold	90 - при заполнении на 90% — экстренное увеличение
```
yc managed-postgresql cluster update my-pg-cluster --disk-size-autoscaling disk-size-limit=20,planned-usage-threshold=80,emergency-usage-threshold=90
```
В интерфейсе:
<img width="938" height="469" alt="image" src="https://github.com/user-attachments/assets/584be274-d903-4f64-b175-7e92dd4e2594" />

### Добавление IP в белый список
Добавляем в группу безопасности еще один адрес
```
yc vpc security-group update-rules pg-access --add-rule "direction=ingress,port=6432,protocol=tcp,v4-cidrs=213.87.153.213/32,description=My phone access"
```
<img width="1529" height="918" alt="image" src="https://github.com/user-attachments/assets/10896675-7fa9-41a4-ae0e-bd70327d529f" />

### Дополнительная информация из интерфейса
Операции с кластером:
<img width="2159" height="822" alt="image" src="https://github.com/user-attachments/assets/69fdbc24-3b4c-4ae6-83b0-4fa26b78df58" />
Мониторинг:
<img width="2149" height="1159" alt="image" src="https://github.com/user-attachments/assets/dc4405a3-2c50-4671-9380-9e191d8ae2ac" />
<img width="2125" height="1190" alt="image" src="https://github.com/user-attachments/assets/d6877c18-309e-4f90-8b75-115236d70c0f" />
Топология:
<img width="1270" height="488" alt="image" src="https://github.com/user-attachments/assets/2a3880bc-abde-4f22-9d3f-d96649fb1dcd" />





