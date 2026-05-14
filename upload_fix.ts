import express, { Router } from 'express';
import multer from 'multer';
import { v4 as uuidv4 } from 'uuid';
import ArchiveParser from '../services/archiveParser.js';
import VectorizationService from '../services/vectorization.js';
import QdrantIndexingService from '../services/qdrantIndexing.js';

const router = express.Router();

// SECURITY: File size and type validation
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 100 * 1024 * 1024 }, // 100 MB
  fileFilter: (req, file, cb) => {
    // SECURITY FIX #1: Validate MIME type
    const allowedMimes = ['application/zip', 'application/x-zip-compressed'];
    const allowedExtensions = ['.zip'];
    
    const ext = file.originalname.toLowerCase().substring(file.originalname.lastIndexOf('.'));
    const isValidExtension = allowedExtensions.includes(ext);
    const isValidMime = allowedMimes.includes(file.mimetype);
    
    if (!isValidExtension || !isValidMime) {
      return cb(new Error(`Invalid file type. Only ZIP files are allowed. Received: ${file.mimetype}`));
    }
    
    cb(null, true);
  }
});

// Job storage
const jobs = new Map<string, Job>();

// Services
const archiveParser = new ArchiveParser();
const vectorization = new VectorizationService();
const qdrant = new QdrantIndexingService();

interface Job {
  id: string;
  filename: string;
  fileSize: number;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  progress: number;
  totalChunks: number;
  processedChunks: number;
  logs: string[];
  createdAt: Date;
  updatedAt: Date;
  error?: string;
}

// Process archive asynchronously
async function processArchive(jobId: string, buffer: Buffer) {
  const job = jobs.get(jobId);
  if (!job) return;

  try {
    job.status = 'processing';
    job.logs.push(`[${new Date().toISOString()}] Processing started`);

    // Parse archive
    const files = await archiveParser.parseArchive(buffer);
    job.logs.push(`[${new Date().toISOString()}] Parsed ${files.length} files`);

    // Create chunks
    const chunks = archiveParser.createChunks(files);
    job.totalChunks = chunks.length;
    job.logs.push(`[${new Date().toISOString()}] Created ${chunks.length} chunks`);

    // Vectorize and index
    for (let i = 0; i < chunks.length; i += 10) {
      const batch = chunks.slice(i, i + 10);
      const vectors = await vectorization.vectorizeBatch(batch);
      await qdrant.indexVectors(vectors);
      job.processedChunks = Math.min(i + 10, chunks.length);
      job.progress = Math.round((job.processedChunks / job.totalChunks) * 100);
      job.logs.push(`[${new Date().toISOString()}] Progress: ${job.progress}%`);
    }

    job.status = 'completed';
    job.logs.push(`[${new Date().toISOString()}] Processing completed`);
  } catch (error) {
    job.status = 'failed';
    job.error = error instanceof Error ? error.message : 'Unknown error';
    job.logs.push(`[${new Date().toISOString()}] ERROR: ${job.error}`);
  }
}

// Upload endpoint with SECURITY FIX
router.post('/', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    // Additional validation
    if (req.file.size === 0) {
      return res.status(400).json({ error: 'File is empty' });
    }

    const jobId = uuidv4();
    const job: Job = {
      id: jobId,
      filename: req.file.originalname,
      fileSize: req.file.size,
      status: 'pending',
      progress: 0,
      totalChunks: 0,
      processedChunks: 0,
      logs: [`[${new Date().toISOString()}] Job created: ${jobId}`],
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    jobs.set(jobId, job);

    // Start processing asynchronously
    processArchive(jobId, req.file.buffer).catch((error) => {
      job.status = 'failed';
      job.error = error.message;
      job.logs.push(`[${new Date().toISOString()}] ERROR: ${error.message}`);
    });

    res.json({
      jobId,
      status: 'accepted',
      message: 'File received. Processing started.',
      filename: req.file.originalname,
      fileSize: req.file.size,
    });
  } catch (error) {
    res.status(500).json({
      error: error instanceof Error ? error.message : 'Upload failed',
    });
  }
});

// Get job status
router.get('/:jobId', (req, res) => {
  const job = jobs.get(req.params.jobId);
  if (!job) {
    return res.status(404).json({ error: 'Job not found' });
  }
  res.json(job);
});

export default router;
