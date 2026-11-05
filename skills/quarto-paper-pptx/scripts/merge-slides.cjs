#!/usr/bin/env node

// Legacy fallback only. Prefer one direct dom-to-pptx export for normal builds.
// When separate slide packages must be merged, slide-local media is copied and
// namespaced here so that relationships from different packages do not collide.

const fs = require('fs');
const path = require('path');

const [, , slideDirArg = 'ship.export-slides', outputArg = 'ship.dom-to-pptx.pptx', jszipPath] = process.argv;
const slideDir = path.resolve(slideDirArg);
const output = path.resolve(outputArg);

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

function maxRelationshipId(xml) {
  return Math.max(0, ...[...xml.matchAll(/Id="rId(\d+)"/g)].map((match) => Number(match[1])));
}

function addContentTypeOverride(xml, partName, contentType) {
  if (xml.includes(`PartName="${partName}"`)) return xml;
  return xml.replace('</Types>', `<Override PartName="${partName}" ContentType="${contentType}"/></Types>`);
}

function addMediaContentType(xml, extension, contentType) {
  const escapedExtension = extension.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  if (new RegExp(`<Default\\s+Extension="${escapedExtension}"\\b`).test(xml)) return xml;
  return xml.replace('</Types>', `<Default Extension="${extension}" ContentType="${contentType}"/></Types>`);
}

function mediaContentTypeFromSource(sourceContentTypes, extension) {
  const escapedExtension = extension.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const match = sourceContentTypes.match(
    new RegExp(`<Default\\s+Extension="${escapedExtension}"\\s+ContentType="([^"]+)"\\s*/?>`),
  );
  if (match) return match[1];
  const known = {
    png: 'image/png',
    jpg: 'image/jpeg',
    jpeg: 'image/jpeg',
    gif: 'image/gif',
    svg: 'image/svg+xml',
  };
  return known[extension.toLowerCase()] || null;
}

async function copySlideMedia(sourceZip, targetZip, targetNumber, contentTypes) {
  const sourceContentTypes = await sourceZip.file('[Content_Types].xml').async('string');
  const mediaNames = Object.keys(sourceZip.files)
    .filter((name) => /^ppt\/media\/[^/]+$/.test(name) && !sourceZip.files[name].dir);
  const mediaMap = new Map();
  for (const sourceName of mediaNames) {
    const basename = path.posix.basename(sourceName);
    const targetBasename = `slide${targetNumber}-${basename}`;
    const targetName = `ppt/media/${targetBasename}`;
    targetZip.file(targetName, await sourceZip.file(sourceName).async('nodebuffer'));
    mediaMap.set(basename, targetBasename);
    const extension = path.posix.extname(basename).slice(1);
    const mediaType = mediaContentTypeFromSource(sourceContentTypes, extension);
    if (mediaType) contentTypes = addMediaContentType(contentTypes, extension, mediaType);
  }
  return { contentTypes, mediaMap };
}

function namespaceMediaRelationships(relsXml, mediaMap) {
  let result = relsXml;
  for (const [sourceBasename, targetBasename] of mediaMap.entries()) {
    result = result.replaceAll(`Target="../media/${sourceBasename}"`, `Target="../media/${targetBasename}"`);
  }
  return result;
}

async function copyNotesSlide(sourceZip, targetZip, targetNumber) {
  const sourceXml = sourceZip.file('ppt/notesSlides/notesSlide1.xml');
  const sourceRels = sourceZip.file('ppt/notesSlides/_rels/notesSlide1.xml.rels');
  if (!sourceXml || !sourceRels) return;
  targetZip.file(`ppt/notesSlides/notesSlide${targetNumber}.xml`, await sourceXml.async('nodebuffer'));
  const relsXml = await sourceRels.async('string');
  targetZip.file(
    `ppt/notesSlides/_rels/notesSlide${targetNumber}.xml.rels`,
    relsXml.replace('Target="../slides/slide1.xml"', `Target="../slides/slide${targetNumber}.xml"`),
  );
}

async function main() {
  const JSZip = loadJSZip();
  const slideInputs = fs.readdirSync(slideDir)
    .filter((name) => /^slide-\d+\.pptx$/.test(name))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
  if (slideInputs.length === 0) throw new Error(`No slide PPTX inputs found in ${slideDir}`);

  const pptxInputs = slideInputs.map((name) => path.join(slideDir, name));
  const baseZip = await JSZip.loadAsync(fs.readFileSync(pptxInputs[0]));
  let presentationXml = await baseZip.file('ppt/presentation.xml').async('string');
  let presentationRels = await baseZip.file('ppt/_rels/presentation.xml.rels').async('string');
  let contentTypes = await baseZip.file('[Content_Types].xml').async('string');
  let nextSlideId = Math.max(255, ...[...presentationXml.matchAll(/<p:sldId\b[^>]*id="(\d+)"/g)].map((m) => Number(m[1])));
  let nextRelId = maxRelationshipId(presentationRels);

  for (let index = 1; index < pptxInputs.length; index += 1) {
    const slideNumber = index + 1;
    const sourceZip = await JSZip.loadAsync(fs.readFileSync(pptxInputs[index]));
    const slideXml = await sourceZip.file('ppt/slides/slide1.xml').async('nodebuffer');
    let relsXml = await sourceZip.file('ppt/slides/_rels/slide1.xml.rels').async('string');
    const copiedMedia = await copySlideMedia(sourceZip, baseZip, slideNumber, contentTypes);
    contentTypes = copiedMedia.contentTypes;
    relsXml = namespaceMediaRelationships(relsXml, copiedMedia.mediaMap);
    baseZip.file(`ppt/slides/slide${slideNumber}.xml`, slideXml);
    baseZip.file(
      `ppt/slides/_rels/slide${slideNumber}.xml.rels`,
      relsXml.replace('Target="../notesSlides/notesSlide1.xml"', `Target="../notesSlides/notesSlide${slideNumber}.xml"`),
    );
    await copyNotesSlide(sourceZip, baseZip, slideNumber);
    contentTypes = addContentTypeOverride(
      contentTypes,
      `/ppt/notesSlides/notesSlide${slideNumber}.xml`,
      'application/vnd.openxmlformats-officedocument.presentationml.notesSlide+xml',
    );
    nextSlideId += 1;
    nextRelId += 1;
    const slideRelId = `rId${nextRelId}`;
    presentationXml = presentationXml.replace('</p:sldIdLst>', `<p:sldId id="${nextSlideId}" r:id="${slideRelId}"/></p:sldIdLst>`);
    presentationRels = presentationRels.replace(
      '</Relationships>',
      `<Relationship Id="${slideRelId}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide${slideNumber}.xml"/></Relationships>`,
    );
    contentTypes = contentTypes.replace(
      '</Types>',
      `<Override PartName="/ppt/slides/slide${slideNumber}.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/></Types>`,
    );
  }

  baseZip.file('ppt/presentation.xml', presentationXml);
  baseZip.file('ppt/_rels/presentation.xml.rels', presentationRels);
  baseZip.file('[Content_Types].xml', contentTypes);
  fs.writeFileSync(output, await baseZip.generateAsync({ type: 'nodebuffer', compression: 'DEFLATE' }));
  console.log(`Merged ${slideInputs.length} slide PPTX parts: ${output}`);
}

main().catch((error) => {
  console.error(error.stack || error.message || error);
  process.exit(1);
});
