const fs = require('fs');
const path = require('path');

const inputPath = process.argv[2];
const outputPath = process.argv[3];
const targetW = parseInt(process.argv[4]) || 512;
const targetH = parseInt(process.argv[5]) || 512;
const format = process.argv[6] || 'webp';

if (!inputPath || !outputPath) {
    console.log('Usage: node process_image.js <input> <output> [width] [height] [format]');
    process.exit(1);
}

let sharp;
try {
    sharp = require('sharp');
} catch (e) {
    console.log('ERROR: sharp not available');
    process.exit(1);
}

async function processImage() {
    try {
        const inputBuf = fs.readFileSync(inputPath);
        console.log('Input: ' + inputPath + ' (' + inputBuf.length + ' bytes)');
        console.log('Processing: ' + targetW + 'x' + targetH + ' ' + format);

        let pipeline = sharp(inputBuf, { failOnError: false })
            .resize(targetW, targetH, {
                fit: 'contain',
                background: { r: 0, g: 0, b: 0, alpha: 0 },
                kernel: sharp.kernel.lanczos3
            });

        if (format === 'webp') {
            pipeline = pipeline.webp({
                quality: 95,
                alphaQuality: 100,
                smartSubsample: true
            });
        } else if (format === 'png') {
            pipeline = pipeline.png({ compressionLevel: 6 });
        } else {
            pipeline = pipeline.jpeg({ quality: 95 });
        }

        const outputBuf = await pipeline.toBuffer();

        fs.writeFileSync(outputPath, outputBuf);
        console.log('Output: ' + outputPath + ' (' + outputBuf.length + ' bytes)');
    } catch (e) {
        console.error('Error: ' + e.message);
        process.exit(1);
    }
}

processImage();
