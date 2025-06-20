#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Путь к конфигурационному файлу
CONFIG_FILE="migration_config.conf"

# Функция для отображения заголовка
show_header() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    СКРИПТ МИГРАЦИИ ПРИЛОЖЕНИЙ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

# Функция для красивого вывода текущих параметров из конфига
show_config_summary() {
    if [ -f "$CONFIG_FILE" ]; then
        # Загружаем переменные из конфига во временную оболочку
        unset APP_SERVER_IP APP_SERVER_PORT APP_SERVER_USER APP_SERVER_PASSWORD APP_DIR SQL_SERVER_IP SQL_USER SQL_PASSWORD
        source "$CONFIG_FILE"
        echo -e "${YELLOW}Текущие параметры конфига:${NC}"
        echo "-----------------------------------------------"
        printf "| %-20s | %-22s |\n" "Параметр" "Значение"
        echo "-----------------------------------------------"
        printf "| %-20s | %-22s |\n" "APP_SERVER_IP"     "${APP_SERVER_IP:-не задано}"
        printf "| %-20s | %-22s |\n" "APP_SERVER_PORT"   "${APP_SERVER_PORT:-не задано}"
        printf "| %-20s | %-22s |\n" "APP_SERVER_USER"   "${APP_SERVER_USER:-не задано}"
        printf "| %-20s | %-22s |\n" "APP_SERVER_PASSWORD" "$( [ -n "$APP_SERVER_PASSWORD" ] && echo '****' || echo 'не задано' )"
        printf "| %-20s | %-22s |\n" "APP_DIR"           "${APP_DIR:-не задано}"
        printf "| %-20s | %-22s |\n" "SQL_SERVER_IP"     "${SQL_SERVER_IP:-не задано}"
        printf "| %-20s | %-22s |\n" "SQL_USER"          "${SQL_USER:-не задано}"
        printf "| %-20s | %-22s |\n" "SQL_PASSWORD"      "$( [ -n "$SQL_PASSWORD" ] && echo '****' || echo 'не задано' )"
        echo "-----------------------------------------------"
        echo
    fi
}

# Функция для отображения главного меню
show_main_menu() {
    show_header
    if [ -f "$CONFIG_FILE" ]; then
        show_config_summary
        echo -e "${RED}ВНИМАНИЕ: Файл конфигурации $CONFIG_FILE уже существует!${NC}"
        echo -e "${RED}Будьте внимательны: параметры подключения и базы будут браться из этого файла.${NC}"
    else
        echo -e "${GREEN}Файл конфигурации $CONFIG_FILE отсутствует.${NC}"
        echo -e "${GREEN}Перед началом работы настройте параметры подключения в меню 'Настройки подключения'.${NC}"
    fi
    echo -e "${GREEN}ГЛАВНОЕ МЕНЮ:${NC}"
    echo
    echo "1. Миграция приложения"
    echo "2. Миграция базы данных"
    echo "3. Подготовка к запуску"
    echo "4. Миграция сервиса"
    echo "5. Автоматическая миграция"
    echo -e "${YELLOW}6. Настройки подключения${NC}"
    echo "7. Выход"
    echo
    echo -n "Выберите пункт меню (1-7): "
}

# Функция для отображения подменю миграции приложения
show_app_migration_menu() {
    show_header
    echo -e "${GREEN}МИГРАЦИЯ ПРИЛОЖЕНИЯ:${NC}"
    echo
    echo "1. Базовый перенос приложения (без файлов проекта)"
    echo "2. Отдельный перенос файлов проекта"
    echo "3. Общий перенос приложения с файлами проекта (п.1 + п.2)"
    echo -e "${RED}4. Полный перенос приложения с файлами всех проектов (не рекомендуется)${NC}"
    echo "5. Вернуться в главное меню"
    echo
    echo -n "Выберите пункт меню (1-5): "
}

# Функция для отображения подменю миграции базы данных
show_db_migration_menu() {
    show_header
    echo -e "${GREEN}МИГРАЦИЯ БАЗЫ ДАННЫХ:${NC}"
    echo
    echo "1. Быстрый перенос базы данных (без таблицы event_store)"
    echo "2. Полный перенос базы данных"
    echo -e "${YELLOW}3. Быстрое снятие и передача бекапа (без таблицы event_store)${NC}"
    echo -e "${YELLOW}4. Полное снятие и передача бекапа${NC}"
    echo "5. Вернуться в главное меню"
    echo
    echo -n "Выберите пункт меню (1-5): "
}

# Функция для отображения подменю настроек
show_settings_menu() {
    show_header
    echo -e "${YELLOW}НАСТРОЙКИ ПОДКЛЮЧЕНИЯ:${NC}"
    echo
    echo "1. Параметры подключения к серверу приложений"
    echo "2. Параметры подключения к SQL серверу"
    echo "3. Тесты подключения"
    echo -e "${RED}4. Удалить файл конфигурации ($CONFIG_FILE)${NC}"
    echo "5. Вернуться в главное меню"
    echo
    echo -n "Выберите пункт меню (1-5): "
}

# Функция для отображения подменю тестов
show_tests_menu() {
    show_header
    echo -e "${YELLOW}ТЕСТЫ ПОДКЛЮЧЕНИЯ:${NC}"
    echo
    echo "1. Тест подключения и проверка прав (SSH)"
    echo "2. Тест подключения SQL и проверка прав"
    echo "3. Вернуться в меню настроек"
    echo
    echo -n "Выберите пункт меню (1-3): "
}

# Функция для чтения значения с дефолтом
read_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [ -n "$default" ]; then
        echo -n "$prompt [$default]: "
    else
        echo -n "$prompt: "
    fi
    
    read input
    if [ -z "$input" ]; then
        input="$default"
    fi
    
    # Сохраняем в переменную
    eval "$var_name=\"$input\""
}

# Функция для безопасного ввода пароля
read_password() {
    local prompt="$1"
    local var_name="$2"
    
    echo -n "$prompt: "
    read -s password
    echo
    eval "$var_name=\"$password\""
}

# Функция для проверки и установки зависимостей
check_and_install_dependencies() {
    echo "Проверка зависимостей..."
    
    # Проверяем sshpass
    if ! command -v sshpass &> /dev/null; then
        echo -e "${YELLOW}sshpass не установлен. Устанавливаем...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install sshpass
            else
                echo -e "${RED}Ошибка: Homebrew не установлен. Установите sshpass вручную: brew install sshpass${NC}"
                return 1
            fi
        elif command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            sudo apt-get update && sudo apt-get install -y sshpass
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            sudo yum install -y sshpass
        else
            echo -e "${RED}Ошибка: Не удалось определить пакетный менеджер. Установите sshpass вручную${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}sshpass уже установлен${NC}"
    fi
    
    # Проверяем psql
    if ! command -v psql &> /dev/null; then
        echo -e "${YELLOW}psql не установлен. Устанавливаем PostgreSQL client...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install postgresql
            else
                echo -e "${RED}Ошибка: Homebrew не установлен. Установите PostgreSQL client вручную: brew install postgresql${NC}"
                return 1
            fi
        elif command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            sudo apt-get update && sudo apt-get install -y postgresql-client
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            sudo yum install -y postgresql
        else
            echo -e "${RED}Ошибка: Не удалось определить пакетный менеджер. Установите PostgreSQL client вручную${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}psql уже установлен${NC}"
    fi
    
    echo -e "${GREEN}Все зависимости установлены${NC}"
    return 0
}

# Функция для настройки параметров сервера приложений
configure_app_server() {
    show_header
    echo -e "${YELLOW}ПАРАМЕТРЫ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ ПРИЛОЖЕНИЙ:${NC}"
    echo
    
    # Загружаем существующие значения из конфига
    source_config_if_exists
    
    read_with_default "Укажите IP адрес проектного сервера приложений" "$APP_SERVER_IP" "APP_SERVER_IP"
    read_with_default "Укажите SSH порт проектного сервера приложений" "${APP_SERVER_PORT:-22}" "APP_SERVER_PORT"
    read_with_default "Укажите имя пользователя проектного сервера приложений" "${APP_SERVER_USER:-root}" "APP_SERVER_USER"
    read_password "Укажите пароль пользователя проектного сервера приложений" "APP_SERVER_PASSWORD"
    read_with_default "Укажите директорию основного приложения" "${APP_DIR:-/home/platform5-server}" "APP_DIR"
    
    # Сохраняем в конфиг
    save_config
    echo
    echo -e "${GREEN}Параметры сервера приложений сохранены в: $CONFIG_FILE${NC}"
    echo
    pause
}

# Функция для настройки параметров SQL сервера
configure_sql_server() {
    show_header
    echo -e "${YELLOW}ПАРАМЕТРЫ ПОДКЛЮЧЕНИЯ К SQL СЕРВЕРУ:${NC}"
    echo
    
    # Загружаем существующие значения из конфига
    source_config_if_exists
    
    read_with_default "Укажите IP адрес проектного SQL сервера" "$SQL_SERVER_IP" "SQL_SERVER_IP"
    read_with_default "Укажите имя пользователя PostgreSQL" "${SQL_USER:-postgres}" "SQL_USER"
    read_password "Укажите пароль пользователя PostgreSQL" "SQL_PASSWORD"
    
    # Сохраняем в конфиг
    save_config
    echo
    echo -e "${GREEN}Параметры SQL сервера сохранены в: $CONFIG_FILE${NC}"
    echo
    pause
}

# Функция для загрузки конфига если он существует
source_config_if_exists() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

# Функция для сохранения конфига
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Конфигурация миграции
# Автоматически сгенерировано $(date)

# Параметры сервера приложений
APP_SERVER_IP="$APP_SERVER_IP"
APP_SERVER_PORT="$APP_SERVER_PORT"
APP_SERVER_USER="$APP_SERVER_USER"
APP_SERVER_PASSWORD="$APP_SERVER_PASSWORD"
APP_DIR="$APP_DIR"

# Параметры SQL сервера
SQL_SERVER_IP="$SQL_SERVER_IP"
SQL_USER="$SQL_USER"
SQL_PASSWORD="$SQL_PASSWORD"

# Переменные окружения для sshpass и psql
export SSHPASS="$APP_SERVER_PASSWORD"
export PGPASSWORD="$SQL_PASSWORD"
EOF
}

# Функция для теста SSH подключения
test_ssh_connection() {
    show_header
    echo -e "${YELLOW}ТЕСТ ПОДКЛЮЧЕНИЯ И ПРОВЕРКА ПРАВ (SSH):${NC}"
    echo
    
    # Проверяем и устанавливаем зависимости
    if ! check_and_install_dependencies; then
        echo
        pause
        return
    fi
    
    # Загружаем конфиг
    source_config_if_exists
    
    if [ -z "$APP_SERVER_IP" ] || [ -z "$APP_SERVER_USER" ] || [ -z "$APP_SERVER_PASSWORD" ]; then
        echo -e "${RED}Ошибка: Не все параметры SSH подключения настроены${NC}"
        echo "Пожалуйста, сначала настройте параметры подключения к серверу приложений"
        echo
        pause
        return
    fi
    
    echo "Выполняется тест подключения..."
    
    # Тест подключения
    if sshpass -p "$APP_SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "$APP_SERVER_PORT" "$APP_SERVER_USER@$APP_SERVER_IP" "echo 'SSH connection test successful'" 2>/dev/null; then
        echo -e "${GREEN}Соединение успешно${NC}"
        
        # Тест создания директории и файла
        echo "Проверка прав пользователя..."
        if sshpass -p "$APP_SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p "$APP_SERVER_PORT" "$APP_SERVER_USER@$APP_SERVER_IP" "
            mkdir -p /tmp/migration_test 2>/dev/null && 
            echo 'test content' > /tmp/migration_test/test_file.txt 2>/dev/null && 
            rm -rf /tmp/migration_test 2>/dev/null && 
            echo 'Permissions test successful'
        " 2>/dev/null; then
            echo -e "${GREEN}Права пользователя допустимы${NC}"
        else
            echo -e "${RED}Права пользователя не допустимы${NC}"
        fi
    else
        echo -e "${RED}Соединение не успешно${NC}"
    fi
    
    echo
    pause
}

# Функция для теста SQL подключения
test_sql_connection() {
    show_header
    echo -e "${YELLOW}ТЕСТ ПОДКЛЮЧЕНИЯ SQL И ПРОВЕРКА ПРАВ:${NC}"
    echo
    
    # Проверяем и устанавливаем зависимости
    if ! check_and_install_dependencies; then
        echo
        pause
        return
    fi
    
    # Загружаем конфиг
    source_config_if_exists
    
    if [ -z "$SQL_SERVER_IP" ] || [ -z "$SQL_USER" ] || [ -z "$SQL_PASSWORD" ]; then
        echo -e "${RED}Ошибка: Не все параметры SQL подключения настроены${NC}"
        echo "Пожалуйста, сначала настройте параметры подключения к SQL серверу"
        echo
        pause
        return
    fi
    
    echo "Выполняется тест подключения к PostgreSQL..."
    
    # Экспортируем пароль для psql
    export PGPASSWORD="$SQL_PASSWORD"
    
    # Тест подключения и создания базы
    if psql -h "$SQL_SERVER_IP" -U "$SQL_USER" -d postgres -c "CREATE DATABASE migration_test_db;" 2>/dev/null; then
        echo -e "${GREEN}Соединение с SQL сервером выполнено${NC}"
        # Удаляем тестовую базу
        psql -h "$SQL_SERVER_IP" -U "$SQL_USER" -d postgres -c "DROP DATABASE migration_test_db;" 2>/dev/null
    else
        echo -e "${RED}Соединение с SQL сервера не выполнено${NC}"
    fi
    
    echo
    pause
}

# Функция для базового переноса приложения
basic_app_migration() {
    show_header
    echo -e "${GREEN}БАЗОВЫЙ ПЕРЕНОС ПРИЛОЖЕНИЯ (БЕЗ ФАЙЛОВ ПРОЕКТА):${NC}"
    echo
    source_config_if_exists
    if [ -z "$APP_SERVER_IP" ] || [ -z "$APP_SERVER_USER" ] || [ -z "$APP_SERVER_PASSWORD" ]; then
        echo -e "${RED}Ошибка: Не все параметры SSH подключения настроены${NC}"
        echo "Пожалуйста, сначала настройте параметры подключения к серверу приложений"
        echo
        pause
        return
    fi
    read_with_default "Укажите путь к локальному приложению для переноса" "/home/platform5-server" "LOCAL_APP_PATH"
    if [ ! -d "$LOCAL_APP_PATH" ]; then
        echo -e "${RED}Ошибка: Директория '$LOCAL_APP_PATH' не существует${NC}"
        echo
        pause
        return
    fi
    echo
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}                ВНИМАНИЕ!${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}ПЕРЕНОС ПРИЛОЖЕНИЯ БУДЕТ ВЫПОЛНЕН${NC}"
    echo -e "${YELLOW}БЕЗ ФАЙЛОВ ПРОЕКТА!${NC}"
    echo
    echo -e "${YELLOW}НЕ ЗАБУДЬТЕ ПОТОМ ПЕРЕНЕСТИ ФАЙЛЫ ПРОЕКТА${NC}"
    echo -e "${YELLOW}ОТДЕЛЬНО!${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo
    echo -n "Вы уверены, что хотите продолжить? (y/N): "
    read confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Операция отменена."
        echo
        pause
        return
    fi
    echo
    echo "Начинаю базовый перенос приложения через rsync..."
    echo "Источник: $LOCAL_APP_PATH"
    echo "Назначение: $APP_SERVER_USER@$APP_SERVER_IP:$APP_DIR"
    echo
    if ! check_and_install_dependencies; then
        echo
        pause
        return
    fi
    # Проверка свободного места
    APP_SIZE=$(du -sk "$LOCAL_APP_PATH" | awk '{print $1}')
    FREE_SPACE=$(sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$APP_SERVER_PORT" "$APP_SERVER_USER@$APP_SERVER_IP" "df --output=avail -k $APP_DIR | tail -1")
    if [ "$FREE_SPACE" -lt "$APP_SIZE" ]; then
        echo -e "${RED}Недостаточно места на целевом сервере для передачи приложения!${NC}"
        pause
        return
    fi
    echo -e "${YELLOW}Передаю файлы приложения на сервер через rsync...${NC}"
    rsync -avz --progress -e "sshpass -p '$APP_SERVER_PASSWORD' ssh -o StrictHostKeyChecking=no -p $APP_SERVER_PORT" --exclude='bin/storage/1/evt*' "$LOCAL_APP_PATH/" "$APP_SERVER_USER@$APP_SERVER_IP:$APP_DIR/"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Файлы приложения успешно переданы на сервер${NC}"
    else
        echo -e "${RED}Ошибка при передаче файлов приложения через rsync${NC}"
        pause
        return
    fi
    echo
    pause
}

# Функция для переноса файлов проекта
project_files_migration() {
    show_header
    echo -e "${GREEN}ОТДЕЛЬНЫЙ ПЕРЕНОС ФАЙЛОВ ПРОЕКТА:${NC}"
    echo
    source_config_if_exists
    if [ -z "$APP_SERVER_IP" ] || [ -z "$APP_SERVER_USER" ] || [ -z "$APP_SERVER_PASSWORD" ]; then
        echo -e "${RED}Ошибка: Не все параметры SSH подключения настроены${NC}"
        echo "Пожалуйста, сначала настройте параметры подключения к серверу приложений"
        echo
        pause
        return
    fi
    read_with_default "Укажите путь к локальному приложению для переноса" "/home/platform5-server" "LOCAL_APP_PATH"
    if [ ! -d "$LOCAL_APP_PATH" ]; then
        echo -e "${RED}Ошибка: Директория '$LOCAL_APP_PATH' не существует${NC}"
        echo
        pause
        return
    fi
    echo -n "Укажите номер проекта (1/2/3...10...40 и т.д.): "
    read PROJECT_NUMBER
    if [ -z "$PROJECT_NUMBER" ] || ! [[ "$PROJECT_NUMBER" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Ошибка: Номер проекта не указан или не является числом${NC}"
        echo
        pause
        return
    fi
    PROJECT_DIR="$LOCAL_APP_PATH/bin/storage/1/evt$PROJECT_NUMBER"
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${RED}Ошибка: Директория проекта '$PROJECT_DIR' не существует${NC}"
        echo
        pause
        return
    fi
    echo
    echo -e "${YELLOW}Передаю файлы проекта evt$PROJECT_NUMBER на сервер через rsync...${NC}"
    rsync -avz --progress -e "sshpass -p '$APP_SERVER_PASSWORD' ssh -o StrictHostKeyChecking=no -p $APP_SERVER_PORT" "$PROJECT_DIR/" "$APP_SERVER_USER@$APP_SERVER_IP:$APP_DIR/bin/storage/1/evt$PROJECT_NUMBER/"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Файлы проекта успешно переданы на сервер${NC}"
    else
        echo -e "${RED}Ошибка при передаче файлов проекта через rsync${NC}"
        pause
        return
    fi
    echo
    pause
}

# Функция для общего переноса приложения
full_app_migration() {
    show_header
    echo -e "${GREEN}ОБЩИЙ ПЕРЕНОС ПРИЛОЖЕНИЯ С ФАЙЛАМИ ПРОЕКТА:${NC}"
    echo
    source_config_if_exists
    if [ -z "$APP_SERVER_IP" ] || [ -z "$APP_SERVER_USER" ] || [ -z "$APP_SERVER_PASSWORD" ]; then
        echo -e "${RED}Ошибка: Не все параметры SSH подключения настроены${NC}"
        echo "Пожалуйста, сначала настройте параметры подключения к серверу приложений"
        echo
        pause
        return
    fi
    if [ -z "$LOCAL_APP_PATH" ]; then
        read_with_default "Укажите путь к локальному приложению для переноса" "/home/platform5-server" "LOCAL_APP_PATH"
    fi
    if [ ! -d "$LOCAL_APP_PATH" ]; then
        echo -e "${RED}Ошибка: Директория '$LOCAL_APP_PATH' не существует${NC}"
        echo
        pause
        return
    fi
    if [ -z "$PROJECT_NUMBER" ]; then
        echo -n "Укажите номер проекта (1/2/3...10...40 и т.д.): "
        read PROJECT_NUMBER
        if [ -z "$PROJECT_NUMBER" ] || ! [[ "$PROJECT_NUMBER" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Ошибка: Номер проекта не указан или не является числом${NC}"
            echo
            pause
            return
        fi
    fi
    PROJECT_DIR="$LOCAL_APP_PATH/bin/storage/1/evt$PROJECT_NUMBER"
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${RED}Ошибка: Директория проекта '$PROJECT_DIR' не существует${NC}"
        echo
        pause
        return
    fi
    echo
    echo -e "${YELLOW}Передаю файлы приложения на сервер через rsync...${NC}"
    rsync -avz --progress -e "sshpass -p '$APP_SERVER_PASSWORD' ssh -o StrictHostKeyChecking=no -p $APP_SERVER_PORT" --exclude='bin/storage/1/evt*' "$LOCAL_APP_PATH/" "$APP_SERVER_USER@$APP_SERVER_IP:$APP_DIR/"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Файлы приложения успешно переданы на сервер${NC}"
    else
        echo -e "${RED}Ошибка при передаче файлов приложения через rsync${NC}"
        pause
        return
    fi
    echo -e "${YELLOW}Передаю файлы проекта evt$PROJECT_NUMBER на сервер через rsync...${NC}"
    rsync -avz --progress -e "sshpass -p '$APP_SERVER_PASSWORD' ssh -o StrictHostKeyChecking=no -p $APP_SERVER_PORT" "$PROJECT_DIR/" "$APP_SERVER_USER@$APP_SERVER_IP:$APP_DIR/bin/storage/1/evt$PROJECT_NUMBER/"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Файлы проекта успешно переданы на сервер${NC}"
    else
        echo -e "${RED}Ошибка при передаче файлов проекта через rsync${NC}"
        pause
        return
    fi
    echo
    pause
}

# Функция для полного переноса всех проектов
complete_migration() {
    show_header
    echo -e "${RED}ПОЛНЫЙ ПЕРЕНОС ПРИЛОЖЕНИЯ С ФАЙЛАМИ ВСЕХ ПРОЕКТОВ:${NC}"
    echo
    source_config_if_exists
    if [ -z "$APP_SERVER_IP" ] || [ -z "$APP_SERVER_USER" ] || [ -z "$APP_SERVER_PASSWORD" ]; then
        echo -e "${RED}Ошибка: Не все параметры SSH подключения настроены${NC}"
        echo "Пожалуйста, сначала настройте параметры подключения к серверу приложений"
        echo
        pause
        return
    fi
    if [ -z "$LOCAL_APP_PATH" ]; then
        read_with_default "Укажите путь к локальному приложению для переноса" "/home/platform5-server" "LOCAL_APP_PATH"
    fi
    if [ ! -d "$LOCAL_APP_PATH" ]; then
        echo -e "${RED}Ошибка: Директория '$LOCAL_APP_PATH' не существует${NC}"
        echo
        pause
        return
    fi
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}ЭТО ПЕРЕНОС ВСЕГО ПРИЛОЖЕНИЯ С ФАЙЛАМИ${NC}"
    echo -e "${RED}ВСЕХ ПРОЕКТОВ!${NC}"
    echo
    echo -e "${RED}ЭТО МОЖЕТ ЗАНЯТЬ ДЛИТЕЛЬНОЕ ВРЕМЯ!${NC}"
    echo -e "${RED}УБЕДИТЕСЬ, ЧТО У ВАС СТАБИЛЬНЫЙ ИНТЕРНЕТ!${NC}"
    echo -e "${RED}========================================${NC}"
    echo
    echo "Источник: $LOCAL_APP_PATH"
    echo "Назначение: $APP_SERVER_USER@$APP_SERVER_IP:$APP_DIR"
    echo "Включая ВСЕ проекты (evt1, evt2, evt3, ...)"
    echo
    echo -n "Вы уверены, что хотите продолжить полный перенос приложения и всех проектов? (y/N): "
    read confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Операция отменена."
        echo
        pause
        return
    fi
    if ! check_and_install_dependencies; then
        echo
        pause
        return
    fi
    echo -e "${YELLOW}Передаю все файлы приложения и проектов на сервер через rsync...${NC}"
    rsync -avz --progress -e "sshpass -p '$APP_SERVER_PASSWORD' ssh -o StrictHostKeyChecking=no -p $APP_SERVER_PORT" "$LOCAL_APP_PATH/" "$APP_SERVER_USER@$APP_SERVER_IP:$APP_DIR/"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Все файлы приложения и проектов успешно переданы на сервер${NC}"
    else
        echo -e "${RED}Ошибка при передаче файлов через rsync${NC}"
        pause
        return
    fi
    echo
    pause
}

# === Быстрый перенос базы данных (без таблицы event_store) ===
quick_db_migration() {
    source_config_if_exists
    SSH_PORT="$APP_SERVER_PORT"
    SSH_USER="$APP_SERVER_USER"
    SSH_HOST="$APP_SERVER_IP"
    REMOTE_PG_USER="$SQL_USER"
    REMOTE_PG_PASSWORD="$SQL_PASSWORD"
    echo -e "${CYAN}=== Быстрый перенос базы данных (без таблицы event_store) ===${NC}"
    # Явно запрашиваем все параметры
    read_with_default "Введите имя пользователя PostgreSQL (локально)" "postgres" "local_pg_user"
    read_password "Введите пароль для пользователя $local_pg_user (локально)" "local_pg_password"
    export PGPASSWORD="$local_pg_password"
    # Получаем список баз
    echo -e "\n${CYAN}Доступные базы данных:${NC}"
    databases=$(psql -U "$local_pg_user" -h localhost -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d' | grep -v 'template[0-9]')
    if [ $? -ne 0 ] || [ -z "$databases" ]; then
        echo -e "${RED}Ошибка при получении списка баз данных. Проверьте учетные данные.${NC}"
        pause
        return 1
    fi
    echo "$databases" | nl
    read -p "Введите номер базы данных для миграции: " db_number
    source_db=$(echo "$databases" | sed -n "${db_number}p")
    if [ -z "$source_db" ]; then
        echo -e "${RED}Ошибка: Неверный выбор базы данных${NC}"
        pause
        return 1
    fi
    read_with_default "Введите имя целевой базы данных на сервере" "$source_db" "target_db"
    if [ -z "$target_db" ]; then
        echo -e "${RED}Ошибка: Имя целевой базы данных не указано${NC}"
        pause
        return 1
    fi
    echo -e "\n${YELLOW}ВНИМАНИЕ!${NC} Будет перенесена база ${CYAN}$source_db${NC} в ${CYAN}$target_db${NC} (без таблицы event_store)"
    read -p "Продолжить? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Операция отменена."
        pause
        return
    fi
    # Проверяем подключение к удалённому серверу
    if ! sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "PGPASSWORD='$SQL_PASSWORD' psql -U $SQL_USER -lqt" > /dev/null 2>&1; then
        echo -e "${RED}Ошибка: Не удалось подключиться к удаленному PostgreSQL серверу${NC}"
        pause
        return 1
    fi
    # Проверяем наличие базы на сервере
    remote_check=$(sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "PGPASSWORD='$SQL_PASSWORD' psql -U $SQL_USER -lqt | cut -d \| -f1 | grep -w $target_db")
    if [ -z "$remote_check" ]; then
        echo -e "${YELLOW}База данных $target_db не существует. Будет создана новая база.${NC}"
        # Получение локалей через корректный SQL
        local_locale=$(psql -U "$local_pg_user" -d "$source_db" -t -c "SELECT setting FROM pg_settings WHERE name='lc_collate';" | xargs)
        local_ctype=$(psql -U "$local_pg_user" -d "$source_db" -t -c "SELECT setting FROM pg_settings WHERE name='lc_ctype';" | xargs)
        remote_locales=$(sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "locale -a")
        if ! echo "$remote_locales" | grep -q "$local_locale"; then
            if echo "$remote_locales" | grep -q "C.UTF-8"; then
                local_locale="C.UTF-8"
                local_ctype="C.UTF-8"
            elif echo "$remote_locales" | grep -q "en_US.UTF-8"; then
                local_locale="en_US.UTF-8"
                local_ctype="en_US.UTF-8"
            else
                local_locale=""
                local_ctype=""
            fi
        fi
        if [ -n "$local_locale" ] && [ -n "$local_ctype" ]; then
            create_db_cmd="CREATE DATABASE \"$target_db\" WITH OWNER = $SQL_USER ENCODING = 'UTF8' LC_COLLATE = '$local_locale' LC_CTYPE = '$local_ctype' TEMPLATE = template0;"
        else
            create_db_cmd="CREATE DATABASE \"$target_db\" WITH OWNER = $SQL_USER ENCODING = 'UTF8' TEMPLATE = template0;"
        fi
        if ! sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "PGPASSWORD='$SQL_PASSWORD' psql -U $SQL_USER -c \"$create_db_cmd\""; then
            echo -e "${RED}Ошибка: Не удалось создать базу данных${NC}"
            pause
            return 1
        fi
        echo -e "${GREEN}База данных успешно создана${NC}"
    else
        echo -e "${GREEN}База $target_db уже существует на проектном сервере${NC}"
    fi
    # Дамп и передача
    echo -e "${YELLOW}Создаю дамп базы (без event_store)...${NC}"
    pg_dump -U "$local_pg_user" -Fc "$source_db" --exclude-table=event_store --exclude-table=event_store_* -f db_backup.sql
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: Не удалось создать дамп${NC}"
        rm -f db_backup.sql
        pause
        return 1
    fi
    echo -e "${YELLOW}Передаю дамп на сервер...${NC}"
    rsync -avz --progress -e "sshpass -p '$APP_SERVER_PASSWORD' ssh -o StrictHostKeyChecking=no -p $SSH_PORT" db_backup.sql "$SSH_USER@$SSH_HOST:/tmp/db_backup.sql"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: Не удалось передать файл на сервер${NC}"
        rm -f db_backup.sql
        pause
        return 1
    fi
    rm -f db_backup.sql
    echo -e "${YELLOW}Восстанавливаю базу на сервере...${NC}"
    cpu_cores=$(sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "nproc")
    optimal_jobs=$(($cpu_cores / 2)); [ $optimal_jobs -lt 1 ] && optimal_jobs=1
    sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "PGPASSWORD='$SQL_PASSWORD' pg_restore -U $SQL_USER -d $target_db -j $optimal_jobs /tmp/db_backup.sql"
    sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "rm -f /tmp/db_backup.sql"
    echo -e "${GREEN}Быстрый перенос базы данных завершён!${NC}"
    pause
}

# === Полный перенос базы данных ===
full_db_migration() {
    source_config_if_exists
    SSH_PORT="$APP_SERVER_PORT"
    SSH_USER="$APP_SERVER_USER"
    SSH_HOST="$APP_SERVER_IP"
    REMOTE_PG_USER="$SQL_USER"
    REMOTE_PG_PASSWORD="$SQL_PASSWORD"
    echo -e "${CYAN}=== Полная миграция базы данных ===${NC}"
    read_with_default "Введите имя пользователя PostgreSQL (локально)" "postgres" "local_pg_user"
    read_password "Введите пароль для пользователя $local_pg_user (локально)" "local_pg_password"
    export PGPASSWORD="$local_pg_password"
    # Получаем список баз
    echo -e "\n${CYAN}Доступные базы данных:${NC}"
    databases=$(psql -U "$local_pg_user" -h localhost -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d' | grep -v 'template[0-9]')
    if [ $? -ne 0 ] || [ -z "$databases" ]; then
        echo -e "${RED}Ошибка при получении списка баз данных. Проверьте учетные данные.${NC}"
        pause
        return 1
    fi
    echo "$databases" | nl
    read -p "Введите номер базы данных для миграции: " db_number
    source_db=$(echo "$databases" | sed -n "${db_number}p")
    if [ -z "$source_db" ]; then
        echo -e "${RED}Ошибка: Неверный выбор базы данных${NC}"
        pause
        return 1
    fi
    read_with_default "Введите имя целевой базы данных на сервере" "$source_db" "target_db"
    if [ -z "$target_db" ]; then
        echo -e "${RED}Ошибка: Имя целевой базы данных не указано${NC}"
        pause
        return 1
    fi
    echo -e "\n${YELLOW}ВНИМАНИЕ!${NC} Будет перенесена база ${CYAN}$source_db${NC} в ${CYAN}$target_db${NC} (полный перенос)"
    read -p "Продолжить? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Операция отменена."
        pause
        return
    fi
    # Проверка валидности имени базы
    if [[ -z "$target_db" || "$target_db" =~ ^(true|false|yes|no)$ ]]; then
        echo -e "${RED}Ошибка: Имя целевой базы данных не указано или некорректно!${NC}"
        pause
        return 1
    fi
    # Проверяем подключение к удалённому серверу
    if ! sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "PGPASSWORD='$SQL_PASSWORD' psql -U $SQL_USER -lqt" > /dev/null 2>&1; then
        echo -e "${RED}Ошибка: Не удалось подключиться к удаленному PostgreSQL серверу${NC}"
        pause
        return 1
    fi
    # Проверяем наличие базы на сервере
    remote_check=$(sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "PGPASSWORD='$SQL_PASSWORD' psql -U $SQL_USER -lqt | cut -d \| -f1 | grep -w $target_db")
    if [ -z "$remote_check" ]; then
        echo -e "${YELLOW}База данных $target_db не существует. Будет создана новая база.${NC}"
        # Получение локалей через корректный SQL
        local_locale=$(psql -U "$local_pg_user" -d "$source_db" -t -c "SELECT setting FROM pg_settings WHERE name='lc_collate';" | xargs)
        local_ctype=$(psql -U "$local_pg_user" -d "$source_db" -t -c "SELECT setting FROM pg_settings WHERE name='lc_ctype';" | xargs)
        remote_locales=$(sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "locale -a")
        if ! echo "$remote_locales" | grep -q "$local_locale"; then
            if echo "$remote_locales" | grep -q "C.UTF-8"; then
                local_locale="C.UTF-8"
                local_ctype="C.UTF-8"
            elif echo "$remote_locales" | grep -q "en_US.UTF-8"; then
                local_locale="en_US.UTF-8"
                local_ctype="en_US.UTF-8"
            else
                local_locale=""
                local_ctype=""
            fi
        fi
        if [ -n "$local_locale" ] && [ -n "$local_ctype" ]; then
            create_db_cmd="CREATE DATABASE \"$target_db\" WITH OWNER = $SQL_USER ENCODING = 'UTF8' LC_COLLATE = '$local_locale' LC_CTYPE = '$local_ctype' TEMPLATE = template0;"
        else
            create_db_cmd="CREATE DATABASE \"$target_db\" WITH OWNER = $SQL_USER ENCODING = 'UTF8' TEMPLATE = template0;"
        fi
        if ! sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "PGPASSWORD='$SQL_PASSWORD' psql -U $SQL_USER -c \"$create_db_cmd\""; then
            echo -e "${RED}Ошибка: Не удалось создать базу данных${NC}"
            pause
            return 1
        fi
        echo -e "${GREEN}База данных успешно создана${NC}"
    else
        echo -e "${GREEN}База $target_db уже существует на проектном сервере${NC}"
    fi
    # Дамп и передача
    echo -e "${YELLOW}Создаю дамп базы...${NC}"
    pg_dump -U "$local_pg_user" -Fc "$source_db" -f db_backup.sql
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: Не удалось создать дамп${NC}"
        rm -f db_backup.sql
        pause
        return 1
    fi
    echo -e "${YELLOW}Передаю дамп на сервер...${NC}"
    rsync -avz --progress -e "sshpass -p '$APP_SERVER_PASSWORD' ssh -o StrictHostKeyChecking=no -p $SSH_PORT" db_backup.sql "$SSH_USER@$SSH_HOST:/tmp/db_backup.sql"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: Не удалось передать файл на сервер${NC}"
        rm -f db_backup.sql
        pause
        return 1
    fi
    rm -f db_backup.sql
    echo -e "${YELLOW}Восстанавливаю базу на сервере...${NC}"
    cpu_cores=$(sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "nproc")
    optimal_jobs=$(($cpu_cores / 2)); [ $optimal_jobs -lt 1 ] && optimal_jobs=1
    sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "PGPASSWORD='$SQL_PASSWORD' pg_restore -U $SQL_USER -d $target_db -j $optimal_jobs /tmp/db_backup.sql"
    sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "rm -f /tmp/db_backup.sql"
    echo -e "${GREEN}Полная миграция базы данных завершена!${NC}"
    pause
}

# Функция для быстрого снятия и передачи бекапа
quick_backup_transfer() {
    source_config_if_exists

    if [ -z "$APP_SERVER_PORT" ] || [ -z "$APP_SERVER_USER" ] || [ -z "$APP_SERVER_IP" ]; then
        echo -e "${RED}Ошибка: Не все параметры подключения настроены${NC}"
        echo -e "${YELLOW}Проверьте настройки подключения в меню настроек${NC}"
        pause
        return 1
    fi

    SSH_PORT="$APP_SERVER_PORT"
    SSH_USER="$APP_SERVER_USER"
    SSH_HOST="$APP_SERVER_IP"

    echo -e "${CYAN}=== Быстрое снятие и передача бекапа (без таблицы event_store) ===${NC}"
    echo -e "Шаг 1 из 3: Проверка учетных данных"
    read -p "Введите имя пользователя PostgreSQL [postgres]: " local_pg_user
    local_pg_user=${local_pg_user:-postgres}
    echo -n "Введите пароль для пользователя $local_pg_user: "
    read -s local_pg_password
    echo

    echo -e "\nШаг 2 из 3: Получение списка доступных баз данных..."
    export PGPASSWORD="$local_pg_password"
    databases=$(psql -U "$local_pg_user" -h localhost -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d' | grep -v 'template[0-9]')
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при получении списка баз данных. Проверьте учетные данные.${NC}"
        read -p "Нажмите Enter для возврата в меню..."
        return 1
    fi
    echo -e "\nДоступные базы данных:"
    echo "$databases" | nl
    read -p "Введите номер базы данных для бекапа: " db_number
    source_db=$(echo "$databases" | sed -n "${db_number}p")
    if [ -z "$source_db" ]; then
        echo -e "${RED}Ошибка: Неверный выбор базы данных${NC}"
        read -p "Нажмите Enter для возврата в меню..."
        return 1
    fi

    read -p "Введите путь для сохранения бекапа на проектном сервере (например, /tmp/db_backup.sql): " remote_backup_path
    if [ -z "$remote_backup_path" ]; then
        echo -e "${RED}Ошибка: Путь не указан${NC}"
        read -p "Нажмите Enter для возврата в меню..."
        return 1
    fi

    temp_local_backup="/tmp/db_backup_$$.sql"

    echo -e "\nШаг 3 из 3: Снятие бекапа базы данных (без таблицы event_store)..."
    pg_dump -U "$local_pg_user" -Fc "$source_db" \
        --exclude-table=event_store \
        --exclude-table=event_store_* \
        -f "$temp_local_backup"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: Не удалось создать бекап${NC}"
        rm -f "$temp_local_backup"
        read -p "Нажмите Enter для возврата в меню..."
        return 1
    fi
    echo -e "${GREEN}Бекап успешно создан: $temp_local_backup${NC}"

    echo -e "\nПередача бекапа на проектный сервер..."
    sshpass -p "$APP_SERVER_PASSWORD" scp -P "$SSH_PORT" "$temp_local_backup" "$SSH_USER@$SSH_HOST:$remote_backup_path"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: Не удалось передать файл на проектный сервер${NC}"
        rm -f "$temp_local_backup"
        read -p "Нажмите Enter для возврата в меню..."
        return 1
    fi
    echo -e "${GREEN}Файл успешно передан на проектный сервер: $remote_backup_path${NC}"
    rm -f "$temp_local_backup"
    read -p "Нажмите Enter для возврата в меню..."
}

# Функция для полного снятия и передачи бекапа
full_backup_transfer() {
    source_config_if_exists

    if [ -z "$APP_SERVER_PORT" ] || [ -z "$APP_SERVER_USER" ] || [ -z "$APP_SERVER_IP" ]; then
        echo -e "${RED}Ошибка: Не все параметры подключения настроены${NC}"
        echo -e "${YELLOW}Проверьте настройки подключения в меню настроек${NC}"
        pause
        return 1
    fi

    SSH_PORT="$APP_SERVER_PORT"
    SSH_USER="$APP_SERVER_USER"
    SSH_HOST="$APP_SERVER_IP"

    echo -e "${CYAN}=== Полное снятие и передача бекапа базы данных ===${NC}"
    echo -e "Шаг 1 из 3: Проверка учетных данных"
    read -p "Введите имя пользователя PostgreSQL [postgres]: " local_pg_user
    local_pg_user=${local_pg_user:-postgres}
    echo -n "Введите пароль для пользователя $local_pg_user: "
    read -s local_pg_password
    echo

    echo -e "\nШаг 2 из 3: Получение списка доступных баз данных..."
    export PGPASSWORD="$local_pg_password"
    databases=$(psql -U "$local_pg_user" -h localhost -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d' | grep -v 'template[0-9]')
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при получении списка баз данных. Проверьте учетные данные.${NC}"
        read -p "Нажмите Enter для возврата в меню..."
        return 1
    fi
    echo -e "\nДоступные базы данных:"
    echo "$databases" | nl
    read -p "Введите номер базы данных для бекапа: " db_number
    source_db=$(echo "$databases" | sed -n "${db_number}p")
    if [ -z "$source_db" ]; then
        echo -e "${RED}Ошибка: Неверный выбор базы данных${NC}"
        read -p "Нажмите Enter для возврата в меню..."
        return 1
    fi

    read -p "Введите путь для сохранения бекапа на проектном сервере (например, /tmp/db_backup.sql): " remote_backup_path
    if [ -z "$remote_backup_path" ]; then
        echo -e "${RED}Ошибка: Путь не указан${NC}"
        read -p "Нажмите Enter для возврата в меню..."
        return 1
    fi

    temp_local_backup="/tmp/db_backup_$$.sql"

    echo -e "\nШаг 3 из 3: Снятие полного бекапа базы данных..."
    pg_dump -U "$local_pg_user" -Fc "$source_db" -f "$temp_local_backup"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: Не удалось создать бекап${NC}"
        rm -f "$temp_local_backup"
        read -p "Нажмите Enter для возврата в меню..."
        return 1
    fi
    echo -e "${GREEN}Бекап успешно создан: $temp_local_backup${NC}"

    echo -e "\nПередача бекапа на проектный сервер..."
    sshpass -p "$APP_SERVER_PASSWORD" scp -P "$SSH_PORT" "$temp_local_backup" "$SSH_USER@$SSH_HOST:$remote_backup_path"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: Не удалось передать файл на проектный сервер${NC}"
        rm -f "$temp_local_backup"
        read -p "Нажмите Enter для возврата в меню..."
        return 1
    fi
    echo -e "${GREEN}Файл успешно передан на проектный сервер: $remote_backup_path${NC}"
    rm -f "$temp_local_backup"
    read -p "Нажмите Enter для возврата в меню..."
}

# Функция для обработки выбора в меню миграции базы данных
handle_db_migration_menu() {
    local choice
    read choice
    
    case $choice in
        1)
            quick_db_migration
            ;;
        2)
            full_db_migration
            ;;
        3)
            quick_backup_transfer
            ;;
        4)
            full_backup_transfer
            ;;
        5)
            DB_MENU_EXIT=1
            return
            ;;
        *)
            echo -e "${RED}Неверный выбор${NC}"
            read -p "Нажмите Enter для продолжения..."
            ;;
    esac
}

migrate_service() {
    source_config_if_exists
    if [ -z "$APP_SERVER_PORT" ] || [ -z "$APP_SERVER_USER" ] || [ -z "$APP_SERVER_IP" ] || [ -z "$APP_SERVER_PASSWORD" ]; then
        echo -e "${RED}Ошибка: Не все параметры подключения к серверу приложений настроены${NC}"
        pause
        return
    fi
    SSH_PORT="$APP_SERVER_PORT"
    SSH_USER="$APP_SERVER_USER"
    SSH_HOST="$APP_SERVER_IP"
    SERVICE_FILE="/etc/systemd/system/platform5.service"
    echo -e "${CYAN}Передача файла сервиса $SERVICE_FILE на проектный сервер...${NC}"
    sshpass -p "$APP_SERVER_PASSWORD" scp -P "$SSH_PORT" "$SERVICE_FILE" "$SSH_USER@$SSH_HOST:$SERVICE_FILE"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка передачи файла сервиса${NC}"
        pause
        return
    fi
    echo -e "${GREEN}Файл успешно передан. Выполняю systemctl daemon-reload, enable и start...${NC}"
    sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "sudo systemctl daemon-reload && sudo systemctl enable platform5.service && sudo systemctl start platform5.service"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при запуске сервиса на проектном сервере${NC}"
    else
        echo -e "${GREEN}Сервис успешно запущен и включен в автозагрузку!${NC}"
    fi
    pause
}

prepare_to_run() {
    source_config_if_exists
    if [ -z "$APP_SERVER_PORT" ] || [ -z "$APP_SERVER_USER" ] || [ -z "$APP_SERVER_IP" ] || [ -z "$APP_DIR" ] || [ -z "$APP_SERVER_PASSWORD" ]; then
        echo -e "${RED}Ошибка: Не все параметры подключения или путь к приложению настроены${NC}"
        pause
        return
    fi
    SSH_PORT="$APP_SERVER_PORT"
    SSH_USER="$APP_SERVER_USER"
    SSH_HOST="$APP_SERVER_IP"
    # Если параметры переданы — используем их, иначе спрашиваем
    if [ -n "$1" ]; then
        PROJECT_DB_NAME="$1"
    else
        read_with_default "Введите название проектной базы данных для подготовки приложения" "projectdb" "PROJECT_DB_NAME"
    fi
    if [ -n "$2" ]; then
        CONF_FILE_PATH="$2"
    else
        read_with_default "Введите путь к файлу конфигурации db.conf на проектном сервере" "/home/platform5-server/conf/db.conf" "CONF_FILE_PATH"
    fi
    echo -e "${CYAN}Делаю chmod +x $APP_DIR/bin/server на проектном сервере...${NC}"
    sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "chmod +x $APP_DIR/bin/server"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при выполнении chmod на проектном сервере${NC}"
    else
        echo -e "${GREEN}Права на запуск успешно установлены!${NC}"
    fi
    # Корректная замена имени базы в url
    echo -e "${CYAN}Обновляю имя базы данных в $CONF_FILE_PATH на проектном сервере...${NC}"
    sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "sed -i.bak 's|\(url = \"jdbc:postgresql://localhost:5432/\)[^?]*\(.*\)|\1$PROJECT_DB_NAME\2|' '$CONF_FILE_PATH'"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при обновлении конфигурационного файла${NC}"
    else
        echo -e "${GREEN}Имя базы данных в конфиге успешно обновлено!${NC}"
    fi
    pause
}

# === Автоматическая миграция через rsync ===
auto_migration() {
    source_config_if_exists
    if [ -z "$APP_SERVER_PORT" ] || [ -z "$APP_SERVER_USER" ] || [ -z "$APP_SERVER_IP" ] || [ -z "$APP_SERVER_PASSWORD" ] || [ -z "$APP_DIR" ] || [ -z "$SQL_PASSWORD" ] || [ -z "$SQL_USER" ]; then
        echo -e "${RED}Ошибка: Не все параметры подключения или путь к приложению настроены${NC}"
        pause
        return
    fi
    SSH_PORT="$APP_SERVER_PORT"
    SSH_USER="$APP_SERVER_USER"
    SSH_HOST="$APP_SERVER_IP"
    # Все вопросы в начале
    if [ -z "$LOCAL_APP_PATH" ]; then
        read_with_default "Укажите путь к локальному приложению для переноса" "/home/platform5-server" "LOCAL_APP_PATH"
    fi
    if [ ! -d "$LOCAL_APP_PATH" ]; then
        echo -e "${RED}Ошибка: Директория '$LOCAL_APP_PATH' не существует${NC}"
        pause
        return
    fi
    read_with_default "Укажите номера проектов evt для переноса (через запятую, например: 1,2,5) или оставьте пустым для переноса только приложения" "" "PROJECTS_LIST"
    echo -e "${YELLOW}Автоматическая миграция: будет выполнен перенос приложения, выбранных проектов и базы данных!${NC}"
    echo "Источник: $LOCAL_APP_PATH"
    echo "Назначение: $APP_SERVER_USER@$APP_SERVER_IP:$APP_DIR"
    # Перенос основного приложения (без evt*)
    echo -e "${YELLOW}Передаю файлы приложения (без evt*) на сервер через rsync...${NC}"
    rsync -avz --progress -e "sshpass -p '$APP_SERVER_PASSWORD' ssh -o StrictHostKeyChecking=no -p $APP_SERVER_PORT" --exclude='bin/storage/1/evt*' "$LOCAL_APP_PATH/" "$APP_SERVER_USER@$APP_SERVER_IP:$APP_DIR/"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Файлы приложения успешно переданы на сервер${NC}"
    else
        echo -e "${RED}Ошибка при передаче файлов приложения через rsync${NC}"
        return
    fi
    # Перенос выбранных проектов
    if [ -n "$PROJECTS_LIST" ]; then
        IFS=',' read -ra PROJECTS <<< "$PROJECTS_LIST"
        for PROJECT_NUMBER in "${PROJECTS[@]}"; do
            PROJECT_NUMBER=$(echo "$PROJECT_NUMBER" | xargs) # trim
            PROJECT_DIR="$LOCAL_APP_PATH/bin/storage/1/evt$PROJECT_NUMBER"
            if [ -d "$PROJECT_DIR" ]; then
                echo -e "${YELLOW}Передаю файлы проекта evt$PROJECT_NUMBER на сервер через rsync...${NC}"
                rsync -avz --progress -e "sshpass -p '$APP_SERVER_PASSWORD' ssh -o StrictHostKeyChecking=no -p $APP_SERVER_PORT" "$PROJECT_DIR/" "$APP_SERVER_USER@$APP_SERVER_IP:$APP_DIR/bin/storage/1/evt$PROJECT_NUMBER/"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}Файлы проекта evt$PROJECT_NUMBER успешно переданы на сервер${NC}"
                else
                    echo -e "${RED}Ошибка при передаче файлов проекта evt$PROJECT_NUMBER через rsync${NC}"
                fi
            else
                echo -e "${RED}Директория проекта '$PROJECT_DIR' не существует, пропуск...${NC}"
            fi
        done
    fi
    # Миграция базы данных (вызываем функцию миграции БД)
    full_db_migration
    # После миграции базы target_db должен быть определён
    PROJECT_DB_NAME="$target_db"
    CONF_FILE_PATH="/home/platform5-server/conf/db.conf"
    # Проверяем наличие файла на сервере
    sshpass -p "$APP_SERVER_PASSWORD" ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "test -f '$CONF_FILE_PATH'"
    if [ $? -ne 0 ]; then
        read_with_default "Файл $CONF_FILE_PATH не найден. Укажите корректный путь к конфигу на проектном сервере" "$CONF_FILE_PATH" "CONF_FILE_PATH"
    fi
    # Права на запуск и обновление конфига
    prepare_to_run "$PROJECT_DB_NAME" "$CONF_FILE_PATH"
    # Миграция systemd-сервиса
    migrate_service
    echo -e "${GREEN}Автоматическая миграция завершена!${NC}"
}

full_app_migration_auto() {
    LOCAL_APP_PATH="$1"
    PROJECT_NUMBER="$2"
    export LOCAL_APP_PATH PROJECT_NUMBER NO_PAUSE=1
    full_app_migration > /tmp/full_app_migration_auto.log 2>&1
}

full_db_migration_auto() {
    # $1 - local_pg_user, $2 - local_pg_password, $3 - source_db, $4 - target_db
    local_pg_user="$1"
    local_pg_password="$2"
    source_db="$3"
    target_db="$4"
    export local_pg_user local_pg_password source_db target_db NO_PAUSE=1
    full_db_migration 2>&1 | tee /tmp/full_db_migration_auto.log
}

# Функция для безопасной паузы (можно отключить через NO_PAUSE=1)
pause() {
    if [ -z "$NO_PAUSE" ]; then
        read -p "Нажмите Enter для возврата в меню..."
    fi
}

# Основной цикл программы
main() {
    while true; do
        show_main_menu
        read choice
        case $choice in
            1)
                app_migration_menu
                ;;
            2)
                db_migration_menu
                ;;
            3)
                prepare_to_run
                ;;
            4)
                migrate_service
                ;;
            5)
                auto_migration
                ;;
            6)
                settings_menu
                ;;
            7)
                echo -e "${GREEN}До свидания!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Неверный выбор. Попробуйте снова.${NC}"
                read -p "Нажмите Enter для продолжения..."
                ;;
        esac
    done
}

# Меню миграции приложения
app_migration_menu() {
    while true; do
        show_app_migration_menu
        read choice
        
        case $choice in
            1)
                basic_app_migration
                ;;
            2)
                project_files_migration
                ;;
            3)
                full_app_migration
                ;;
            4)
                complete_migration
                ;;
            5)
                return
                ;;
            *)
                echo -e "${RED}Неверный выбор. Попробуйте снова.${NC}"
                read -p "Нажмите Enter для продолжения..."
                ;;
        esac
    done
}

# Меню миграции базы данных
db_migration_menu() {
    while true; do
        show_db_migration_menu
        handle_db_migration_menu
        # Проверяем флаг возврата
        if [ "$DB_MENU_EXIT" = "1" ]; then
            unset DB_MENU_EXIT
            return
        fi
    done
}

# Меню настроек
settings_menu() {
    while true; do
        show_settings_menu
        read choice
        case $choice in
            1)
                configure_app_server
                ;;
            2)
                configure_sql_server
                ;;
            3)
                tests_menu
                ;;
            4)
                # Удаление конфига с подтверждением
                if [ -f "$CONFIG_FILE" ]; then
                    echo -e "${RED}ВНИМАНИЕ: Файл $CONFIG_FILE будет удалён!${NC}"
                    read -p "Вы уверены, что хотите удалить конфиг? (y/N): " confirm
                    if [[ $confirm =~ ^[Yy]$ ]]; then
                        rm -f "$CONFIG_FILE"
                        echo -e "${GREEN}Файл конфигурации удалён. Все настройки нужно будет ввести заново.${NC}"
                    else
                        echo -e "${YELLOW}Удаление отменено.${NC}"
                    fi
                else
                    echo -e "${GREEN}Файл конфигурации уже отсутствует.${NC}"
                fi
                pause
                ;;
            5)
                return
                ;;
            *)
                echo -e "${RED}Неверный выбор. Попробуйте снова.${NC}"
                read -p "Нажмите Enter для продолжения..."
                ;;
        esac
    done
}

# Меню тестов
tests_menu() {
    while true; do
        show_tests_menu
        read choice
        
        case $choice in
            1)
                test_ssh_connection
                ;;
            2)
                test_sql_connection
                ;;
            3)
                return
                ;;
            *)
                echo -e "${RED}Неверный выбор. Попробуйте снова.${NC}"
                read -p "Нажмите Enter для продолжения..."
                ;;
        esac
    done
}

# Запуск программы
main 
