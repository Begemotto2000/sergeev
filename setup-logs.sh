#!/bin/bash
PROJECT_PATH="/opt/sergeev-100/sergeev_digitization_system"

# Создать logrotate конфиг
cat > /etc/logrotate.d/sergeev-app << 'LOGROTATE'
$PROJECT_PATH/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 nodejs nodejs
    sharedscripts
    postrotate
        docker restart sergeyev-app > /dev/null 2>&1 || true
    endscript
}
LOGROTATE

echo "Logrotate configured"
