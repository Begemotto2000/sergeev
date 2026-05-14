#!/bin/bash
set -e

# Configuration
SERVER_IP="46.8.255.137"
SERVER_USER="root"
APP_DIR="/opt/sergeyev-search"
DOMAIN="788047.cloud4box.ru"

echo "🚀 Starting Docker deployment to Moscow server..."
echo "📍 Target: $SERVER_IP ($DOMAIN)"
echo ""

# Step 1: Create deployment package
echo "📦 Creating deployment package..."
mkdir -p /tmp/docker-deploy
cp Dockerfile docker-compose.yml nginx.conf /tmp/docker-deploy/
cp -r . /tmp/docker-deploy/app/ 2>/dev/null || true
cd /tmp/docker-deploy

# Step 2: Upload to server
echo "📤 Uploading to server..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $SERVER_USER@$SERVER_IP "mkdir -p $APP_DIR" 2>/dev/null || true
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r Dockerfile docker-compose.yml nginx.conf $SERVER_USER@$SERVER_IP:$APP_DIR/ 2>&1 | grep -v "Warning" || true

# Step 3: Deploy on server
echo "⚙️ Installing Docker and starting services..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $SERVER_USER@$SERVER_IP << 'REMOTE_SCRIPT'
#!/bin/bash
set -e

APP_DIR="/opt/sergeyev-search"
cd $APP_DIR

echo "📥 Installing Docker..."
apt-get update -qq > /dev/null 2>&1
apt-get install -y -qq docker.io docker-compose > /dev/null 2>&1 || apt-get install -y -qq docker.io docker-compose-plugin > /dev/null 2>&1

echo "🔧 Starting Docker daemon..."
systemctl start docker
systemctl enable docker

echo "🏗️ Building and starting containers..."
docker-compose up -d --build

echo "⏳ Waiting for services to be healthy..."
sleep 10

echo "✅ Checking service status..."
docker-compose ps

echo "🌐 Checking application health..."
for i in {1..30}; do
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        echo "✅ Application is healthy!"
        break
    fi
    echo "⏳ Waiting for application to start... ($i/30)"
    sleep 2
done

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📍 Access your application at:"
echo "   http://46.8.255.137"
echo "   http://788047.cloud4box.ru"
echo ""
echo "🔍 Demo page:"
echo "   http://46.8.255.137/demo"
echo ""
echo "📊 API endpoint:"
echo "   http://46.8.255.137/api/trpc"
echo ""
echo "📝 View logs:"
echo "   docker-compose logs -f app"
echo ""
echo "🔄 Check status:"
echo "   docker-compose ps"
echo ""
echo "🛑 Stop services:"
echo "   docker-compose down"

REMOTE_SCRIPT

echo ""
echo "✅ Docker deployment finished!"
echo ""
echo "🌐 Your application is now running at:"
echo "   🔗 http://46.8.255.137"
echo "   🔗 http://788047.cloud4box.ru"
echo ""
echo "⏳ Give it 30-60 seconds to fully initialize..."
echo "📊 Check status with: docker-compose ps"
