# Migration Script — Files and Database

---

## ⚠️ Requirements / Требования

Before using this script, make sure the following packages are installed on your system:

**Required packages:**
- `git` — for cloning the repository
- `sshpass` — for non-interactive SSH/SCP
- `rsync` — for reliable file transfer

### How to install dependencies (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install git sshpass rsync
```

### Как установить зависимости (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install git sshpass rsync
```

---

## 🇬🇧 Installation and Usage (English)

1. **Go to the start directory (for example, /root):**
   ```bash
   cd /root
   ```
2. **Clone the repository:**
   ```bash
   git clone https://github.com/zaycevmain/migration.git
   cd migration
   ```
3. **Add execute permission for the script:**
   ```bash
   chmod +x migration_script.sh
   ```
4. **Run the script:**
   ```bash
   bash migration_script.sh
   ```

5. **Follow the interactive menu:**
   - Set up connection parameters in the menu "Settings" if running for the first time.
   - Use the migration options as needed (application, database, full migration, etc).

**Note:**
- The script will warn you if the configuration file already exists.
- All actions are logged and require confirmation for critical operations.
- For automatic migration, all required parameters will be requested at the beginning.

---

## 🇷🇺 Установка и использование (Russian)

1. **Перейдите в рабочую директорию (например, /root):**
   ```bash
   cd /root
   ```
2. **Склонируйте репозиторий:**
   ```bash
   git clone https://github.com/zaycevmain/migration.git
   cd migration
   ```
3. **Дайте права на выполнение скрипта:**
   ```bash
   chmod +x migration_script.sh
   ```
4. **Запустите скрипт:**
   ```bash
   bash migration_script.sh
   ```

5. **Следуйте интерактивному меню:**
   - При первом запуске настройте параметры подключения в меню "Настройки".
   - Используйте нужные пункты меню для миграции приложения, базы данных, автоматической миграции и т.д.

**Примечания:**
- Скрипт предупредит, если файл конфигурации уже существует.
- Все действия логируются, для критичных операций требуется подтверждение.
- В автоматической миграции все параметры будут запрошены в начале.

---

**If you have any questions or issues, please create an issue on GitHub or contact the repository maintainer.**

**Если возникли вопросы или проблемы — создайте issue на GitHub или свяжитесь с владельцем репозитория.** 
