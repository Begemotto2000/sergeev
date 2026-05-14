#!/bin/bash

# Create test archive with sample data
mkdir -p /tmp/test_data
cd /tmp/test_data

# Create test files
cat > "lesson_01.txt" << 'TXTEOF'
Урок 1: Введение в систему
Это первый урок нашего курса. Здесь мы изучим основные концепции и принципы работы системы.
Основные темы:
1. История и развитие
2. Архитектура системы
3. Ключевые компоненты
4. Примеры использования

Детальное описание каждой темы будет представлено в следующих уроках.
TXTEOF

cat > "lesson_02.txt" << 'TXTEOF'
Урок 2: Архитектура и компоненты
В этом уроке мы рассмотрим архитектуру системы и основные компоненты.
Компоненты системы:
- Frontend: интерфейс пользователя
- Backend: обработка данных
- Database: хранение информации
- Vector Store: поиск по семантике

Каждый компонент играет важную роль в работе системы.
TXTEOF

# Create ZIP archive
cd /tmp
zip -r test_module.zip test_data/
ls -lh test_module.zip

# Test upload
echo ""
echo "=== Testing Upload ==="
curl -X POST -F 'file=@test_module.zip' http://46.8.255.137:3001/api/upload 2>/dev/null | jq .

