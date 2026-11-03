# Rebuild workflow

Use this reference when creating or revising a deck. Replace the example stem and paths with the current deck's values. Keep task-specific source files in the deck directory.

## Locate the tools

```bash
SLIDES_ROOT=/home/yuzugon/slides
DEMO_ROOT=/home/yuzugon/slides/20260907/dom-to-pptx-quarto-demo
DECK_DIR=/home/yuzugon/slides/YYYYMMDD/paper-slug
STEM=paper
QUARTO_BIN="$DEMO_ROOT/node_modules/@lillies/quarto/bin/quarto.js"
DOM_TO_PPTX="$DEMO_ROOT/node_modules/.bin/dom-to-pptx"
```

Read the Quarto × dom-to-pptx section in `$SLIDES_ROOT/README.md` before changing the pipeline. The demo's `HOW-TO.md` is only a compatibility pointer. If the demo has moved, find the nearest current copy under `$SLIDES_ROOT`.

## Sectioned research decks

For a deck that combines several research topics, keep the sources in ordered directories and build each section independently:

```text
YYYYMMDD/research-pack/
├── 00-intro/
├── 01-paper-a/
├── 02-paper-b/
├── 03-paper-c/
└── 04-power/
```

Only `00-intro` uses the large cover/title treatment. The other sections use ordinary slide headers, even when their first slide introduces a paper or topic. After each section has produced its `export-slides/slide-XX.pptx` files, merge in directory order:

```bash
node "$DEMO_ROOT/scripts/merge-section-slides.cjs" \
  "$DECK_DIR/$STEM.dom-to-pptx.pptx" \
  "$DECK_DIR/00-intro/$STEM.export-slides" \
  "$DECK_DIR/01-paper-a/$STEM.export-slides" \
  "$DECK_DIR/02-paper-b/$STEM.export-slides" \
  "$DECK_DIR/03-paper-c/$STEM.export-slides" \
  "$DECK_DIR/04-power/$STEM.export-slides"
```

The merger namespaces copied media/embedding parts and rewrites slide-local relationships. Patch the merged PPTX and apply `template.pptx` only after this step. Verify the final slide count against the sum of the section counts.

## Render and prepare

Run these after every `.qmd` or CSS change:

```bash
node "$QUARTO_BIN" render "$DECK_DIR/$STEM.qmd"
node "$DEMO_ROOT/scripts/prepare-export.cjs" \
  "$DECK_DIR/$STEM.html" "$DECK_DIR/$STEM.export.html"
```

The preparation step creates the exporter-ready HTML and preserves the top-level Reveal sections for direct multi-slide export. Always export from that fresh file.

## Direct export, patch, and template

```bash
node "$DOM_TO_PPTX" export \
  "$DECK_DIR/$STEM.export.html" \
  --inject --no-pseudo \
  --selector '.reveal .slides > section' \
  --width 13.333333 --height 7.5 \
  --browser-width 1280 --browser-height 720 \
  --title "$STEM" --author "Author" \
  --output "$DECK_DIR/$STEM.dom-to-pptx.pptx"

node "$DEMO_ROOT/scripts/patch-pptx.cjs" \
  "$DECK_DIR/$STEM.dom-to-pptx.pptx" \
  "$DECK_DIR/$STEM.dom-to-pptx.patched.pptx" 150

node "$DEMO_ROOT/scripts/apply-template.cjs" \
  "$DECK_DIR/$STEM.dom-to-pptx.patched.pptx" \
  "$SLIDES_ROOT/template.pptx" "$DECK_DIR/$STEM.template.pptx"

node /home/yuzugon/.codex/skills/quarto-paper-pptx/scripts/strip-master-slide-number.cjs \
  "$DECK_DIR/$STEM.template.pptx" "$DECK_DIR/$STEM.template.pptx" \
  "$DEMO_ROOT/node_modules/jszip"

node "$DEMO_ROOT/scripts/patch-pptx.cjs" \
  "$DECK_DIR/$STEM.template.pptx" "$DECK_DIR/$STEM.template.pptx" 150

node /home/yuzugon/.codex/skills/quarto-paper-pptx/scripts/remove-slide-number-slash.cjs \
  "$DECK_DIR/$STEM.template.pptx" "$DECK_DIR/$STEM.template.pptx" \
  "$DEMO_ROOT/node_modules/jszip"
```

For a single-topic deck, the direct export creates all sections in one PPTX and lets `dom-to-pptx` create one consistent media and relationship graph. For a multi-topic research deck, direct export remains the default within each section; `merge-section-slides.cjs` is the normal final assembly step. Applying a template is a separate step and happens once after the section merge.
The template application helper removes generated master/theme copies before copying the template parts. Verify that the result has one slide master and only the template's referenced layouts/themes; retaining stale generated masters can trigger PowerPoint repair and change the apparent header width.

Use `scripts/export-slides-retry.sh` only when a direct export hangs and you need to identify the offending section. Its output is diagnostic by default. For section assembly, use `scripts/merge-section-slides.cjs`; it copies and namespaces slide-local media parts and notes relationships, but still requires the complete relationship audit below.

If a figure must be inserted after layout, inject it before footer patching and template application:

```bash
node "$DEMO_ROOT/scripts/add-images.cjs" \
  "$DECK_DIR/$STEM.dom-to-pptx.pptx" \
  "$DECK_DIR/$STEM.with-figures.pptx" \
  --figure-slide 5 \
  --image "$DECK_DIR/assets/figure-02-overview.png"
```

Use `$STEM.with-figures.pptx` as the input to `patch-pptx.cjs` in the next step. For multiple figures, use a deck-local copy of `add-images.cjs` with an array of figure specifications rather than repeatedly overwriting the same PPTX. The injected picture must be checked for a matching `ppt/media/*` entry before applying the template.

When an SVG-to-PNG compatibility conversion was used, run the deck-local image repair helper before template application or footer patching:

```bash
node "$DECK_DIR/scripts/repair-pptx-images.cjs" \
  "$DECK_DIR/$STEM.dom-to-pptx.pptx" \
  "$DECK_DIR/$STEM.images-repaired.pptx" \
  "$DECK_DIR/tmp/render/math-png-assets-hi"
```

Use the repaired file as the next pipeline input. This removes invalid `asvg:svgBlip` entries and stale SVG content types while retaining the high-resolution PNG fallback.
If `inject-math-images.cjs` inserted MathJax SVGs as ordinary `a:blip` pictures, run the deck-local `replace-svg-with-png.cjs` before the repair helper. The safe order is: inject SVG equations → rasterize every SVG media part → repair relationships and replace MathJax PNGs at 4x → apply the template.

The final three steps are paired with the source footer form:

```html
<footer class="slide-footer"><span class="slide-number">1/</span></footer>
```

Use the matching current number on each slide. `patch-pptx.cjs` turns the number into a dynamic slide-number field. The master-strip helper removes the template's duplicate number shape, and `remove-slide-number-slash.cjs` removes the patcher's separator run, so the final file has one visible dynamic current-page footer with no total-page denominator.

## Verification

```bash
unzip -t "$DECK_DIR/$STEM.template.pptx"
slides=$(unzip -Z1 "$DECK_DIR/$STEM.template.pptx" \
  | rg '^ppt/slides/slide[0-9]+\.xml$' | wc -l)
prepared=$(rg -o '<section\b' "$DECK_DIR/$STEM.export.html" | wc -l)
test "$slides" -eq "$prepared"

for rel in $(unzip -Z1 "$DECK_DIR/$STEM.template.pptx" \
  | rg '^ppt/slides/_rels/slide[0-9]+\.xml\.rels$'); do
  while read -r media; do
    [ -z "$media" ] || unzip -Z1 "$DECK_DIR/$STEM.template.pptx" \
      | rg -q "^ppt/media/$media$"
  done < <(unzip -p "$DECK_DIR/$STEM.template.pptx" "$rel" \
    | rg -o 'Target="\.\./media/[^"]+"' \
    | sed 's/Target="\.\.\/media\///; s/"$//')
done

for i in 1 2 "$slides"; do
  unzip -p "$DECK_DIR/$STEM.template.pptx" "ppt/slides/slide${i}.xml" \
    | rg -o 'type="slidenum"' | wc -l
done

unzip -p "$DECK_DIR/$STEM.template.pptx" ppt/slideMasters/slideMaster1.xml \
  | rg -o 'type="slidenum"' | wc -l
```

The slide count must match the number of top-level sections; the three sample slide-number counts should be `1`; the master count should be `0` when using the custom-footer strategy. The relationship loop must complete without a missing media file. Run the same relationship check on the direct-export PPTX before applying the template. Also convert the final PPTX to one PDF and inspect the first, densest, result, and last slides. Do not use the PDF alone as proof that text is editable: the OOXML and the PowerPoint file must remain the handoff artifacts.

## Recovery from a hung export

```bash
ps -o pid,ppid,etime,stat,cmd -C node | rg 'dom-to-pptx|export-slides' || true
```

If the user interrupts a run, terminate only the exact stale `dom-to-pptx` PID, then rerun the direct export from the fresh prepared HTML. Use the retry helper for the affected slide only when isolating the failure; do not combine old slide parts with a newly prepared HTML directory.
