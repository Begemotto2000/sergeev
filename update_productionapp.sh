cd /home/ubuntu/sergeev_digitization_system

# Update productionApp.ts to import and use archive and Qdrant services
sed -i "s/import { randomUUID } from 'crypto';/import { randomUUID } from 'crypto';\nimport { processArchive } from '.\/archiveService.js';\nimport { initializeCollection, indexChunks, searchChunks, getCollectionStats } from '.\/qdrantService.js';/" server/productionApp.ts

# Add Qdrant initialization after app creation
sed -i "/app.use(express.static/a\\  \/\/ Initialize Qdrant collection on startup\\n  const COLLECTION_NAME = 'sergeyev_lessons';\\n  initializeCollection(COLLECTION_NAME).catch(err => console.error('Failed to initialize Qdrant:', err));" server/productionApp.ts

echo "✅ Updated productionApp.ts"
