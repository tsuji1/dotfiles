#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const [, , inputPath, outputPath = inputPath, jszipPath] = process.argv;
if (!inputPath) {
  console.error('Usage: node strip-master-slide-number.cjs input.pptx [output.pptx] [jszip-module-path]');
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
  const name = 'ppt/slideMasters/slideMaster1.xml';
  const entry = zip.file(name);
  if (!entry) throw new Error(`Missing ${name}`);
  const xml = await entry.async('string');
  let removed = 0;
  const patched = xml.replace(/<p:sp>[\s\S]*?<\/p:sp>/g, (block) => {
    if (!block.includes('type="slidenum"')) return block;
    removed += 1;
    return '';
  });
  if (removed !== 1) {
    throw new Error(`Expected one master slide-number shape, removed ${removed}`);
  }
  zip.file(name, patched);
  fs.writeFileSync(output, await zip.generateAsync({
    type: 'nodebuffer',
    compression: 'DEFLATE',
  }));
  console.log(`Removed ${removed} master slide-number shape from ${output}`);
}

main().catch((error) => {
  console.error(error.stack || error.message || error);
  process.exit(1);
});
