# API Endpoints Documentation v2.0

## Overview

This document describes all tRPC endpoints added in Phase 12-14, including transcription intake, optimization, and health monitoring.

---

## Transcription Intake Router (`trpc.transcriptionIntake.*`)

### 1. uploadTranscription
**Type:** Mutation (Protected)

**Purpose:** Upload and process transcription files (PDF, DOCX, TXT, JSON, SRT)

**Input:**
```typescript
{
  filename: string;           // File name (e.g., "lecture.pdf")
  fileBuffer: Buffer;         // File content as Buffer
  fileType: 'pdf' | 'docx' | 'txt' | 'json' | 'srt';
}
```

**Output:**
```typescript
{
  uploadId: number;
  status: 'processing';
  message: string;
}
```

**Example:**
```typescript
const result = await trpc.transcriptionIntake.uploadTranscription.mutate({
  filename: 'lecture.pdf',
  fileBuffer: pdfBuffer,
  fileType: 'pdf'
});
```

**File Size Limits:**
- PDF/DOCX: 50MB max
- TXT: 10MB max

---

### 2. getUploadStatus
**Type:** Query (Protected)

**Purpose:** Get current processing status of a transcription upload

**Input:**
```typescript
{
  uploadId: number;
}
```

**Output:**
```typescript
{
  id: number;
  userId: number;
  filename: string;
  fileType: string;
  fileUrl: string;
  status: 'pending' | 'processing' | 'indexed' | 'failed';
  errorMessage?: string;
  segmentCount: number;
  chunkCount: number;
  totalTokens: number;
  createdAt: Date;
  updatedAt: Date;
}
```

**Status Meanings:**
- `pending`: Waiting to be processed
- `processing`: Currently being processed
- `indexed`: Successfully indexed in Qdrant
- `failed`: Processing failed (check errorMessage)

---

### 3. listUploads
**Type:** Query (Protected)

**Purpose:** List all transcription uploads for the current user

**Input:** None

**Output:**
```typescript
Array<{
  id: number;
  filename: string;
  fileType: string;
  status: 'pending' | 'processing' | 'indexed' | 'failed';
  segmentCount: number;
  chunkCount: number;
  createdAt: Date;
}>
```

---

### 4. getIndexedChunks
**Type:** Query (Protected)

**Purpose:** Get all indexed chunks for a specific upload

**Input:**
```typescript
{
  uploadId: number;
}
```

**Output:**
```typescript
Array<{
  id: number;
  uploadId: number;
  chunkId: string;
  startTime: string;
  endTime: string;
  text: string;
  tokenCount: number;
  embeddingModel: string;
  createdAt: Date;
}>
```

---

### 5. deleteUpload
**Type:** Mutation (Protected)

**Purpose:** Delete a transcription upload and all associated chunks

**Input:**
```typescript
{
  uploadId: number;
}
```

**Output:**
```typescript
{
  success: boolean;
}
```

---

## Optimized Knowledge Base Router (`trpc.knowledgeBaseOptimized.*`)

### 1. answerQueryOptimized
**Type:** Mutation (Protected)

**Purpose:** Search with caching and performance optimization

**Input:**
```typescript
{
  query: string;              // Search query (1-1000 chars)
  topK?: number;              // Number of results (1-20, default: 5)
  useCache?: boolean;         // Enable caching (default: true)
}
```

**Output:**
```typescript
{
  mode: 'ОТВЕТ';
  query: string;
  answer: string;
  sources: Array<{
    videoTitle: string;
    startTime: string;
    endTime: string;
    text: string;
  }>;
  executionTime: number;      // milliseconds
  cached: boolean;
  performanceMetrics: {
    cacheHitRate: number;     // percentage
    avgSearchTime: number;    // milliseconds
  };
}
```

---

### 2. getPerformanceMetrics
**Type:** Query (Protected)

**Purpose:** Get current performance metrics

**Output:**
```typescript
{
  cacheHitRate: number;       // percentage
  avgSearchTime: number;      // milliseconds
  totalSearches: number;
  cacheHits: number;
  cacheMisses: number;
  recentSearches: Array<{
    query: string;
    time: number;
    cached: boolean;
    timestamp: number;
  }>;
}
```

---

### 3. analyzeQueryPerformance
**Type:** Query (Protected)

**Purpose:** Analyze query performance and get optimization recommendations

**Input:**
```typescript
{
  limit?: number;  // Number of recent searches to analyze (1-100, default: 50)
}
```

**Output:**
```typescript
{
  totalQueries: number;
  avgTime: number;
  slowQueries: Array<{
    query: string;
    time: number;
    cached: boolean;
  }>;
  recommendations: string[];
  slowestQuery: string;
  fastestQuery: string;
}
```

---

### 4. clearCache
**Type:** Mutation (Protected)

**Purpose:** Reset cache metrics

**Output:**
```typescript
{
  success: boolean;
  message: string;
}
```

---

### 5. getCacheStats
**Type:** Query (Protected)

**Purpose:** Get cache statistics

**Output:**
```typescript
{
  cacheHits: number;
  cacheMisses: number;
  hitRate: string;            // e.g., "75.50%"
  totalRequests: number;
}
```

---

## Health Check Router (`trpc.health.*`)

### 1. getStatus
**Type:** Query (Public)

**Purpose:** Get current system health status

**Output:**
```typescript
{
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: number;
  uptime: number;             // milliseconds
  components: {
    database: { status: 'ok' | 'error'; responseTime: number; };
    qdrant: { status: 'ok' | 'error'; responseTime: number; };
    llm: { status: 'ok' | 'error'; responseTime: number; };
  };
  metrics: {
    memoryUsage: number;      // MB
    cpuUsage: number;         // ms
    activeConnections: number;
  };
}
```

---

### 2. getDetailedReport
**Type:** Query (Public)

**Purpose:** Get comprehensive health report with resource usage

**Output:**
```typescript
{
  systemStatus: 'healthy' | 'degraded' | 'unhealthy';
  uptime: {
    milliseconds: number;
    formatted: string;        // e.g., "1h 30m"
  };
  components: {
    database: { status: 'ok' | 'error'; responseTime: number; description: string; };
    qdrant: { status: 'ok' | 'error'; responseTime: number; description: string; };
    llm: { status: 'ok' | 'error'; responseTime: number; description: string; };
  };
  resources: {
    memory: {
      heapUsed: string;       // e.g., "50.25 MB"
      heapTotal: string;
      external: string;
    };
    cpu: {
      user: string;           // e.g., "1500.00 ms"
      system: string;
    };
  };
  timestamp: string;          // ISO 8601
}
```

---

### 3. isReady
**Type:** Query (Public)

**Purpose:** Check if system is ready to accept requests

**Output:**
```typescript
{
  ready: boolean;
  components: {
    database: boolean;
    qdrant: boolean;
    llm: boolean;
  };
}
```

---

### 4. getComponentStatus
**Type:** Query (Public)

**Purpose:** Get status of a specific component

**Input:**
```typescript
{
  component: 'database' | 'qdrant' | 'llm';
}
```

**Output:**
```typescript
{
  component: string;
  status: 'ok' | 'error';
  responseTime: number;       // milliseconds
  timestamp: number;
}
```

---

### 5. getMetrics
**Type:** Query (Public)

**Purpose:** Get detailed system resource metrics

**Output:**
```typescript
{
  memory: {
    rss: string;              // e.g., "150.50 MB"
    heapTotal: string;
    heapUsed: string;
    external: string;
    arrayBuffers: string;
  };
  cpu: {
    user: string;             // e.g., "2500.00 ms"
    system: string;
  };
  uptime: {
    seconds: number;
    formatted: string;        // e.g., "2h 15m"
  };
  timestamp: string;          // ISO 8601
}
```

---

## Usage Examples

### Example 1: Upload and Process Transcription
```typescript
// Upload PDF
const upload = await trpc.transcriptionIntake.uploadTranscription.mutate({
  filename: 'lecture.pdf',
  fileBuffer: pdfBuffer,
  fileType: 'pdf'
});

// Check status
const status = await trpc.transcriptionIntake.getUploadStatus.query({
  uploadId: upload.uploadId
});

// Get indexed chunks
const chunks = await trpc.transcriptionIntake.getIndexedChunks.query({
  uploadId: upload.uploadId
});
```

### Example 2: Optimized Search with Caching
```typescript
// First search (cache miss)
const result1 = await trpc.knowledgeBaseOptimized.answerQueryOptimized.mutate({
  query: 'What is machine learning?',
  useCache: true
});

// Second search (cache hit)
const result2 = await trpc.knowledgeBaseOptimized.answerQueryOptimized.mutate({
  query: 'What is machine learning?',
  useCache: true
});

// Get metrics
const metrics = await trpc.knowledgeBaseOptimized.getPerformanceMetrics.query();
console.log(`Cache hit rate: ${metrics.cacheHitRate}%`);
```

### Example 3: Health Monitoring
```typescript
// Check system readiness
const ready = await trpc.health.isReady.query();
if (!ready.ready) {
  console.error('System not ready:', ready.components);
}

// Get detailed report
const report = await trpc.health.getDetailedReport.query();
console.log(`System status: ${report.systemStatus}`);
console.log(`Uptime: ${report.uptime.formatted}`);

// Monitor specific component
const dbStatus = await trpc.health.getComponentStatus.query({
  component: 'database'
});
```

---

## Error Handling

All endpoints follow standard tRPC error handling:

```typescript
try {
  const result = await trpc.transcriptionIntake.uploadTranscription.mutate({...});
} catch (error) {
  if (error.code === 'BAD_REQUEST') {
    console.error('Invalid input:', error.message);
  } else if (error.code === 'NOT_FOUND') {
    console.error('Resource not found:', error.message);
  } else if (error.code === 'INTERNAL_SERVER_ERROR') {
    console.error('Server error:', error.message);
  }
}
```

---

## Rate Limiting

- No explicit rate limiting on health endpoints (public)
- Protected endpoints inherit rate limiting from main API
- Caching reduces load on frequently accessed queries

---

## Performance Notes

- **Caching TTL:** 5 minutes (configurable)
- **Batch Size:** 50 vectors per batch
- **Average Response Time:** 100-300ms for cached queries, 500-1500ms for uncached
- **Memory Usage:** ~50-100MB typical, scales with cache size

---

## Monitoring Recommendations

1. **Health Checks:** Call `health.getStatus` every 30 seconds
2. **Performance:** Monitor `knowledgeBaseOptimized.getPerformanceMetrics` every 5 minutes
3. **Uploads:** Check `transcriptionIntake.getUploadStatus` after each upload
4. **Alerts:** Set up alerts when `health.getStatus.status !== 'healthy'`

---

## Version History

- **v2.0** (May 2026): Added transcription intake, optimization, and health endpoints
- **v1.0** (April 2026): Initial API with 4 RAG modes
