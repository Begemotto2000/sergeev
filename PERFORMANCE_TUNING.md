# Performance Tuning Guide

## Overview

This guide provides recommendations for optimizing the Sergeev Digitization System for production environments.

---

## 1. Caching Optimization

### Current Configuration
```typescript
const OPTIMIZATION_CONFIG = {
  batchSize: 50,
  cacheEnabled: true,
  cacheTTL: 300000,        // 5 minutes
  indexOptimization: true,
};
```

### Tuning Recommendations

#### For High-Traffic Scenarios
```typescript
const OPTIMIZATION_CONFIG = {
  batchSize: 100,          // Increase batch size
  cacheEnabled: true,
  cacheTTL: 600000,        // 10 minutes
  indexOptimization: true,
};
```

**Expected Improvement:** 30-40% reduction in query latency

#### For Memory-Constrained Environments
```typescript
const OPTIMIZATION_CONFIG = {
  batchSize: 25,           // Reduce batch size
  cacheEnabled: true,
  cacheTTL: 120000,        // 2 minutes
  indexOptimization: true,
};
```

**Expected Improvement:** 50% reduction in memory usage

### Monitoring Cache Performance

```typescript
// Check cache hit rate
const metrics = await trpc.knowledgeBaseOptimized.getPerformanceMetrics.query();
console.log(`Cache Hit Rate: ${metrics.cacheHitRate}%`);

// Target: 60-80% for optimal performance
// If < 50%: Increase cacheTTL
// If > 90%: May indicate insufficient query diversity
```

---

## 2. Database Optimization

### Connection Pooling

**Current:** MySQL2 with default connection pool (10 connections)

**For Production:**
```typescript
// In drizzle.config.ts
export default {
  schema: './drizzle/schema.ts',
  out: './drizzle',
  driver: 'mysql2',
  dbCredentials: {
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '3306'),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    // Increase pool size for high concurrency
    connectionLimit: 50,
    waitForConnections: true,
    connectionTimeout: 10000,
    queueLimit: 0,
  },
};
```

### Query Optimization

1. **Add Indexes**
```sql
CREATE INDEX idx_search_history_user_id ON search_history(userId);
CREATE INDEX idx_search_history_mode ON search_history(mode);
CREATE INDEX idx_indexed_transcriptions_upload_id ON indexed_transcriptions(uploadId);
CREATE INDEX idx_transcription_uploads_user_id ON transcription_uploads(userId);
```

2. **Archive Old Data**
```sql
-- Archive search history older than 90 days
INSERT INTO search_history_archive
SELECT * FROM search_history
WHERE createdAt < DATE_SUB(NOW(), INTERVAL 90 DAY);

DELETE FROM search_history
WHERE createdAt < DATE_SUB(NOW(), INTERVAL 90 DAY);
```

---

## 3. Qdrant Vector Database Optimization

### Index Configuration

**Current:** Default Qdrant settings

**For Production:**
```yaml
# qdrant_config.yaml
storage:
  # Increase snapshot interval
  snapshots_path: ./snapshots
  wal_path: ./wal
  
performance:
  # Enable memory mapping for large collections
  max_search_batch_size: 100
  
  # Optimize for read-heavy workloads
  default_segment_type: mmap
```

### Vector Dimension Tuning

```typescript
// Current: 384-dimensional embeddings
// For better performance:
// - 256 dimensions: 33% faster, 33% less memory
// - 512 dimensions: 33% slower, 33% more memory

export async function generateEmbedding(
  text: string,
  dimension: number = 256  // Reduce from 384
): Promise<number[]> {
  // ...
}
```

### Batch Processing

```typescript
// Current: 5 vectors per batch
// Optimize for throughput:

export async function createEmbeddingsForChunks(
  chunks: ChunkedSegment[],
  batchSize: number = 20  // Increase from 5
): Promise<VectorEmbedding[]> {
  // ...
}
```

---

## 4. LLM API Optimization

### Request Batching

```typescript
// Instead of individual requests
const responses = await Promise.all(
  texts.map(text => invokeLLM({...}))
);

// Use batch processing
const batchedResponses = await invokeLLMBatch(texts);
```

### Token Optimization

```typescript
// Reduce context window
const context = formattedResults
  .slice(0, 3)  // Top 3 results instead of all
  .map(r => `[${r.videoTitle}] ${r.text}`)
  .join('\n\n');

// Limit context to 2000 tokens
const limitedContext = context.substring(0, 8000);
```

### Caching LLM Responses

```typescript
// Cache LLM-generated answers
const answerCache = new Map<string, string>();

export async function generateAnswerCached(
  query: string,
  context: string,
  mode: string
): Promise<string> {
  const cacheKey = `${query}_${mode}`;
  
  if (answerCache.has(cacheKey)) {
    return answerCache.get(cacheKey)!;
  }
  
  const answer = await generateAnswer(query, context, mode);
  answerCache.set(cacheKey, answer);
  
  return answer;
}
```

---

## 5. Frontend Performance

### API Call Optimization

```typescript
// Debounce search queries
const debouncedSearch = useMemo(
  () => debounce((query: string) => {
    trpc.knowledgeBaseOptimized.answerQueryOptimized.mutate({
      query,
      useCache: true
    });
  }, 500),
  []
);

// Use query caching
const queryClient = useQueryClient();
queryClient.setQueryData(
  ['transcriptionIntake.listUploads'],
  uploads
);
```

### Component Optimization

```typescript
// Memoize expensive components
export const SearchResults = React.memo(({ results }) => {
  return results.map(r => <ResultCard key={r.id} result={r} />);
});

// Virtualize long lists
import { FixedSizeList } from 'react-window';
```

---

## 6. Infrastructure Scaling

### Horizontal Scaling

1. **Load Balancer Configuration**
```nginx
upstream app_backend {
  least_conn;  # Use least connections algorithm
  server app1:3000 weight=1;
  server app2:3000 weight=1;
  server app3:3000 weight=1;
  
  keepalive 32;
}
```

2. **Session Persistence**
```typescript
// Use Redis for session storage
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

const redisClient = createClient();
const store = new RedisStore({ client: redisClient });
```

### Vertical Scaling

**Recommended Production Specs:**
- CPU: 4+ cores
- RAM: 16GB+ (8GB minimum)
- Storage: 100GB+ SSD
- Network: 1Gbps+

---

## 7. Monitoring & Alerting

### Key Metrics to Monitor

```typescript
// 1. Cache Hit Rate
if (metrics.cacheHitRate < 50) {
  alert('Low cache hit rate - consider increasing TTL');
}

// 2. Average Query Time
if (metrics.avgSearchTime > 1000) {
  alert('Slow queries - check database performance');
}

// 3. System Health
const health = await trpc.health.getDetailedReport.query();
if (health.systemStatus !== 'healthy') {
  alert('System degraded - check components');
}

// 4. Memory Usage
if (parseFloat(health.resources.memory.heapUsed) > 8000) {
  alert('High memory usage - consider scaling');
}
```

### Prometheus Metrics

```typescript
// Export metrics for Prometheus
import promClient from 'prom-client';

const cacheHitRate = new promClient.Gauge({
  name: 'cache_hit_rate',
  help: 'Cache hit rate percentage'
});

const queryLatency = new promClient.Histogram({
  name: 'query_latency_ms',
  help: 'Query latency in milliseconds',
  buckets: [50, 100, 200, 500, 1000, 2000]
});
```

---

## 8. Transcription Processing Optimization

### Chunking Strategy

```typescript
// Current: 512 tokens per chunk
// Optimize based on use case:

// For precision (legal, medical):
const chunks = chunkTranscription(segments, videoId, 256);

// For speed (general knowledge):
const chunks = chunkTranscription(segments, videoId, 1024);

// For balanced performance:
const chunks = chunkTranscription(segments, videoId, 512);
```

### Parallel Processing

```typescript
// Process multiple uploads in parallel
const uploads = await Promise.all(
  files.map(file => 
    processTranscriptionFile(file.path, file.type, uploadId, userId)
  )
);
```

---

## 9. Cost Optimization

### LLM API Costs

| Strategy | Savings | Trade-off |
|----------|---------|-----------|
| Reduce context window | 30-40% | Slightly lower quality |
| Batch processing | 20-30% | Latency increase |
| Caching responses | 50-70% | Stale data risk |
| Use smaller model | 40-60% | Quality decrease |

### Storage Costs

| Strategy | Savings | Trade-off |
|----------|---------|-----------|
| Archive old data | 20-30% | Reduced historical data |
| Compress vectors | 15-20% | Precision loss |
| Delete duplicates | 10-20% | Data loss risk |

---

## 10. Benchmarking

### Performance Baseline

```typescript
// Measure baseline performance
const baseline = {
  avgQueryTime: 800,        // ms
  cacheHitRate: 65,         // %
  memoryUsage: 500,         // MB
  cpuUsage: 30,             // %
};

// After optimization, target:
const target = {
  avgQueryTime: 300,        // 62% improvement
  cacheHitRate: 80,         // 23% improvement
  memoryUsage: 300,         // 40% improvement
  cpuUsage: 15,             // 50% improvement
};
```

### Load Testing

```bash
# Use Apache Bench
ab -n 1000 -c 10 https://api.example.com/api/trpc/health.getStatus

# Use wrk for more detailed metrics
wrk -t12 -c400 -d30s https://api.example.com/api/trpc/health.getStatus
```

---

## Conclusion

Performance optimization is an iterative process. Start with monitoring, identify bottlenecks, apply targeted optimizations, and measure the impact. The recommendations in this guide should provide 2-3x performance improvement in most scenarios.

For additional support, refer to:
- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [MySQL Performance](https://dev.mysql.com/doc/)
- [Node.js Performance](https://nodejs.org/en/docs/guides/simple-profiling/)
