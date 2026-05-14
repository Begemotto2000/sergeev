#!/bin/bash
SERVER="http://localhost:8100"

echo "=== TESTING API ENDPOINTS ==="
echo ""

echo "1. GET /api/jobs"
curl -s "$SERVER/api/jobs" | jq . || echo "Failed"
echo ""

echo "2. GET /api/trpc/auth.me"
curl -s "$SERVER/api/trpc/auth.me" | jq . || echo "Failed"
echo ""

echo "3. POST /api/upload (test with empty file)"
curl -s -X POST "$SERVER/api/upload" | jq . || echo "Failed"
echo ""

echo "4. GET /api/job/test-id (non-existent)"
curl -s "$SERVER/api/job/test-id" | jq . || echo "Failed"
echo ""

echo "=== CONTAINER STATUS ==="
docker ps | grep sergeyev-app
echo ""

echo "=== CHECKING DATABASE CONNECTIONS ==="
docker exec sergeyev-app node -e "console.log('Node.js running in container')" 2>&1 || echo "Container check failed"
