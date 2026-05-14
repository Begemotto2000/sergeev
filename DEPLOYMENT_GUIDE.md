# Deployment Guide — Sergeev Digitization System

## Overview

This guide covers deploying the Sergeev Digitization System to production environments.

## Prerequisites

- Node.js 22.13.0+
- PostgreSQL 14+
- Qdrant vector database
- Manus OAuth credentials
- Environment variables configured

## Environment Setup

### Required Environment Variables

```bash
# Database
DATABASE_URL=mysql://user:password@host:3306/database

# OAuth
VITE_APP_ID=your_app_id
OAUTH_SERVER_URL=https://api.manus.im
VITE_OAUTH_PORTAL_URL=https://login.manus.im
JWT_SECRET=your_jwt_secret

# Qdrant
QDRANT_URL=http://qdrant-server:6333
QDRANT_API_KEY=your_api_key

# LLM
BUILT_IN_FORGE_API_URL=https://api.manus.im/forge
BUILT_IN_FORGE_API_KEY=your_forge_key
VITE_FRONTEND_FORGE_API_KEY=your_frontend_key
VITE_FRONTEND_FORGE_API_URL=https://api.manus.im/forge

# Owner Info
OWNER_NAME=Your Name
OWNER_OPEN_ID=your_open_id

# Analytics
VITE_ANALYTICS_ENDPOINT=https://analytics.manus.im
VITE_ANALYTICS_WEBSITE_ID=your_website_id
```

## Deployment Steps

### 1. Build the Project

```bash
# Install dependencies
pnpm install

# Run database migrations
pnpm db:push

# Build frontend and backend
pnpm build
```

### 2. Start the Server

```bash
# Production mode
NODE_ENV=production pnpm start

# Or use PM2 for process management
pm2 start "pnpm start" --name "sergeev-digitization"
```

### 3. Verify Deployment

```bash
# Check server health
curl http://localhost:3000/api/health

# Check OAuth initialization
curl http://localhost:3000/api/trpc/auth.me

# Check analytics endpoints
curl http://localhost:3000/api/trpc/analytics.getDashboardSummary
```

## Docker Deployment

### Dockerfile

```dockerfile
FROM node:22-alpine

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN npm install -g pnpm && pnpm install --frozen-lockfile

# Copy source
COPY . .

# Build
RUN pnpm build

# Expose port
EXPOSE 3000

# Start
CMD ["pnpm", "start"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=mysql://user:password@db:3306/sergeev
      - QDRANT_URL=http://qdrant:6333
      - NODE_ENV=production
    depends_on:
      - db
      - qdrant

  db:
    image: mysql:8
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=sergeev
    volumes:
      - db_data:/var/lib/mysql

  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage

volumes:
  db_data:
  qdrant_data:
```

## Monitoring & Logs

### Log Files

- **Dev Server**: `.manus-logs/devserver.log`
- **Browser Console**: `.manus-logs/browserConsole.log`
- **Network Requests**: `.manus-logs/networkRequests.log`
- **Session Replay**: `.manus-logs/sessionReplay.log`

### Health Check Endpoint

```bash
GET /api/health

Response:
{
  "status": "ok",
  "timestamp": "2026-05-06T09:00:00Z",
  "uptime": 3600,
  "database": "connected",
  "qdrant": "connected"
}
```

## Performance Optimization

### Caching Strategy

- Query results cached in memory (5 minutes)
- Qdrant search results cached (10 minutes)
- LLM responses cached (24 hours)

### Database Optimization

```sql
-- Create indexes for search performance
CREATE INDEX idx_search_history_mode ON search_history(mode);
CREATE INDEX idx_search_history_created ON search_history(createdAt);
CREATE INDEX idx_search_results_query ON search_results(query);
```

### CDN Configuration

- Static assets served from CDN
- API responses gzipped
- HTTP/2 enabled

## Scaling

### Horizontal Scaling

- Use load balancer (nginx, HAProxy)
- Run multiple app instances
- Share database connection pool

### Vertical Scaling

- Increase Node.js heap size: `NODE_OPTIONS=--max-old-space-size=4096`
- Optimize Qdrant memory usage
- Use SSD for database

## Backup & Recovery

### Database Backup

```bash
# MySQL backup
mysqldump -u user -p database > backup.sql

# Restore
mysql -u user -p database < backup.sql
```

### Qdrant Backup

```bash
# Snapshot
curl -X POST http://qdrant:6333/snapshots

# Restore
curl -X POST http://qdrant:6333/snapshots/restore
```

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check DATABASE_URL format
   - Verify MySQL is running
   - Check firewall rules

2. **Qdrant Connection Failed**
   - Verify QDRANT_URL is correct
   - Check Qdrant service status
   - Verify API key

3. **High Memory Usage**
   - Reduce cache TTL
   - Implement pagination for large queries
   - Monitor with `top` or PM2 monitoring

4. **Slow Response Times**
   - Check database query performance
   - Verify Qdrant index status
   - Review LLM API latency

## Support

For issues or questions, refer to:
- API_DOCUMENTATION.md
- USER_GUIDE.md
- ADMIN_GUIDE.md
