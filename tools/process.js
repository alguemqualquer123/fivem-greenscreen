#!/usr/bin/env node

const sharp = require('sharp');
const path = require('path');

async function removeGreenBackground(inputPath, outputPath, tolerance) {
    tolerance = parseInt(tolerance) || 50;

    const image = sharp(inputPath);
    const metadata = await image.metadata();
    const { data, info } = await image
        .raw()
        .toBuffer({ resolveWithObject: true });

    const channels = info.channels;
    const width = info.width;
    const height = info.height;
    const pixelCount = width * height;

    const output = Buffer.alloc(pixelCount * 4);

    const minG = 150;
    const maxR = tolerance;
    const maxB = tolerance;

    for (let i = 0; i < pixelCount; i++) {
        const offset = i * channels;
        const outOffset = i * 4;

        let r = data[offset];
        let g = channels >= 2 ? data[offset + 1] : r;
        let b = channels >= 3 ? data[offset + 2] : r;

        output[outOffset] = r;
        output[outOffset + 1] = g;
        output[outOffset + 2] = b;

        const isGreen = g > minG && r < (g * 0.4 + maxR) && b < (g * 0.4 + maxB);

        if (isGreen) {
            output[outOffset + 3] = 0;
        } else {
            const greenness = Math.max(0, g - Math.max(r, b)) / 255.0;
            const alpha = Math.round(255 * (1.0 - greenness * 0.8));
            output[outOffset + 3] = Math.max(0, Math.min(255, alpha));
        }
    }

    await sharp(output, {
        raw: {
            width: width,
            height: height,
            channels: 4
        }
    })
        .png({ compressionLevel: 6 })
        .toFile(outputPath);

    return true;
}

async function main() {
    const args = process.argv.slice(2);

    if (args.length < 2) {
        console.error('Usage: node process.js <input.png> <output.png> [tolerance]');
        process.exit(1);
    }

    const inputPath = args[0];
    const outputPath = args[1];
    const tolerance = args[2] || 50;

    try {
        await removeGreenBackground(inputPath, outputPath, tolerance);
        console.log('SUCCESS: ' + outputPath);
    } catch (err) {
        console.error('ERROR: ' + err.message);
        process.exit(1);
    }
}

main();
