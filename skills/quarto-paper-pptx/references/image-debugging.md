# Image and CSS export debugging

Read this reference when the viewer reports “this image cannot be displayed”, PowerPoint asks to repair the file, or the exported deck contains unexpected `Picture` objects.

## First determine whether the source contains images

```bash
rg -n '<img|<svg|url\(' "$DECK_DIR/$STEM.export.html" || true
unzip -l "$DECK_DIR/$STEM.template.pptx" | rg 'ppt/media|image-[0-9]+' || true
```

If the HTML has no image tags but the PPTX has many pictures, the exporter likely rasterized CSS rather than importing a source image.

## Figure insertion workflow

For a paper figure or chart, first decide whether the figure should be editable as individual elements. Recreate simple plots and diagrams with DOM/CSS when component editing matters. For a complex source figure, use a real `<figure>`/`<img>` for the HTML preview or a fixed-size placeholder followed by OOXML picture injection when the exporter is unstable.

```html
<figure class="figure-frame">
  <div class="figure-slot" aria-label="System overview figure"></div>
  <figcaption>Figure 2. System overview.</figcaption>
</figure>
```

The placeholder keeps the layout and caption in the normal export. A deck-local image helper should then:

1. add the asset under `ppt/media/`;
2. add the image content type to `[Content_Types].xml`;
3. add an image relationship to the target slide's `.rels` file; and
4. append a `p:pic` with explicit EMU coordinates to the slide shape tree.

The demo's `/home/yuzugon/slides/20260907/dom-to-pptx-quarto-demo/scripts/add-images.cjs` implements this pattern. Copy it into the deck when `<img>` causes a headless-export hang; do not rely on a browser preview alone.

For figure assets, use stable names such as `figure-02-overview.png`, keep the source and license/citation beside the deck, and put captions/annotations in editable HTML rather than baking them into the bitmap where possible. Use PNG for broad PowerPoint compatibility; preserve SVG only after testing the actual target viewer.

## Check for dangling relationships

```bash
unzip -l "$DECK_DIR/$STEM.template.pptx" | rg 'ppt/slides/_rels|ppt/media'
CHECK_DIR=$(mktemp -d)
unzip -q "$DECK_DIR/$STEM.template.pptx" -d "$CHECK_DIR"
for rels in "$CHECK_DIR"/ppt/slides/_rels/*.rels; do
  rg -o 'Target="\.\./media/[^"]+"' "$rels" || true
done
rm -rf "$CHECK_DIR"
```

A relationship target such as `../media/image-1-1.png` must have a matching `ppt/media/image-1-1.png` ZIP entry. A relationship without a ZIP entry is a broken PPTX even if LibreOffice happens to render a preview.

Also inspect the SVG fallback extension when a converter has rasterized images:

```bash
unzip -p "$DECK_DIR/$STEM.template.pptx" ppt/slides/slide3.xml \
  | rg 'asvg:svgBlip|a:blip'
unzip -p "$DECK_DIR/$STEM.template.pptx" '[Content_Types].xml' \
  | rg 'svg|ppt/media'
```

`asvg:svgBlip` must target an actual SVG part. If the package contains only PNG media, remove the `asvg:svgBlip` extension and use the high-resolution PNG relationship as the ordinary `a:blip`; remove stale `/ppt/media/*.svg` content-type overrides as well. Merely renaming the relationship target from `.svg` to `.png` leaves an invalid OOXML package and commonly triggers PowerPoint's repair dialog.

## Safer authoring forms

Use flat, real DOM rectangles for essential accents:

```html
<div class="callout">
  <div class="accent-bar"></div>
  <div class="callout-content">Important claim</div>
</div>
```

```css
.callout { position: relative; background: #f1f1f1; }
.accent-bar { position: absolute; inset: 0 auto 0 0; width: 6px; background: #c23b3b; }
.callout-content { margin-left: 18px; }
```

For density or distribution visuals, use several flat segment `div`s instead of `linear-gradient` or `repeating-linear-gradient`. Avoid `::before`/`::after` for information that must survive conversion. A `border-left` or `border-top` may be acceptable only after checking the generated relationships; if it becomes a missing image, replace it with an explicit child rectangle.

## When to inspect the exporter

If a minimal HTML fixture with one border or gradient deterministically creates a dangling `ppt/media` relationship, inspect the dom-to-pptx CSS-to-SVG/PNG path. Look for an un-awaited Promise or a mismatch between generated image data and the ZIP/image relationship registration. Clone and patch the demo only for a reproducible implementation defect; otherwise prefer the native-DOM workaround and record the limitation in the deck notes.
