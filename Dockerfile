# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

ARG BASE_PATH=/100
ENV BASE_PATH=${BASE_PATH}

# Install pnpm
RUN npm install -g pnpm

# Copy package files and pnpm patches required by patchedDependencies
COPY package.json pnpm-lock.yaml ./
COPY patches ./patches

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build application
RUN pnpm build

# Production stage
FROM node:22-alpine

WORKDIR /app

# Install pnpm and dumb-init
RUN npm install -g pnpm && \
    apk add --no-cache dumb-init

# Copy built application from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server ./server
COPY --from=builder /app/drizzle ./drizzle
COPY --from=builder /app/drizzle.config.ts ./drizzle.config.ts
COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-lock.yaml ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start application
ENTRYPOINT ["dumb-init", "--"]
CMD ["pnpm", "start"]
