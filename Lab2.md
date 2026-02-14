# Установка и настройка PostgreSQL в контейнере Docker
## 1. Создание инстанса с Ubuntu 20.04 в Яндекс.Облаке
Создаем ВМ:
- Имя: bananaflow-docker
- ОС: Ubuntu 20.04 LTS
- vCPU: 2
- RAM: 2 ГБ
- Диск: 20 ГБ

<img width="400" height="400" alt="image" src="https://github.com/user-attachments/assets/af1a6bc0-a9d5-460a-882d-f11930146100" />
<img width="400" height="400" alt="image" src="https://github.com/user-attachments/assets/ceb4d126-5a7a-40fa-b416-6700c155997a" />
<img width="400" height="400" alt="image" src="https://github.com/user-attachments/assets/239385a5-8e83-4a71-8898-b9ae54d1c18f" />

Запущенная ВМ по адресу 51.250.89.152
<img width="1000" height="200" alt="image" src="https://github.com/user-attachments/assets/e103ab5a-9b8a-4eed-99a5-c9717bd27e8e" />

Подключение к ВМ по SSH:

<img width="400" height="500" alt="image" src="https://github.com/user-attachments/assets/6019ba2c-e421-4bfe-9117-0f1439a4a3bb" />

## 2. Установка Docker Engine
### 2.1 Обновляем список пакетов
- sudo apt update

### 2.2 Устанавливаем зависимости
Docker требует этих программ для установки. -y автоматически отвечает "да" на все вопросы
- sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

### 2.3 Добавляем официальный ключ Docker
Ключ подтверждает, что пакеты Docker настоящие, а не поддельные
- curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

### 2.4 Добавляем репозиторий Docker
Говорим, откуда скачивать Docker
- echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

### 2.5 Устанавливаем Docker
- sudo apt update
- sudo apt install docker-ce -y

<img width="800" height="800" alt="image" src="https://github.com/user-attachments/assets/abcee603-5230-47d5-99fd-92ba5b12ebcb" />

### 2.6 Проверяем, что Docker работает
- sudo systemctl status docker

<img width="1000" height="500" alt="image" src="https://github.com/user-attachments/assets/dbebd182-79df-4f7a-a966-045b3e6c351e" />

Получаем active (running) - все нормально

### 2.7 Добавляем себя в группу docker, чтобы не прописывать sudo в каждой команде
- sudo usermod -aG docker $USER

### 2.8 Проверяем, что Docker работает
Перезаходим в ВМ и проверяем список контейнеров - пока их нет
- docker ps

<img width="500" height="500" alt="image" src="https://github.com/user-attachments/assets/85531b40-bc57-4b6c-8bdd-1707efdc7a58" />

## 3. Создание каталога /var/lib/postgres для хранения данных
Создаем на ВМ папку, где будут храниться данные PostgreSQL
- sudo mkdir -p /var/lib/postgres

Даем права текущему пользователю
- sudo chown -R $USER:$USER /var/lib/postgres

<img width="500" height="100" alt="image" src="https://github.com/user-attachments/assets/940ff51c-ca16-444c-b644-aecaea47e992" />

## 4. Развертывание контейнера с PostgreSQL 14 с монтировкой /var/lib/postgres
Запускаем контейнер с PostgreSQL 14, монтируем папку с данными, открываем порт
```
docker run -d \
  --name pg-server \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=bananaflow \
  -e POSTGRES_USER=darya \
  -v /var/lib/postgres:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:14
```
  
<img width="1000" height="500" alt="image" src="https://github.com/user-attachments/assets/ffe07b57-ccba-4548-8934-c41fe19bb0eb" />

## 5. Развертывание контейнера с клиентом PostgreSQL
Запускаем второй контейнер, в котором будет только клиент PostgreSQL
- docker run -it --name pg-client postgres:14 bash

<img width="600" height="100" alt="image" src="https://github.com/user-attachments/assets/0543f67b-edb4-48ca-99d2-b61f5e1754a3" />

## 6. Подключение из контейнера с клиентом к контейнеру с сервером и создание таблицы с данными о перевозках
Чтобы контейнеры видели друг друга, создаем сеть и привязываем их к ней:
- docker network create banana-network
- docker network connect banana-network pg-server
- docker network connect banana-network pg-client

<img width="600" height="100" alt="image" src="https://github.com/user-attachments/assets/962ba43b-1491-41df-bcd3-1a4e697ce3eb" />

Заходим в контейнер-клиент, устанавливаем psql:
- apt update
- apt install postgresql-client -y

<img width="800" height="500" alt="image" src="https://github.com/user-attachments/assets/15b5ba1c-f52e-49c2-b9fe-945bee02b2a3" />

Подключаемся к серверу с БД:
- psql -h pg-server -U darya -d bananaflow

<img width="600" height="200" alt="image" src="https://github.com/user-attachments/assets/440af944-7819-43a9-b847-ac62e3c1360b" />

Создаем таблицу и наполняем ее данными:
```
create table shipments(id serial, product_name text, quantity int, destination text);
insert into shipments(product_name, quantity, destination) values('bananas', 1000, 'Europe');
insert into shipments(product_name, quantity, destination) values('bananas', 1500, 'Asia');
insert into shipments(product_name, quantity, destination) values('bananas', 2000, 'Africa');
insert into shipments(product_name, quantity, destination) values('coffee', 500, 'USA');
insert into shipments(product_name, quantity, destination) values('coffee', 700, 'Canada');
insert into shipments(product_name, quantity, destination) values('coffee', 300, 'Japan');
insert into shipments(product_name, quantity, destination) values('sugar', 1000, 'Europe');
insert into shipments(product_name, quantity, destination) values('sugar', 800, 'Asia');
insert into shipments(product_name, quantity, destination) values('sugar', 600, 'Africa');
insert into shipments(product_name, quantity, destination) values('sugar', 400, 'USA');
```

<img width="800" height="400" alt="image" src="https://github.com/user-attachments/assets/75053eb9-29ca-40ca-93e2-93337b329495" />

Проверяем данные:

<img width="300" height="400" alt="image" src="https://github.com/user-attachments/assets/680ae121-70cb-43e9-8b2a-cb7c5b7f95f4" />

## 7. Подключение к контейнеру с сервером с ноутбука
Подключаемся со своего устройства через dbeaver

<img width="600" height="600" alt="image" src="https://github.com/user-attachments/assets/f457ef67-2695-40ce-9817-237d565dc583" />

Проверка данных в таблице - все корректно

<img width="800" height="600" alt="image" src="https://github.com/user-attachments/assets/6c3c2ca4-a91a-4332-aadf-678901cd42bc" />

## 8. Удаление контейнера с сервером и создание его заново
Остановка контейнера:
- docker stop pg-server

Удаление контейнера:
- docker rm pg-server

Проверка, что контейнера больше нет:
- docker ps -a

<img width="800" height="100" alt="image" src="https://github.com/user-attachments/assets/a6d701f7-abe4-45c4-9a40-4c47d42b5900" />

Создаем аналогичный контейнер, монтируя ту же папку с данными:
```
docker run -d \
  --name pg-server \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=bananaflow \
  -e POSTGRES_USER=darya \
  -v /var/lib/postgres:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:14
```

## 9. Проверка, что данные остались на месте
Привязываем сервер к той же сети, подключаемся к нему из клиента и выводим данные из таблицы - все сохранилось
<img width="800" height="500" alt="image" src="https://github.com/user-attachments/assets/71db4da2-0ef0-4b69-848b-a24c42ee38ae" />

Дополнительно аналогично проверяем подключение со своего устройства - все так же доступно:
<img width="1000" height="400" alt="image" src="https://github.com/user-attachments/assets/aa662b1f-d429-48a8-bc50-d31292e7ff8a" />

