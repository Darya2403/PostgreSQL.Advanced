Лабораторная 1 - Работа с уровнями изоляции транзакции в PostgreSQL
1. Создание проекта
   1.1 Генерируем ssh-ключ для подключения к ВМ
   - Был создан SSH-ключ
   - Публичный ключ добавлен при создании ВМ
   <img width="899" height="546" alt="image" src="https://github.com/user-attachments/assets/07328a7f-5f5c-4b64-a02a-c285ffb0de24" />

   1.2 Создаем ВМ
   Была создана виртуальная машина в Яндекс.Облаке со следующими параметрами:
   - Платформа: Яндекс.Облако
   - vCPU: 2 ядра
   - RAM: 4 ГБ
   - ОС: Ubuntu 22.04 LTS
   - Имя ВМ: bananaflow-20010324
   - Диск: 20 ГБ HDD
   <img width="1131" height="1168" alt="image" src="https://github.com/user-attachments/assets/578453bd-e7b8-44b1-882a-3d92f687f3cb" />
   <img width="1134" height="1037" alt="image" src="https://github.com/user-attachments/assets/ed1413bd-8248-44ae-9eba-89e9acf05a57" />
   <img width="1124" height="1092" alt="image" src="https://github.com/user-attachments/assets/84a44048-a385-4fef-8f1e-c3b133b5aba2" />

   Получаем активную ВМ:
   <img width="1674" height="393" alt="image" src="https://github.com/user-attachments/assets/8c51c57b-85b0-4a88-b62f-fd3fe8f95290" />
   Публичный адрес для подключения: 84.201.158.249

2. Подключение по SSH
   <img width="926" height="1016" alt="image" src="https://github.com/user-attachments/assets/97c99fea-9fec-4827-8ece-2c17a32d6363" />

3. Установка PostgreSQL
   Выполняем команды в 1-ой сессии для установки PostgreSQL:
   sudo apt update
   sudo apt install postgresql postgresql-contrib -y

   <img width="996" height="286" alt="image" src="https://github.com/user-attachments/assets/c21e517f-be36-4a13-84b4-301f1545c6ec" />
   <img width="1468" height="413" alt="image" src="https://github.com/user-attachments/assets/df7579c1-8ef5-42e0-b5fc-45f622025660" />

   Проверяем активность, статус SUCCESS
   sudo systemctl status postgresql
   <img width="1139" height="251" alt="image" src="https://github.com/user-attachments/assets/101a54b6-c727-49c5-b768-e21acb231c6d" />

4. Подключение к PostgreSQL
   Подключаем вторую SSH-сессию через команду:
   sudo -u postgres psql
   <img width="820" height="844" alt="image" src="https://github.com/user-attachments/assets/854befd9-d454-4560-b531-e0c1733516b3" />

5. Работа с транзакциями
   Выключаем автоматический коммит в обеих сессиях:
   \set AUTOCOMMIT off
   <img width="625" height="132" alt="image" src="https://github.com/user-attachments/assets/123fd615-6cca-474f-a9d4-61a5becf9b21" />

   В 1 сессии создаем таблицу и наполняем ее данными:
   create table shipments(id serial, product_name text, quantity int, destination text);
   insert into shipments(product_name, quantity, destination) values('bananas', 1000, 'Europe');
   insert into shipments(product_name, quantity, destination) values('coffee', 500, 'USA');
   commit;
   
   <img width="1074" height="312" alt="image" src="https://github.com/user-attachments/assets/beb66238-d07d-4778-8264-31ff62c06d53" />
   Проверим созданную таблицу:
   select * from shipments;
   <img width="549" height="161" alt="image" src="https://github.com/user-attachments/assets/c68d4e78-6a6d-4580-8764-548e12b1a803" />

6. Изучение уровней изоляции
   <img width="556" height="129" alt="image" src="https://github.com/user-attachments/assets/6d51ddb7-c54c-4a5e-b011-34c637b51d9a" />
   Текущий уровень изоляции: read commited

   1 сессия:
   Добавилась 3 строка без коммита
   <img width="1087" height="251" alt="image" src="https://github.com/user-attachments/assets/bb619a66-f338-48a7-a84c-cf03f5141e98" />

   2 сессия:
   Изменений нет, новая строка не добавилась
   <img width="622" height="239" alt="image" src="https://github.com/user-attachments/assets/3a9b552b-516c-4586-a91b-013e5f7d7418" />
   Результат: 3 запись НЕ ВИДНА
   Объяснение: уровень изоляции read committed защищает от dirty read. Сессия 2 видит только те данные, которые уже закоммичены. Так как вставка в сессии 1 еще не закоммичена, она не видна другим транзакциям.

   После commit в 1 сессии и повторного селекта во 2 сессии данные обновились, 3 строка появилась
   <img width="546" height="180" alt="image" src="https://github.com/user-attachments/assets/4b7137e0-c2f4-416c-8a88-114e460ff304" />
   Результат: 3 запись ВИДНА
   Объяснение: после выполнения COMMIT данные стали зафиксированы. Новый запрос в сессии 2 видит все закоммиченные изменения.

7. Эксперименты с уровнем изоляции Repeatable Read
   Начинаем новые транзакции в обеих сессиях с уровнем изоляции repeatable read
   <img width="751" height="136" alt="image" src="https://github.com/user-attachments/assets/96ce0c51-2a0b-4ead-acec-4eadc68a4f62" />

   В 1 сессии добавляем новую строку без коммита, во 2 сессии читаем данные
   Результат: Запись НЕ ВИДНА
   Объяснение: на уровне repeatable read транзакция видит снимок данных на момент своего первого запроса. Она не видит изменений, сделанных в других транзакциях, даже если они еще не закоммичены.

   Завершаем транзакцию в сессии 1 и снова выполняем select * from shipments в сессии 2
   Результат: Запись НЕ ВИДНА
   Объяснение: транзакция в Сессии 2 продолжает работать со старым снимком данных, который был сделан в начале транзакции. Даже после того, как сессия 1 закоммитила изменения, для текущей транзакции сессии 2 мир выглядит так же, как и в момент ее старта. Это и обеспечивает repeatable read.

   Завершаем транзакцию в сессии 2 и снова выполняем select * from shipments
   Результат: Запись ВИДНА
   Объяснение: транзакция завершилась, старый снимок данных уничтожен. Новый SELECT создает новый снимок, который уже включает все закоммиченные изменения.

   1 сессия
   <img width="1050" height="231" alt="image" src="https://github.com/user-attachments/assets/cef0d271-2334-4bbd-938d-03a9198ef77a" />

   2 сессия
   <img width="562" height="649" alt="image" src="https://github.com/user-attachments/assets/5992d7d3-dfaa-4b18-88c0-bd7248d4c136" />

Итоговые результаты:
READ COMMITTED (уровень по умолчанию в PostgreSQL):
- Защищает от "грязного" чтения (dirty read) — нельзя увидеть незакоммиченные данные других транзакций
- После фиксации изменений в другой транзакции новые данные сразу становятся видны

REPEATABLE READ:
- Защищает от "грязного" чтения и от неповторяющегося чтения
- В PostgreSQL также защищает от фантомного чтения
- Гарантирует, что внутри одной транзакции данные всегда выглядят одинаково


   



   








   



   




