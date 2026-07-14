import express from 'express';
import sharp from 'sharp';
import path from 'path';
import fs from 'fs';

const app = express();
const PORT = 3210;

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

const IMAGES_DIR = path.join(__dirname, '..', '..', 'images');
const CONCURRENCY = 4; // parallel workers

// Ensure directories exist
['clothing', 'objects', 'vehicles'].forEach(dir => {
    const dirPath = path.join(IMAGES_DIR, dir);
    if (!fs.existsSync(dirPath)) fs.mkdirSync(dirPath, { recursive: true });
});

// ============================================
// In-memory queue
// ============================================

interface QueueItem {
    filename: string;
    image: string; // base64
    tolerance: number;
    removeBg: boolean;
}

interface QueueResult {
    filename: string;
    ok: boolean;
    error?: string;
}

let queue: QueueItem[] = [];
let processing = false;
let totalQueued = 0;
let totalProcessed = 0;

function processItem(item: QueueItem): Promise<QueueResult> {
    return new Promise(async (resolve) => {
        try {
            let base64 = item.image;
            if (base64.includes(',')) base64 = base64.split(',')[1];

            const inputBuffer = Buffer.from(base64, 'base64');

            let outputBuffer: Buffer;
            if (item.removeBg) {
                outputBuffer = await removeGreenBackground(inputBuffer, item.tolerance);
            } else {
                outputBuffer = inputBuffer;
            }

            const filePath = path.join(IMAGES_DIR, item.filename);
            const dir = path.dirname(filePath);
            if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

            await fs.promises.writeFile(filePath, outputBuffer);
            resolve({ filename: item.filename, ok: true });
        } catch (err: any) {
            resolve({ filename: item.filename, ok: false, error: err.message });
        }
    });
}

async function processQueue() {
    if (processing) return;
    processing = true;

    while (queue.length > 0) {
        // Take batch of items
        const batch = queue.splice(0, CONCURRENCY);

        // Process in parallel
        const results = await Promise.all(batch.map(item => processItem(item)));

        totalProcessed += results.length;

        const ok = results.filter(r => r.ok).length;
        const fail = results.filter(r => !r.ok).length;
        if (fail > 0) {
            console.log(`[greenscreener] Batch: ${ok} ok, ${fail} failed (${totalProcessed}/${totalQueued})`);
        }
    }

    console.log(`[greenscreener] Queue complete: ${totalProcessed}/${totalQueued}`);
    processing = false;
    totalQueued = 0;
    totalProcessed = 0;
}

// ============================================
// Green screen removal (precise color #02C811)
// ============================================

async function removeGreenBackground(inputBuffer: Buffer, tolerance: number = 15): Promise<Buffer> {
    const { data, info } = await sharp(inputBuffer)
        .raw()
        .toBuffer({ resolveWithObject: true });

    const channels = info.channels;
    const width = info.width;
    const height = info.height;
    const pixelCount = width * height;

    const output = Buffer.alloc(pixelCount * 4);

    // Target color: #02C811 (RGB: 2, 200, 17)
    const targetR = 2;
    const targetG = 200;
    const targetB = 17;

    // Tolerance threshold for color matching
    const maxDist = tolerance * tolerance * 3; // Euclidean distance squared

    for (let i = 0; i < pixelCount; i++) {
        const offset = i * channels;
        const outOffset = i * 4;

        const r = data[offset];
        const g = channels >= 2 ? data[offset + 1] : r;
        const b = channels >= 3 ? data[offset + 2] : r;

        // Calculate distance to target color
        const dr = r - targetR;
        const dg = g - targetG;
        const db = b - targetB;
        const distSq = dr * dr + dg * dg + db * db;

        if (distSq < maxDist) {
            // Exact match - make transparent
            output[outOffset] = r;
            output[outOffset + 1] = g;
            output[outOffset + 2] = b;
            output[outOffset + 3] = 0;
        } else {
            // Keep original pixel unchanged
            output[outOffset] = r;
            output[outOffset + 1] = g;
            output[outOffset + 2] = b;
            output[outOffset + 3] = 255;
        }
    }

    return sharp(output, { raw: { width, height, channels: 4 } })
        .png({ compressionLevel: 0 }) // No compression for maximum quality
        .toBuffer();
}

// ============================================
// Routes
// ============================================

app.get('/health', (_req, res) => {
    res.json({ status: 'ok', queue: queue.length, processing });
});

// Single save (immediate)
app.post('/save', async (req, res) => {
    try {
        const { filename, image, removeBg = true, tolerance = 50 } = req.body;

        if (!filename || !image) {
            res.status(400).json({ error: 'Missing filename or image' });
            return;
        }

        const result = await processItem({ filename, image, tolerance, removeBg });
        res.json(result);
    } catch (err: any) {
        res.status(500).json({ error: err.message });
    }
});

// Queue item (fast, non-blocking)
app.post('/queue', (req, res) => {
    const { filename, image, removeBg = true, tolerance = 50 } = req.body;

    if (!filename || !image) {
        res.status(400).json({ error: 'Missing filename or image' });
        return;
    }

    queue.push({ filename, image, tolerance, removeBg });
    totalQueued++;

    // Start processing in background
    processQueue();

    res.json({ ok: true, queued: queue.length });
});

// Queue batch (fast, non-blocking)
app.post('/queue-batch', (req, res) => {
    const { items, removeBg = true, tolerance = 50 } = req.body;

    if (!items || !Array.isArray(items)) {
        res.status(400).json({ error: 'Missing items array' });
        return;
    }

    for (const item of items) {
        queue.push({
            filename: item.filename,
            image: item.image,
            tolerance,
            removeBg,
        });
        totalQueued++;
    }

    processQueue();

    res.json({ ok: true, queued: queue.length, batch: items.length });
});

// Queue status
app.get('/status', (_req, res) => {
    res.json({
        queue: queue.length,
        processing,
        totalQueued,
        totalProcessed,
    });
});

// Clear queue
app.post('/clear', (_req, res) => {
    queue = [];
    totalQueued = 0;
    totalProcessed = 0;
    res.json({ ok: true });
});

app.listen(PORT, '127.0.0.1', () => {
    console.log(`[greenscreener] API running on http://127.0.0.1:${PORT}`);
    console.log(`[greenscreener] Concurrency: ${CONCURRENCY} workers`);
    console.log(`[greenscreener] Images: ${IMAGES_DIR}`);
});
