#!/bin/bash

API_URL="http://46.8.255.137:3000"
LOG_FILE="/opt/sergeev-100/sergeev_digitization_system/logs/monitor.log"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEM=85

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Проверить здоровье контейнеров
    cd /opt/sergeev-100/sergeev_digitization_system
    
    # Получить статус контейнеров
    APP_STATUS=$(docker compose ps sergeyev-app 2>/dev/null | grep -o "Up\|Exited\|Restarting" | head -1)
    MYSQL_STATUS=$(docker compose ps sergeyev-mysql 2>/dev/null | grep -o "Up\|Exited" | head -1)
    REDIS_STATUS=$(docker compose ps sergeyev-redis 2>/dev/null | grep -o "Up\|Exited" | head -1)
    
    # Получить использование ресурсов
    CPU_USAGE=$(docker stats sergeyev-app --no-stream 2>/dev/null | tail -1 | awk '{print $3}' | sed 's/%//' || echo "0")
    MEM_USAGE=$(docker stats sergeyev-app --no-stream 2>/dev/null | tail -1 | awk '{print $7}' | sed 's/%//' || echo "0")
    
    # Проверить API
    API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/api/jobs" 2>/dev/null || echo "000")
    
    # Логировать
    echo "[$TIMESTAMP] App: $APP_STATUS | MySQL: $MYSQL_STATUS | Redis: $REDIS_STATUS | CPU: ${CPU_USAGE}% | MEM: ${MEM_USAGE}% | API: $API_RESPONSE" >> "$LOG_FILE"
    
    # Проверить пороги и отправить алерты
    if (( $(echo "$CPU_USAGE > $ALERT_THRESHOLD_CPU" | bc -l) )); then
        echo "[$TIMESTAMP] ALERT: High CPU usage: ${CPU_USAGE}%" >> "$LOG_FILE"
    fi
    
    if (( $(echo "$MEM_USAGE > $ALERT_THRESHOLD_MEM" | bc -l) )); then
        echo "[$TIMESTAMP] ALERT: High memory usage: ${MEM_USAGE}%" >> "$LOG_FILE"
    fi
    
    if [ "$APP_STATUS" != "Up" ]; then
        echo "[$TIMESTAMP] ALERT: App container is not running!" >> "$LOG_FILE"
    fi
    
    if [ "$API_RESPONSE" != "200" ]; then
        echo "[$TIMESTAMP] ALERT: API returned HTTP $API_RESPONSE" >> "$LOG_FILE"
    fi
    
    sleep 60
done
