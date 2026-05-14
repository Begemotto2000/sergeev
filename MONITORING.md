# Monitoring & Alerting Guide

## Overview

This guide covers monitoring, logging, and alerting for the Sergeev Digitization System.

## Log Files

All logs are stored in `.manus-logs/` directory with automatic rotation (max 1MB per file).

### Log Types

1. **devserver.log** - Server startup, Vite HMR, Express warnings
   - Format: `[ISO-TIMESTAMP] {...}`
   - Use: `tail -f .manus-logs/devserver.log`

2. **browserConsole.log** - Client-side console output
   - Includes: `console.log`, `warn`, `error` with stack traces
   - Use: `grep "ERROR" .manus-logs/browserConsole.log`

3. **networkRequests.log** - HTTP requests (fetch/XHR)
   - Fields: URL, status, duration, method
   - Use: `grep "500" .manus-logs/networkRequests.log`

4. **sessionReplay.log** - User interaction events
   - Events: clicks, focus, navigation, form submissions
   - Use: `tail -100 .manus-logs/sessionReplay.log`

## Health Checks

### Server Health Endpoint

```bash
# Check overall health
curl http://localhost:3000/api/health

# Response:
{
  "status": "ok",
  "timestamp": "2026-05-06T09:00:00Z",
  "uptime": 3600,
  "database": "connected",
  "qdrant": "connected",
  "llm": "available"
}
```

### Database Health

```bash
# Check database connection
curl http://localhost:3000/api/trpc/system.health

# Check query performance
EXPLAIN SELECT * FROM search_history LIMIT 10;
```

### Qdrant Health

```bash
# Check Qdrant status
curl http://qdrant:6333/health

# Check collection stats
curl http://qdrant:6333/collections
```

## Metrics to Monitor

### Performance Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| API Response Time | < 500ms | > 2000ms |
| Database Query Time | < 100ms | > 500ms |
| Qdrant Search Time | < 200ms | > 1000ms |
| LLM Generation Time | < 5s | > 15s |
| Memory Usage | < 512MB | > 1GB |
| CPU Usage | < 50% | > 80% |

### Business Metrics

| Metric | Description |
|--------|-------------|
| Total Queries | Cumulative search requests |
| Mode Distribution | ОТВЕТ vs ТАЙМКОД vs DEEP vs ИМИГО |
| Avg Confidence | Average answer confidence score |
| Success Rate | Queries with results / total queries |
| User Sessions | Active concurrent users |

### Error Metrics

| Metric | Alert Condition |
|--------|-----------------|
| 5xx Errors | > 5 in 5 minutes |
| Database Errors | Any connection failure |
| Qdrant Errors | Any search failure |
| LLM Errors | > 10% failure rate |
| Auth Errors | > 3 failed attempts per user |

## Monitoring Tools

### PM2 Monitoring

```bash
# Install PM2
npm install -g pm2

# Start with monitoring
pm2 start "pnpm start" --name "sergeev" --watch

# Monitor
pm2 monit

# Logs
pm2 logs sergeev

# Save config
pm2 save
```

### Prometheus Metrics

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'sergeev-app'
    static_configs:
      - targets: ['localhost:3000']
    metrics_path: '/metrics'
```

### Grafana Dashboard

Create dashboards for:
- Response times (by endpoint)
- Error rates (by type)
- Database performance
- Qdrant search performance
- LLM generation times
- User activity

## Alerting Rules

### Email Alerts

```
High Error Rate:
- Condition: error_rate > 5%
- Duration: 5 minutes
- Action: Email ops team

Database Down:
- Condition: database_health == down
- Duration: 1 minute
- Action: Page on-call engineer

High Memory Usage:
- Condition: memory_usage > 1GB
- Duration: 10 minutes
- Action: Email ops team
```

### Slack Notifications

```bash
# Send alert to Slack
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -d '{
    "text": "🚨 High error rate detected",
    "blocks": [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*Error Rate Alert*\nCurrent: 8.5%\nThreshold: 5%"
        }
      }
    ]
  }'
```

## Log Analysis

### Common Queries

```bash
# Find all errors
grep -i "error" .manus-logs/*.log

# Count errors by type
grep "ERROR" .manus-logs/*.log | cut -d: -f3 | sort | uniq -c

# Find slow queries
grep "responseTime" .manus-logs/networkRequests.log | awk '$NF > 1000'

# Find failed requests
grep '"status":5' .manus-logs/networkRequests.log

# User session analysis
grep "navigation" .manus-logs/sessionReplay.log | head -20
```

### Performance Analysis

```bash
# Average response time
grep "responseTime" .manus-logs/networkRequests.log | \
  awk '{sum+=$NF; count++} END {print sum/count}'

# P95 response time
grep "responseTime" .manus-logs/networkRequests.log | \
  awk '{print $NF}' | sort -n | \
  awk '{a[NR]=$1} END {print a[int(NR*0.95)]}'

# Error rate
echo "scale=2; $(grep -c 'ERROR' .manus-logs/*.log) / $(wc -l < .manus-logs/networkRequests.log) * 100" | bc
```

## Alerting Checklist

- [ ] Set up PM2 monitoring
- [ ] Configure Prometheus scraping
- [ ] Create Grafana dashboards
- [ ] Set up email alerts
- [ ] Configure Slack notifications
- [ ] Document on-call procedures
- [ ] Test alert routing
- [ ] Set up log aggregation (optional: ELK stack)
- [ ] Configure backup alerts
- [ ] Document escalation procedures

## Troubleshooting

### High Memory Usage

```bash
# Check memory by process
ps aux | grep node | grep -v grep

# Heap snapshot
node --inspect=0.0.0.0:9229 server.js
# Then use Chrome DevTools

# Clear cache
curl -X POST http://localhost:3000/api/cache/clear
```

### Database Performance Issues

```bash
# Check slow queries
SHOW VARIABLES LIKE 'long_query_time';
SET GLOBAL long_query_time = 1;

# Analyze table
ANALYZE TABLE search_history;

# Check indexes
SHOW INDEX FROM search_history;
```

### Qdrant Issues

```bash
# Check collection info
curl http://qdrant:6333/collections/search_vectors

# Rebuild index
curl -X POST http://qdrant:6333/collections/search_vectors/optimize

# Check disk space
du -sh /qdrant/storage
```

## Support

For monitoring issues, refer to:
- DEPLOYMENT_GUIDE.md
- Log files in `.manus-logs/`
- PM2 documentation
- Prometheus documentation
