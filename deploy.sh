#!/bin/bash
PROD_IP="${1:-46.8.255.137}"
PROD_USER="root"
DIST_ARCHIVE="/tmp/sergeev-dist.tar.gz"
echo "🚀 МИГРАЦИЯ НА PRODUCTION"
echo "Production IP: $PROD_IP"
if [ ! -f "$DIST_ARCHIVE" ]; then
    echo "❌ Архив не найден: $DIST_ARCHIVE"
    exit 1
fi
echo "✅ Архив найден ($(du -h $DIST_ARCHIVE | cut -f1))"
echo "📦 Копирование архива на production..."
scp "$DIST_ARCHIVE" "$PROD_USER@$PROD_IP:/tmp/"
echo "📂 Распаковка архива на production..."
ssh "$PROD_USER@$PROD_IP" "cd /opt/sergeev_digitization_system && tar -xzf /tmp/sergeev-dist.tar.gz && rm /tmp/sergeev-dist.tar.gz && ls -lh dist/"
echo "✅ МИГРАЦИЯ ЗАВЕРШЕНА"
