# Спасение данных на внешнем диске
## 1. Создание виртуальной машины с Ubuntu 24.04 и установка PostgreSQL 16
Создание ВМ:
- Имя: bananaflow-disk
- ОС: Ubuntu 20.04 LTS
- vCPU: 2
- RAM: 2 ГБ
- Диск: 20 ГБ

<img width="500" height="500" alt="image" src="https://github.com/user-attachments/assets/9f972c72-2861-45b1-8eb1-e47de655f199" />
<img width="500" height="500" alt="image" src="https://github.com/user-attachments/assets/ee331b90-988e-4981-9d23-f91ad49a9475" />
<img width="500" height="500" alt="image" src="https://github.com/user-attachments/assets/bfba590a-d9d9-4e92-b879-9fcbf86ce497" />

Запущенная ВМ по адресу 93.77.185.107

<img width="600" height="100" alt="image" src="https://github.com/user-attachments/assets/86bcabf8-0d89-4dfc-bc44-8fec98991eb9" />

Подключение к ВМ по SSH:

<img width="400" height="600" alt="image" src="https://github.com/user-attachments/assets/6683f69c-f41c-4587-9820-5e679c80f078" />

В задании требовалось установить PostgreSQL 15 или выше на Ubuntu 20.04. При попытке выполнения возникла ошибка 404 при подключении репозитория PostgreSQL.

Попытка установить завершалась 404 ошибкой:
<img width="1000" height="800" alt="image" src="https://github.com/user-attachments/assets/b3ea6b8d-bf6f-47ac-9127-96d93d6c2642" />

В http://apt.postgresql.org/pub/repos/apt/dists/ отсутствует директория focal-pgdg. Т.е. официальный репозиторий PostgreSQL не содержит готовых пакетов для Ubuntu 20.04 (Focal) для версий 15 и выше.
PostgreSQL поддерживает только актуальные LTS-версии Ubuntu (22.04 или 24.04). Ubuntu 20.04 считается устаревшей для новых версий PostgreSQL

Было принято решение перейти на Ubuntu 24.04, где PostgreSQL 15+ поддерживается официально. В лабораторной поставим 16 версию.

Пересоздаю ВМ с ubuntu 24.04

<img width="400" height="400" alt="image" src="https://github.com/user-attachments/assets/2728d87a-ca04-4153-93bb-e2e9e51ca68d" />

Новый адрес: 93.77.185.203

```
# Обновление списка пакетов
sudo apt update
# Установка PostgreSQL 16
sudo apt install -y postgresql-16 postgresql-client-16 postgresql-contrib-16
```

<img width="800" height="500" alt="image" src="https://github.com/user-attachments/assets/8ca6b778-a3c7-48e7-aa5f-e60d904532a3" />

Вывод показывает работающий кластер PostgreSQL 16

pg_lsclusters

<img width="600" height="100" alt="image" src="https://github.com/user-attachments/assets/637c9c37-4692-401b-bc1a-b650fe416037" />

## 2. Создание таблицы с данными о перевозках
Заходим под пользователем
- sudo -i -u postgres
```
psql << EOF
-- Создаем базу данных
CREATE DATABASE shipments_db;

-- Подключаемся к новой базе
\c shipments_db;

-- Создаем таблицу перевозок
CREATE TABLE shipments (
    id SERIAL PRIMARY KEY,
    product_name TEXT,
    quantity INT,
    destination TEXT
);

-- Заполняем тестовыми данными
INSERT INTO shipments (product_name, quantity, destination) VALUES
    ('bananas', 1000, 'Europe'),
    ('bananas', 1500, 'Asia'),
    ('bananas', 2000, 'Africa'),
    ('coffee', 500, 'USA'),
    ('coffee', 700, 'Canada'),
    ('coffee', 300, 'Japan'),
    ('sugar', 1000, 'Europe'),
    ('sugar', 800, 'Asia'),
    ('sugar', 600, 'Africa'),
    ('sugar', 400, 'USA');

-- Проверяем данные
SELECT * FROM shipments;
EOF
```
<img width="600" height="400" alt="image" src="https://github.com/user-attachments/assets/a0077643-91aa-4165-a0be-eaa76dcedf17" />


## 3. Добавление внешнего диска к виртуальной машине и перенос туда базы данных
Создаем новый диск

<img width="400" height="400" alt="image" src="https://github.com/user-attachments/assets/c81f49aa-90c2-43b4-ac40-72e10c8098fd" />

Подключаем диск

<img width="400" height="200" alt="image" src="https://github.com/user-attachments/assets/98163af9-c2e2-479e-8b88-11aa4e194973" />

Просмотр подключенных дисков: sudo lsblk
- vda - системный диск
- vdb - новый диск (20 ГБ) - это наш новый внешний диск

<img width="300" height="200" alt="image" src="https://github.com/user-attachments/assets/6355de10-cce0-4444-998f-af76f158503d" />

Создаем раздел на диске
- n - создать новый раздел
- p - создать primary раздел
- 1 - номер раздела 1
- Пустые строки - использовать весь диск
- w - записать изменения

<img width="600" height="400" alt="image" src="https://github.com/user-attachments/assets/a2d43dc7-eccb-4ce3-8cf7-5ce5d4b7b9d3" />

Проверяем, что раздел появился - все выполнено корректно

<img width="300" height="200" alt="image" src="https://github.com/user-attachments/assets/aef34292-a9ee-4519-a05d-83b58ea9144d" />

Далее выполняем форматирование раздела в файловую систему ext4
- sudo mkfs.ext4 /dev/vdb1
<img width="600" height="200" alt="image" src="https://github.com/user-attachments/assets/1f2aab49-4d91-4b6a-8bb0-bb7908405d2e" />

```
# Создание папки для монтирования
sudo mkdir -p /mnt/external_disk

# Монтирование раздела
sudo mount /dev/vdb1 /mnt/external_disk

# Проверка монтирования
df -h | grep external_disk
# Вывод показывает размер и точку монтирования
```

<img width="600" height="100" alt="image" src="https://github.com/user-attachments/assets/3d73544f-5572-4f39-90f5-a9bcf1f65850" />

```
# Получение UUID диска (уникальный идентификатор)
sudo blkid /dev/vdb1
# Вывод: /dev/vdb1: UUID="66d137b6-cd54-4498-b6c7-230718fb603c" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="26afe9bb-01"

# Добавление записи в /etc/fstab для автоматического монтирования при загрузке
echo "UUID=$(sudo blkid -s UUID -o value /dev/vdb1) /mnt/external_disk ext4 defaults 0 2" | sudo tee -a /etc/fstab

# Проверка корректности fstab
sudo mount -a
```
Файл /etc/fstab содержит инструкции для монтирования дисков при загрузке системы. Использование UUID гарантирует, что диск будет найден даже если его имя изменится

## 4. Настройка PostgreSQL для работы с новым диском
```
# Создание папки для данных
sudo mkdir -p /mnt/external_disk/postgresql/16/main

# Назначение владельца - пользователь postgres
sudo chown -R postgres:postgres /mnt/external_disk/postgresql

# Установка прав доступа
sudo chmod 700 /mnt/external_disk/postgresql/16/main
```

```
# Остановка сервиса
sudo systemctl stop postgresql

# Проверка, что сервис остановлен
sudo systemctl status postgresql
# Получаем: inactive (dead)
```
Копирование всех файлов базы данных
- sudo rsync -av /var/lib/postgresql/16/main/ /mnt/external_disk/postgresql/16/main/

<img width="800" height="500" alt="image" src="https://github.com/user-attachments/assets/29935498-8a6b-49ac-bd40-b73e0dc81adc" />

Проверка содержимого:

<img width="600" height="400" alt="image" src="https://github.com/user-attachments/assets/f5a4f20e-eea4-469e-ab48-e6814f97047a" />

```
# Переименование старой папки в .backup
sudo mv /var/lib/postgresql/16/main /var/lib/postgresql/16/main.backup

# Проверка бэкапа
ls -la /var/lib/postgresql/16/
```

<img width="600" height="100" alt="image" src="https://github.com/user-attachments/assets/3cfa4ec0-fe07-4f45-a9a8-7e8b09354a83" />

Редактируем конфигурационный файл для изменения параметра data_directory, который указывает PostgreSQL, где физически находятся файлы базы данных

<img width="600" height="600" alt="image" src="https://github.com/user-attachments/assets/1ccd611d-86fc-414e-a874-eb51c3df4a38" />

Запускаем PostgreSQL и проверяем статус - active

<img width="600" height="100" alt="image" src="https://github.com/user-attachments/assets/92abcfa7-8b90-4672-9116-4166c6bb7964" />


## 5. Проверка, что данные сохранились и доступны
Подключение к базе и проверка данных
- psql -d shipments_db -c "SELECT * FROM shipments;"
<img width="600" height="200" alt="image" src="https://github.com/user-attachments/assets/3978d552-5d34-4261-ab3e-860f4a895aff" />

```
# Проверка, где PostgreSQL видит свои данные с нового диска
sudo -u postgres psql -c "SHOW data_directory;"

# Проверка, что данные действительно на внешнем диске
sudo ls -la /mnt/external_disk/postgresql/16/main/
```

<img width="500" height="100" alt="image" src="https://github.com/user-attachments/assets/0098f664-4c6b-4cf7-a939-ccf90c120459" />

<img width="500" height="500" alt="image" src="https://github.com/user-attachments/assets/5fcf8fa4-3c5b-462d-9c39-551e2fa6dbf4" />

Добавление новой записи также выполняется успешно:

<img width="600" height="200" alt="image" src="https://github.com/user-attachments/assets/f0027bc4-bfe9-4e06-adb8-13b275a9f94d" />

При переподключении работа осуществляется с новым диском, все данные доступны




