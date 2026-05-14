#!/bin/bash
set -e

SERVER_IP="46.8.255.137"
SERVER_USER="root"
APP_DIR="/opt/sergeyev-search"
APP_PORT="3000"

echo "📦 Building application for production..."
cd /home/ubuntu/sergeev_digitization_system
pnpm build

echo "📁 Creating deployment package..."
mkdir -p /tmp/deploy-package
cp -r /home/ubuntu/sergeev_digitization_system /tmp/deploy-package/

echo "🚀 Uploading to Moscow server..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $SERVER_USER@$SERVER_IP "mkdir -p $APP_DIR" 2>/dev/null || true
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r /tmp/deploy-package/sergeev_digitization_system/* $SERVER_USER@$SERVER_IP:$APP_DIR/ 2>&1 | head -20

echo "⚙️ Installing dependencies on server..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $SERVER_USER@$SERVER_IP << 'REMOTE_EOF'
#!/bin/bash
set -e

echo "📥 Installing system packages..."
apt-get update -qq
apt-get install -y -qq nodejs npm redis-server nginx curl > /dev/null 2>&1

echo "📦 Installing pnpm..."
npm install -g pnpm pm2 > /dev/null 2>&1

echo "🔧 Setting up application..."
cd /opt/sergeyev-search

echo "📚 Installing dependencies..."
pnpm install --frozen-lockfile 2>&1 | tail -5

echo "🏗️ Building application..."
pnpm build 2>&1 | tail -10

echo "⚙️ Configuring environment..."
cat > .env.production << 'ENV_EOF'
NODE_ENV=production
DATABASE_URL=postgresql://analyzer:analyzer2026@localhost:5432/analyzer_db
REDIS_URL=redis://localhost:6379
PORT=3000
JWT_SECRET=super-secret-jwt-key-change-in-production
VITE_APP_ID=sergeyev-search
OAUTH_SERVER_URL=https://api.manus.im
VITE_OAUTH_PORTAL_URL=https://oauth.manus.im
OWNER_NAME=Sergeyev
OWNER_OPEN_ID=sergeyev-001
BUILT_IN_FORGE_API_URL=https://api.manus.im
BUILT_IN_FORGE_API_KEY=demo-key
VITE_FRONTEND_FORGE_API_URL=https://api.manus.im
VITE_FRONTEND_FORGE_API_KEY=demo-key
VITE_APP_TITLE=Sergeyev Search System
VITE_APP_LOGO=/logo.svg
VITE_ANALYTICS_ENDPOINT=https://analytics.manus.im
VITE_ANALYTICS_WEBSITE_ID=sergeyev-001
ENV_EOF

echo "🚀 Starting application with PM2..."
pm2 delete sergeyev-search 2>/dev/null || true
pm2 start "pnpm start" --name "sergeyev-search" --instances 2 --env production

echo "🌐 Configuring Nginx..."
cat > /etc/nginx/sites-available/sergeyev << 'NGINX_EOF'
upstream sergeyev_backend {
    server localhost:3000 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

server {
    listen 80 default_server;
    server_name _;
    
    client_max_body_size 100M;
    
    gzip on;
    gzip_types text/plain text/css text/javascript application/json;

    location / {
        proxy_pass http://sergeyev_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /api/trpc {
        proxy_pass http://sergeyev_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /health {
        proxy_pass http://sergeyev_backend;
        access_log off;
    }
}
NGINX_EOF

ln -sf /etc/nginx/sites-available/sergeyev /etc/nginx/sites-enabled/sergeyev
rm -f /etc/nginx/sites-enabled/default

echo "✅ Testing Nginx configuration..."
nginx -t

echo "🔄 Restarting services..."
systemctl restart nginx
systemctl enable redis-server
systemctl enable nginx
systemctl start redis-server

echo "💾 Saving PM2 configuration..."
pm2 startup systemd -u root --hp /root
pm2 save

echo "✅ Deployment complete!"
echo ""
echo "🌐 Access your application at:"
echo "   http://46.8.255.137"
echo "   http://788047.cloud4box.ru"
echo ""
echo "📊 API endpoint:"
echo "   http://46.8.255.137/api/trpc"
echo ""
echo "📝 Logs:"
echo "   pm2 logs sergeyev-search"
echo ""
echo "🔄 Status:"
echo "   pm2 status"

REMOTE_EOF

echo "✅ Deployment script executed!"
echo ""
echo "🎉 Your application is now running on the Moscow server!"
echo ""
echo "📍 Access it at:"
echo "   🌐 http://46.8.255.137"
echo "   🌐 http://788047.cloud4box.ru"
echo ""
echo "🔍 Demo page:"
echo "   http://46.8.255.137/demo"
echo ""
echo "⏳ Give it 30-60 seconds to fully start..."
