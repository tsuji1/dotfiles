#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const [, , inputPath, outputPath = inputPath, jszipPath] = process.argv;
if (!inputPath) {
  console.error('Usage: node remove-slide-number-slash.cjs input.pptx [output.pptx] [jszip-module-path]');
  process.exit(2);
}

function loadJSZip() {
  const candidates = [
    jszipPath,
    path.join(process.cwd(), 'node_modules/jszip'),
    '/home/yuzugon/slides/20260907/dom-to-pptx-quarto-demo/node_modules/jszip',
  ].filter(Boolean);
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return require(candidate);
  }
  throw new Error('JSZip not found; pass the demo node_modules/jszip path as the third argument');
}

async function main() {
  const JSZip = loadJSZip();
  const input = path.resolve(inputPath);
  const output = path.resolve(outputPath);
  const zip = await JSZip.loadAsync(fs.readFileSync(input));
  let removed = 0;

  for (const name of Object.keys(zip.files)) {
    if (!/^ppt\/slides\/slide\d+\.xml$/.test(name)) continue;
    const entry = zip.file(name);
    const xml = await entry.async('string');
    const patched = xml.replace(
      /(<a:fld\b[^>]*type="slidenum"[\s\S]*?<\/a:fld>)<a:r>[\s\S]*?<a:t>\/<\/a:t>[\s\S]*?<\/a:r>/g,
      (_whole, field) => {
        removed += 1;
        return field;
      },
    );
    if (patched !== xml) zip.file(name, patched);
  }

  fs.writeFileSync(output, await zip.generateAsync({
    type: 'nodebuffer',
    compression: 'DEFLATE',
  }));
  console.log(`Removed ${removed} slide-number slash run(s) from ${output}`);
}

main().catch((error) => {
  console.error(error.stack || error.message || error);
  process.exit(1);
});
