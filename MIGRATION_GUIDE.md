# MIGRATION GUIDE: АРХИВ МЕНТОРСТВА НА PRODUCTION СЕРВЕР

**Версия:** 1.0  
**Дата:** 2026-05-09  
**Статус:** ✅ ГОТОВО К МИГРАЦИИ  
**Целевой сервер:** 46.8.255.137 (Moscow, Russia)

---

## 📋 СОДЕРЖАНИЕ

1. [Обзор системы](#обзор-системы)
2. [Подготовка к миграции](#подготовка-к-миграции)
3. [Развертывание на production](#развертывание-на-production)
4. [Конфигурация окружения](#конфигурация-окружения)
5. [Загрузка данных](#загрузка-данных)
6. [Тестирование](#тестирование)
7. [Мониторинг и поддержка](#мониторинг-и-поддержка)

---

## 🏗️ ОБЗОР СИСТЕМЫ

### Архитектура

Система индексирования архивов состоит из трёх основных компонентов:

**Слой 1: Парсер (Python)**
- Входные данные: ZIP архив с TXT файлами
- Выходные данные: JSON с 805 чанками
- Обработка: Разбиение текста на чанки (50 слов, 30 сек, 300 символов)
- Файл: `/home/ubuntu/process_archive.py`

**Слой 2: Сервис индексирования (TypeScript/Node.js)**
- Входные данные: JSON с чанками
- Выходные данные: Векторы в Qdrant + метаданные в MySQL
- Обработка: Генерация эмбеддингов, загрузка в БД
- Файлы: `server/services/archiveIndexingService.ts`, `server/routers/archiveIndexing.ts`

**Слой 3: Хранилище данных**
- Qdrant: Вектор-БД для семантического поиска (3072-мерные векторы, text-embedding-3-large)
- MySQL: Метаданные, таймкоды, источники

### Статистика данных

| Метрика | Значение |
|---------|----------|
| Архивов | 1 (MENTORSTVO01.zip) |
| Файлов в архиве | 15 TXT |
| Всего чанков | 805 |
| Всего символов | 268,052 |
| Среднее слов/чанк | 53.5 |
| Средняя длительность | 19.1 сек |
| Размер вектора | 3072 измерения (text-embedding-3-large) |

---

## 🔧 ПОДГОТОВКА К МИГРАЦИИ

### Предварительные требования

**На локальной машине:**
- Git для клонирования репозитория
- SSH ключи для доступа к серверу
- Доступ к исходным файлам архива

**На production сервере (46.8.255.137):**
- Ubuntu 22.04 LTS или выше
- Node.js 22.13.0 или выше
- Python 3.11 или выше
- Docker (для Qdrant)
- MySQL 8.0 или выше
- 10GB свободного места на диске

### Чеклист подготовки

- [ ] Проверить доступ к production серверу по SSH
- [ ] Убедиться в наличии всех необходимых зависимостей
- [ ] Создать резервную копию текущей конфигурации
- [ ] Подготовить переменные окружения для production
- [ ] Скачать архив MENTORSTVO01.zip
- [ ] Подготовить SQL скрипты для инициализации БД

---

## 🚀 РАЗВЕРТЫВАНИЕ НА PRODUCTION

### Шаг 1: Подключение к серверу

```bash
# Подключиться к серверу по SSH
ssh root@46.8.255.137

# Или используя SSH ключ (рекомендуется)
ssh -i ~/.ssh/production_key root@46.8.255.137
```

**Учетные данные сервера:**
- IP: 46.8.255.137
- Пользователь: root
- Домен: 788047.cloud4box.ru
- Регион: Moscow, Russia
- Тариф: VPS - AMD Ryzen 5.2 GHz, NVMe

### Шаг 2: Подготовка окружения

```bash
# Обновить систему
sudo apt update && sudo apt upgrade -y

# Установить необходимые пакеты
sudo apt install -y curl wget git build-essential

# Установить Node.js (если не установлен)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# Установить Python (если не установлен)
sudo apt install -y python3 python3-pip

# Установить Docker (для Qdrant)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Установить MySQL (если не установлен)
sudo apt install -y mysql-server
```

### Шаг 3: Развертывание Qdrant

```bash
# Создать директорию для Qdrant
mkdir -p /opt/qdrant/data

# Запустить Qdrant контейнер
docker run -d \
  --name qdrant \
  -p 6333:6333 \
  -p 6334:6334 \
  -v /opt/qdrant/data:/qdrant/storage \
  qdrant/qdrant:latest

# Проверить статус
docker ps | grep qdrant
curl http://localhost:6333/health
```

### Шаг 4: Клонирование проекта

```bash
# Создать директорию для проекта
mkdir -p /opt/sergeev_digitization_system
cd /opt/sergeev_digitization_system

# Клонировать репозиторий
git clone <repository-url> .

# Установить зависимости
pnpm install
```

### Шаг 5: Конфигурация MySQL

```bash
# Подключиться к MySQL
mysql -u root -p

# Создать БД и пользователя
CREATE DATABASE sergeev_digitization;
CREATE USER 'sergeev'@'localhost' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON sergeev_digitization.* TO 'sergeev'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# Инициализировать схему
pnpm db:push
```

---

## ⚙️ КОНФИГУРАЦИЯ ОКРУЖЕНИЯ

### Переменные окружения

Создать файл `.env.production`:

```env
# Database
DATABASE_URL=mysql://sergeev:secure_password@localhost:3306/sergeev_digitization

# Qdrant
QDRANT_URL=http://localhost:6333
QDRANT_API_KEY=your_api_key_here

# Node
NODE_ENV=production
PORT=3000

# OAuth (если используется)
VITE_APP_ID=your_app_id
OAUTH_SERVER_URL=https://api.manus.im
JWT_SECRET=your_jwt_secret

# LLM (для production эмбеддингов)
OPENAI_API_KEY=your_openai_key
EMBEDDING_MODEL=text-embedding-3-small

# Мониторинг
LOG_LEVEL=info
SENTRY_DSN=your_sentry_dsn
```

### Загрузка переменных

```bash
# Скопировать в production
scp .env.production root@46.8.255.137:/opt/sergeev_digitization_system/

# На сервере
cd /opt/sergeev_digitization_system
source .env.production
```

---

## 📥 ЗАГРУЗКА ДАННЫХ

### Шаг 1: Загрузка архива

```bash
# На локальной машине
scp /path/to/MENTORSTVO01.zip root@46.8.255.137:/opt/sergeev_digitization_system/

# На сервере
cd /opt/sergeev_digitization_system
unzip MENTORSTVO01.zip
```

### Шаг 2: Запуск парсера

```bash
# На сервере
python3 process_archive.py

# Результат: processing_results.json с 805 чанками
```

### Шаг 3: Загрузка в Qdrant через API

```bash
# Запустить dev сервер
pnpm dev

# В другом терминале, загрузить архив
curl -X POST http://localhost:3000/api/trpc/archiveIndexing.indexFromJson \
  -H "Content-Type: application/json" \
  -d '{
    "archiveId": "MENTORSTVO01",
    "jsonData": "'"$(cat processing_results.json | jq -c .)"'"
  }'
```

### Шаг 4: Проверка загрузки

```bash
# Получить статистику коллекции
curl http://localhost:3000/api/trpc/archiveIndexing.getCollectionStats

# Ожидаемый результат:
# {
#   "success": true,
#   "stats": {
#     "totalPoints": 805,
#     "vectorSize": 384
#   }
# }
```

---

## 🧪 ТЕСТИРОВАНИЕ

### Тест 1: Проверка Qdrant

```bash
# Проверить здоровье Qdrant
curl http://localhost:6333/health

# Ожидаемый результат: {"status":"ok"}
```

### Тест 2: Проверка API

```bash
# Проверить существование коллекции
curl http://localhost:3000/api/trpc/archiveIndexing.collectionExists

# Ожидаемый результат: {"success":true,"exists":true}
```

### Тест 3: Тестирование поиска

```bash
# Создать тестовый вектор и выполнить поиск
curl -X POST http://localhost:3000/api/trpc/archiveIndexing.search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "менторство",
    "limit": 5
  }'
```

### Запуск автоматических тестов

```bash
# На сервере
pnpm test -- qdrantSearch.test.ts

# Все тесты должны пройти успешно
```

---

## 📊 МОНИТОРИНГ И ПОДДЕРЖКА

### Мониторинг Qdrant

```bash
# Проверить статус контейнера
docker ps | grep qdrant

# Просмотреть логи
docker logs -f qdrant

# Проверить использование памяти
docker stats qdrant
```

### Мониторинг приложения

```bash
# Просмотреть логи приложения
tail -f /opt/sergeev_digitization_system/.manus-logs/devserver.log

# Проверить статус процесса
ps aux | grep node
```

### Резервное копирование

```bash
# Резервная копия Qdrant
docker exec qdrant tar czf - /qdrant/storage | gzip > qdrant_backup.tar.gz

# Резервная копия MySQL
mysqldump -u sergeev -p sergeev_digitization > db_backup.sql

# Загрузить на локальную машину
scp root@46.8.255.137:/opt/sergeev_digitization_system/qdrant_backup.tar.gz .
scp root@46.8.255.137:/opt/sergeev_digitization_system/db_backup.sql .
```

### Восстановление из резервной копии

```bash
# Восстановить Qdrant
docker stop qdrant
docker rm qdrant
tar xzf qdrant_backup.tar.gz -C /opt/qdrant/data
docker run -d --name qdrant -p 6333:6333 -v /opt/qdrant/data:/qdrant/storage qdrant/qdrant:latest

# Восстановить MySQL
mysql -u sergeev -p sergeev_digitization < db_backup.sql
```

---

## 🔒 БЕЗОПАСНОСТЬ

### SSH ключи (рекомендуется)

```bash
# На локальной машине, создать SSH ключ
ssh-keygen -t rsa -b 4096 -f ~/.ssh/production_key

# Скопировать публичный ключ на сервер
ssh-copy-id -i ~/.ssh/production_key.pub root@46.8.255.137

# На сервере, отключить пароль
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### Firewall

```bash
# На сервере, настроить firewall
sudo ufw enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 3000/tcp  # Node.js приложение
sudo ufw allow 6333/tcp  # Qdrant
sudo ufw allow 3306/tcp  # MySQL (только для локальных подключений)
```

### Переменные окружения

```bash
# Никогда не коммитить .env файлы в Git
echo ".env.production" >> .gitignore

# Использовать переменные окружения для чувствительных данных
# Никогда не хранить пароли в коде
```

---

## 📞 ПОДДЕРЖКА И КОНТАКТЫ

**Координатор проекта:** Андрей  
**Техническая поддержка:** Manus AI  
**Статус сервера:** Активен до 23/05/2026  

### Полезные ссылки

- [Qdrant документация](https://qdrant.tech/documentation/)
- [Node.js документация](https://nodejs.org/docs/)
- [MySQL документация](https://dev.mysql.com/doc/)
- [Docker документация](https://docs.docker.com/)

---

## 📝 ВЕРСИЯ ДОКУМЕНТАЦИИ

| Версия | Дата | Изменения |
|--------|------|-----------|
| 1.0 | 2026-05-09 | Первоначальная версия |

---

**Документ подготовлен:** 2026-05-09  
**Статус:** ✅ ГОТОВО К ИСПОЛЬЗОВАНИЮ  
**Последнее обновление:** 2026-05-09
