# 🚀 ИНСТРУКЦИЯ РАЗВЕРТЫВАНИЯ НА MOSCOW SERVER

**Дата:** 2026-05-06  
**Версия:** 1.0  
**Сервер:** 46.8.255.137 (788047.cloud4box.ru)  
**Путь:** /100  
**Админ пароль:** Nokia3310  

---

## 📋 БЫСТРЫЙ СТАРТ (5 МИНУТ)

### Шаг 1: Подключение к серверу

```bash
ssh root@46.8.255.137
# Пароль: k8hSaZ2XL37x
```

### Шаг 2: Создание директории проекта

```bash
mkdir -p /opt/sergeev-100
cd /opt/sergeev-100
```

### Шаг 3: Загрузка файлов проекта

**Вариант A: Через Git (рекомендуется)**
```bash
git clone https://github.com/your-repo/sergeev_digitization_system.git .
```

**Вариант B: Через SCP (с локального компьютера)**
```bash
scp -r /path/to/sergeev_digitization_system/* root@46.8.255.137:/opt/sergeev-100/
```

**Вариант C: Через tar архив**
```bash
# На локальном компьютере
tar -czf sergeev.tar.gz /home/ubuntu/sergeev_digitization_system/

# На сервере
cd /opt/sergeev-100
scp user@your-ip:sergeev.tar.gz .
tar -xzf sergeev.tar.gz
```

### Шаг 4: Проверка Docker и Docker Compose

```bash
docker --version
docker-compose --version

# Если не установлены, установить:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Шаг 5: Запуск приложения

```bash
cd /opt/sergeev-100

# Запустить все сервисы
docker-compose -f docker-compose.moscow.yml up -d

# Проверить статус
docker-compose -f docker-compose.moscow.yml ps

# Просмотреть логи
docker-compose -f docker-compose.moscow.yml logs -f app
```

### Шаг 6: Проверка доступности

```bash
# Проверить, что приложение запустилось
curl http://localhost:3000
curl http://46.8.255.137/100

# Проверить статус сервисов
docker-compose -f docker-compose.moscow.yml ps
```

---

## 🌐 ДОСТУП К ПРИЛОЖЕНИЮ

После успешного развертывания приложение доступно по адресам:

| Адрес | Описание |
|-------|---------|
| `http://46.8.255.137/100` | Основной адрес (IP) |
| `http://788047.cloud4box.ru/100` | Адрес через домен |
| `http://localhost:3000` | Локальный адрес на сервере |

---

## 🔧 УПРАВЛЕНИЕ СЕРВИСАМИ

### Остановка приложения

```bash
cd /opt/sergeev-100
docker-compose -f docker-compose.moscow.yml down
```

### Перезапуск приложения

```bash
cd /opt/sergeev-100
docker-compose -f docker-compose.moscow.yml restart app
```

### Просмотр логов

```bash
# Логи приложения
docker-compose -f docker-compose.moscow.yml logs -f app

# Логи базы данных
docker-compose -f docker-compose.moscow.yml logs -f postgres

# Логи Redis
docker-compose -f docker-compose.moscow.yml logs -f redis

# Логи Qdrant
docker-compose -f docker-compose.moscow.yml logs -f qdrant

# Логи Nginx
docker-compose -f docker-compose.moscow.yml logs -f nginx
```

### Проверка статуса

```bash
docker-compose -f docker-compose.moscow.yml ps
```

---

## 💾 УПРАВЛЕНИЕ ДАННЫМИ

### Резервная копия базы данных

```bash
# Создать резервную копию
docker-compose -f docker-compose.moscow.yml exec postgres pg_dump -U analyzer analyzer_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Восстановить из резервной копии
docker-compose -f docker-compose.moscow.yml exec -T postgres psql -U analyzer analyzer_db < backup_20260506_120000.sql
```

### Очистка данных

```bash
# Удалить все контейнеры и тома (ВНИМАНИЕ: потеря всех данных!)
docker-compose -f docker-compose.moscow.yml down -v
```

---

## 🔐 БЕЗОПАСНОСТЬ

### Изменение пароля администратора

```bash
# Обновить переменную окружения в docker-compose.moscow.yml
# ADMIN_PASSWORD=NewPassword123

docker-compose -f docker-compose.moscow.yml up -d
```

### Настройка SSL/HTTPS

```bash
# Установить Certbot
sudo apt-get install certbot python3-certbot-nginx

# Получить сертификат
sudo certbot certonly --standalone -d 788047.cloud4box.ru

# Скопировать сертификаты в проект
sudo cp /etc/letsencrypt/live/788047.cloud4box.ru/fullchain.pem ./ssl/
sudo cp /etc/letsencrypt/live/788047.cloud4box.ru/privkey.pem ./ssl/
sudo chown $USER:$USER ./ssl/*

# Обновить nginx.moscow.conf для использования SSL
# Перезапустить контейнеры
docker-compose -f docker-compose.moscow.yml restart nginx
```

---

## 🐛 РЕШЕНИЕ ПРОБЛЕМ

### Приложение не запускается

```bash
# Проверить логи
docker-compose -f docker-compose.moscow.yml logs app

# Проверить, что порты свободны
lsof -i :3000
lsof -i :5432
lsof -i :6379
lsof -i :6333
lsof -i :80

# Перезапустить все сервисы
docker-compose -f docker-compose.moscow.yml restart
```

### Ошибка подключения к базе данных

```bash
# Проверить статус PostgreSQL
docker-compose -f docker-compose.moscow.yml logs postgres

# Проверить переменные окружения
docker-compose -f docker-compose.moscow.yml config | grep DATABASE_URL

# Перезапустить PostgreSQL
docker-compose -f docker-compose.moscow.yml restart postgres
```

### Проблемы с Redis

```bash
# Проверить статус Redis
docker-compose -f docker-compose.moscow.yml logs redis

# Проверить подключение к Redis
docker-compose -f docker-compose.moscow.yml exec redis redis-cli ping

# Очистить Redis кеш
docker-compose -f docker-compose.moscow.yml exec redis redis-cli FLUSHALL
```

### Проблемы с Qdrant

```bash
# Проверить статус Qdrant
docker-compose -f docker-compose.moscow.yml logs qdrant

# Проверить API Qdrant
curl http://localhost:6333/health

# Перезапустить Qdrant
docker-compose -f docker-compose.moscow.yml restart qdrant
```

---

## 📊 МОНИТОРИНГ

### Проверка использования ресурсов

```bash
# CPU и память
docker stats

# Размер контейнеров
docker ps -s

# Размер томов
docker volume ls -f dangling=false
```

### Проверка здоровья приложения

```bash
# Проверить health endpoint
curl http://46.8.255.137/100/api/health

# Проверить статус системы
curl http://46.8.255.137/100/api/system/status
```

---

## 🔄 ОБНОВЛЕНИЕ ПРИЛОЖЕНИЯ

### Обновить код

```bash
cd /opt/sergeev-100

# Получить последние изменения
git pull origin main

# Пересобрать контейнер
docker-compose -f docker-compose.moscow.yml build --no-cache

# Перезапустить приложение
docker-compose -f docker-compose.moscow.yml up -d
```

---

## 📞 ПОДДЕРЖКА

Если возникли проблемы:

1. Проверьте логи: `docker-compose -f docker-compose.moscow.yml logs app`
2. Проверьте статус сервисов: `docker-compose -f docker-compose.moscow.yml ps`
3. Проверьте подключение: `curl http://46.8.255.137/100`
4. Перезапустите приложение: `docker-compose -f docker-compose.moscow.yml restart`

---

**Версия документации:** 1.0  
**Последнее обновление:** 2026-05-06  
**Статус:** ✅ Готово к развертыванию
