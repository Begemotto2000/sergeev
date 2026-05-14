#!/bin/bash

API_URL="http://46.8.255.137:3000"
HEALTH_LOG="/opt/sergeev-100/sergeev_digitization_system/logs/health.log"

# Проверить доступность API
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/api/jobs" 2>/dev/null)

# Проверить Docker контейнеры
cd /opt/sergeev-100/sergeev_digitization_system
CONTAINERS=$(docker compose ps --services --filter "status=running" 2>/dev/null | wc -l)
TOTAL_CONTAINERS=$(docker compose config --services 2>/dev/null | wc -l)

# Логировать результаты
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] API Status: $API_STATUS | Running Containers: $CONTAINERS/$TOTAL_CONTAINERS" >> "$HEALTH_LOG"

# Вернуть статус
if [ "$API_STATUS" = "200" ] && [ "$CONTAINERS" -ge 4 ]; then
    echo "HEALTHY"
    exit 0
else
    echo "UNHEALTHY"
    exit 1
fi
