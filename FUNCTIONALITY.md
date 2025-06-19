# Документация по функционалу скрипта миграции

---

## Важно о логах

- **Централизованного лога (например, migration.log) нет.**
- Весь вывод (ошибки, прогресс, действия) отображается только в терминале.
- В автоматических режимах (например, автоматическая миграция) вывод может сохраняться во временные файлы:
  - `/tmp/full_app_migration_auto.log`
  - `/tmp/full_db_migration_auto.log`
- В ручных режимах логи не сохраняются.
- Если нужно сохранить всё, запускайте скрипт так:
  ```bash
  bash migration_script.sh 2>&1 | tee migration.log
  ```
  Тогда весь вывод будет и на экране, и в файле `migration.log` (создаётся вручную, если нужно).

---

## Главное меню и все подпункты (подробно)

### 1. Миграция приложения
  - Открывает подменю:
    1. **Базовый перенос приложения (без файлов проекта)**
       - Переносит только основное приложение, без директорий evt*.
       - Команда: `rsync -avz --progress --exclude='bin/storage/1/evt*' ...`
       - Ошибки: Permission denied, Connection refused, Недостаточно места.
    2. **Отдельный перенос файлов проекта**
       - Переносит только выбранный проект evtN.
       - Запрашивает номер проекта, переносит только его.
       - Команда: `rsync -avz --progress ... evtN/ ...`
       - Ошибки: Директория не найдена, Permission denied.
    3. **Общий перенос приложения с файлами проекта (п.1 + п.2)**
       - Сначала базовый перенос, затем выбранные проекты.
       - Команды: обе выше.
    4. **Полный перенос приложения с файлами всех проектов**
       - Переносит всё приложение и все evt* проекты.
       - Команда: `rsync -avz --progress ...`
       - Может быть очень долгим!
    5. **Вернуться в главное меню**

### 2. Миграция базы данных
  - Открывает подменю:
    1. **Быстрый перенос базы данных (без event_store)**
       - pg_dump с исключением event_store, rsync на сервер, pg_restore.
       - Команды: `pg_dump ... --exclude-table=event_store*`, `rsync ...`, `pg_restore ...`
       - Ошибки: FATAL, Ошибка аутентификации, Ошибка локалей.
    2. **Полный перенос базы данных**
       - pg_dump всего, rsync, pg_restore.
       - Команды: `pg_dump ...`, `rsync ...`, `pg_restore ...`
    3. **Быстрое снятие и передача бекапа (без event_store)**
       - Только создание и передача дампа, без восстановления.
       - Команды: `pg_dump ... --exclude-table=event_store*`, `scp ...`
    4. **Полное снятие и передача бекапа**
       - То же, но полный дамп.
       - Команды: `pg_dump ...`, `scp ...`
    5. **Вернуться в главное меню**

### 3. Подготовка к запуску
  - Устанавливает права на запуск (`chmod +x`), обновляет имя базы в конфиге через sed на сервере.
  - Команды: `chmod +x ...`, `sed -i ...`
  - Ошибки: Permission denied, файл не найден.

### 4. Миграция сервиса
  - Передаёт systemd unit-файл, выполняет `systemctl daemon-reload`, `enable`, `start` на сервере.
  - Команды: `scp ...`, `systemctl ...`
  - Ошибки: Ошибка прав, unit not found.

### 5. Автоматическая миграция
  - Запрашивает все параметры в начале, затем:
    - Переносит приложение (без evt*).
    - Переносит выбранные проекты evt*.
    - Мигрирует базу (полный перенос).
    - Обновляет конфиг и права.
    - Мигрирует systemd unit.
  - Весь вывод можно найти только в терминале, либо если запускать с перенаправлением в файл, либо во временных логах `/tmp/full_app_migration_auto.log`, `/tmp/full_db_migration_auto.log`.

### 6. Настройки подключения
  - Меню для ввода/изменения параметров подключения, путей, пользователей, паролей.
  - Всё сохраняется в файл `migration_config.conf`.

### 7. Выход

---

## Как мониторить и разбираться с ошибками
- В интерактивном режиме — внимательно читать цветной вывод, ошибки всегда выделяются красным.
- В автоматическом режиме — смотреть временные логи в `/tmp/` (если запускалась автоматизация).
- Если запускали с перенаправлением — смотреть файл лога, если вы его создали вручную через tee.
- Для диагностики — вручную запускать команды ssh, rsync, psql, systemctl с теми же параметрами.

---

# Functionality Documentation (English)

---

## Important about logs

- **There is no centralized log file (like migration.log).**
- All output (errors, progress, actions) is shown only in the terminal.
- In automatic modes, output may be saved to temporary files:
  - `/tmp/full_app_migration_auto.log`
  - `/tmp/full_db_migration_auto.log`
- In manual modes, logs are not saved.
- If you want to save everything, run the script as:
  ```bash
  bash migration_script.sh 2>&1 | tee migration.log
  ```
  Then all output will be both on the screen and in the `migration.log` file (created manually if needed).

---

## Main menu and all subitems (detailed)

### 1. Application migration
  - Opens submenu:
    1. **Basic application transfer (without project files)**
       - Transfers only the main app, without evt* directories.
       - Command: `rsync -avz --progress --exclude='bin/storage/1/evt*' ...`
       - Errors: Permission denied, Connection refused, Not enough space.
    2. **Separate project files transfer**
       - Transfers only the selected evtN project.
       - Asks for project number, transfers only it.
       - Command: `rsync -avz --progress ... evtN/ ...`
       - Errors: Directory not found, Permission denied.
    3. **Combined transfer (basic + selected projects)**
       - First basic transfer, then selected projects.
       - Commands: both above.
    4. **Full transfer with all projects**
       - Transfers the whole app and all evt* projects.
       - Command: `rsync -avz --progress ...`
       - Can be very long!
    5. **Return to main menu**

### 2. Database migration
  - Opens submenu:
    1. **Quick DB migration (without event_store)**
       - pg_dump excluding event_store, rsync to server, pg_restore.
       - Commands: `pg_dump ... --exclude-table=event_store*`, `rsync ...`, `pg_restore ...`
       - Errors: FATAL, Authentication error, Locale error.
    2. **Full DB migration**
       - pg_dump all, rsync, pg_restore.
       - Commands: `pg_dump ...`, `rsync ...`, `pg_restore ...`
    3. **Quick backup and transfer (without event_store)**
       - Only creates and transfers dump, no restore.
       - Commands: `pg_dump ... --exclude-table=event_store*`, `scp ...`
    4. **Full backup and transfer**
       - Same, but full dump.
       - Commands: `pg_dump ...`, `scp ...`
    5. **Return to main menu**

### 3. Prepare to run
  - Sets execute permissions (`chmod +x`), updates DB name in config via sed on server.
  - Commands: `chmod +x ...`, `sed -i ...`
  - Errors: Permission denied, file not found.

### 4. Service migration
  - Transfers systemd unit file, runs `systemctl daemon-reload`, `enable`, `start` on server.
  - Commands: `scp ...`, `systemctl ...`
  - Errors: Permission error, unit not found.

### 5. Automatic migration
  - Asks all parameters at start, then:
    - Transfers app (without evt*).
    - Transfers selected evt* projects.
    - Migrates DB (full).
    - Updates config and permissions.
    - Migrates systemd unit.
  - All output is only in terminal, or in temp logs `/tmp/full_app_migration_auto.log`, `/tmp/full_db_migration_auto.log` if automation was used.

### 6. Connection settings
  - Menu for entering/changing connection params, paths, users, passwords.
  - All saved in `migration_config.conf`.

### 7. Exit

---

## How to monitor and troubleshoot
- In interactive mode — read colored output, errors are always red.
- In automatic mode — check temp logs in `/tmp/` (if automation was used).
- If run with redirection — check the log file, if you created it manually via tee.
- For diagnostics — manually run ssh, rsync, psql, systemctl with the same params.

---

## Общий обзор

Скрипт предназначен для миграции приложений и баз данных между серверами. Поддерживает интерактивный и автоматический режимы, подробное логирование, гибкую настройку и работу с несколькими проектами.

---

## Основные разделы меню и их функции

### 1. Миграция приложения ("Миграция приложения")
- **Что делает:**
  - Переносит выбранный проект (или несколько) с исходного сервера на целевой.
  - Использует `rsync` для передачи файлов напрямую, без архивирования.
  - Сохраняет структуру директорий, права, симлинки и владельцев.
- **Выполняемые команды:**
  - `rsync -avz --progress --delete -e "sshpass -p $SRC_PASS ssh -o StrictHostKeyChecking=no" $SRC_USER@$SRC_HOST:/path/to/project/ /local/target/path/`
- **Фоновые процессы:**
  - Нет, все операции выполняются последовательно.
- **Мониторинг:**
  - Прогресс передачи виден в реальном времени через `--progress`.
  - Все действия логируются в файл (например, `migration.log`).
- **Возможные ошибки:**
  - Ошибка подключения по SSH (неверный пароль, недоступен сервер).
  - Недостаточно прав на чтение/запись.
  - Проблемы с сетью.
- **Решение проблем:**
  - Проверить лог-файл.
  - Проверить параметры подключения и права доступа.
  - Использовать `ssh` вручную для диагностики.

### 2. Миграция базы данных ("Миграция базы данных")
- **Что делает:**
  - Переносит выбранную базу PostgreSQL с исходного на целевой сервер.
  - Поддерживает быстрый и полный перенос (с локалями, ролями, схемой и данными).
- **Выполняемые команды:**
  - Экспорт: `pg_dump -U $SRC_DB_USER -h $SRC_DB_HOST $SRC_DB_NAME > dump.sql`
  - Передача: `rsync -avz -e "sshpass ..." dump.sql $DST_USER@$DST_HOST:/tmp/`
  - Импорт: `psql -U $DST_DB_USER -h $DST_DB_HOST -d $DST_DB_NAME < /tmp/dump.sql`
  - Создание базы: `psql ... -c "CREATE DATABASE ... WITH ..."`
- **Фоновые процессы:**
  - Нет, все операции последовательны.
- **Мониторинг:**
  - Вывод команд `pg_dump` и `psql` отображается в терминале и логируется.
- **Возможные ошибки:**
  - Ошибка аутентификации PostgreSQL.
  - Конфликт локалей или кодировок.
  - Недостаточно прав на создание базы.
- **Решение проблем:**
  - Проверить лог-файл и сообщения об ошибках.
  - Проверить параметры подключения и права пользователя.
  - Проверить локали командой `psql -c "SHOW lc_collate;"`.

### 3. Миграция прав и systemd ("Миграция прав и systemd")
- **Что делает:**
  - Переносит файлы systemd, права и владельцев для корректного запуска сервисов.
  - Может копировать unit-файлы, настраивать автозапуск.
- **Выполняемые команды:**
  - `rsync` для передачи unit-файлов.
  - `systemctl daemon-reload`
  - `systemctl enable/disable/start/stop <service>`
- **Фоновые процессы:**
  - Нет.
- **Мониторинг:**
  - Проверять статус сервисов: `systemctl status <service>`
- **Возможные ошибки:**
  - Ошибки прав, отсутствует unit-файл, неверные пути.
- **Решение проблем:**
  - Проверить логи systemd: `journalctl -u <service>`
  - Проверить права и владельцев файлов.

### 4. Автоматическая миграция ("Автоматическая миграция")
- **Что делает:**
  - Последовательно выполняет все этапы: перенос приложения, базы, прав и systemd.
  - Все параметры (пути, проекты, имя базы, путь к конфигу) запрашиваются в начале.
  - Весь процесс проходит без пауз и подтверждений.
- **Выполняемые команды:**
  - Все вышеописанные команды в автоматическом режиме.
- **Фоновые процессы:**
  - Нет, но процесс полностью автоматизирован.
- **Мониторинг:**
  - Весь вывод и ошибки пишутся в лог-файл.
- **Возможные ошибки:**
  - Любые из описанных выше.
- **Решение проблем:**
  - Анализировать лог-файл, повторить этап вручную при необходимости.

### 5. Настройки ("Настройки")
- **Что делает:**
  - Позволяет задать и изменить параметры подключения, пути, пользователей, пароли.
  - Сохраняет параметры в конфиг-файл.
- **Выполняемые команды:**
  - Чтение/запись в конфиг-файл через `read`, `echo`, `sed`.
- **Мониторинг:**
  - Проверить содержимое конфига: `cat config.cfg`
- **Возможные ошибки:**
  - Ошибка записи (нет прав), повреждённый конфиг.
- **Решение проблем:**
  - Удалить или исправить конфиг вручную.

### 6. Удаление конфига ("Удалить конфиг")
- **Что делает:**
  - Удаляет конфиг-файл после подтверждения.
- **Выполняемые команды:**
  - `rm -f config.cfg`
- **Мониторинг:**
  - Проверить наличие файла: `ls -l config.cfg`
- **Возможные ошибки:**
  - Нет прав на удаление.
- **Решение проблем:**
  - Удалить вручную с правами root.

---

## Логирование и мониторинг
- Все ключевые действия и ошибки пишутся в лог-файл (например, `migration.log`).
- Для просмотра лога используйте:
  ```bash
  tail -f migration.log
  less migration.log
  grep ERROR migration.log
  ```
- В автоматическом режиме лог особенно важен для диагностики.

---

## Типовые ошибки и их устранение

| Ошибка | Причина | Решение |
|--------|---------|---------|
| Permission denied | Неверные права, пользователь | Проверить права, запускать от root |
| Connection refused | Сервер недоступен, firewall | Проверить сеть, firewall, sshd |
| FATAL: database ... does not exist | Ошибка имени базы | Проверить имя, создать базу вручную |
| rsync: command not found | Не установлен rsync | Установить rsync на обеих машинах |
| psql: FATAL | Ошибка аутентификации | Проверить пользователя/пароль |

---

## Советы по мониторингу и отладке
- Используйте `ssh` и `rsync` вручную для диагностики проблем с сетью.
- Проверяйте логи PostgreSQL (`/var/log/postgresql/`), systemd (`journalctl`).
- Для сложных случаев запускайте скрипт с `set -x` для трассировки:
  ```bash
  bash -x migration_script.sh
  ```
- Для проверки переменных окружения используйте `env`.

---

## FAQ

**Q: Можно ли мигрировать только базу или только приложение?**
A: Да, выберите соответствующий пункт меню.

**Q: Как добавить новый проект для миграции?**
A: Укажите путь к проекту в настройках.

**Q: Как восстановить конфиг?**
A: Перезапустите скрипт и заново заполните настройки.

---

Если остались вопросы — создайте issue на GitHub или обратитесь к владельцу репозитория. 
