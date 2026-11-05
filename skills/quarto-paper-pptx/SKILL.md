---
name: quarto-paper-pptx
description: Create and iteratively revise editable Japanese paper-explanation PPTX decks from GitHub-linked papers using Quarto and dom-to-pptx.
---

# Quarto Paper PPTX

Use this skill when the user asks for paper-explanation slides, a PPTX built from a GitHub issue or paper, or repeated revisions to an existing Quarto/dom-to-pptx deck under `/home/yuzugon/slides`. It is intentionally specific to editable Japanese decks; use another workflow for image-only presentations or unrelated documents.

## Desired outcome

- Keep the `.qmd`, CSS, helper scripts, and final `.pptx` together in a dated deck directory: `/home/yuzugon/slides/YYYYMMDD/<slug>/`.
- Keep diagrams as editable HTML/CSS-derived PowerPoint shapes and text whenever possible. Do not rasterize diagrams merely to avoid layout work.
- Deliver one primary PPTX and, when useful, one PDF preview. Avoid producing a page of separate preview-image downloads.
- At handoff, keep only the final primary PPTX directly in the dated deck directory. Move intermediate PPTX files, per-slide exports, generated render files, and inspection artifacts under `tmp/` (for example `tmp/pptx/`, `tmp/render/`, and `tmp/preview-checks/`); keep a retained PDF preview under `preview/`.
- For a multi-topic research deck, keep each topic in its own ordered section folder (for example `00-intro`, `01-paper-a`, `02-paper-b`, `03-paper-c`, `04-power`) and assemble the final deck from those section outputs. Build and preview sections independently; merge them only with the maintained media-aware section merger, then apply the shared template once.
- Use a single direct `dom-to-pptx` export for each section when possible. A single-topic deck may still use one direct export for the whole deck.
- Make every later change happen in the `.qmd`/CSS source, followed by a rebuild and verification; do not make an untracked one-off edit only inside the binary PPTX.
- When the user requests an upload, treat it as part of the deliverable: after the final PPTX/PDF passes validation, upload only those final artifacts to the requested GitHub repository/issue, post stable links there, and record the upload location in the handoff. Do not upload intermediate PPTX files, per-slide exports, preview PNGs, or temporary build files.

## Source review

When a GitHub issue, repository, or URL is supplied, use `gh` first. Read the issue body, comments, labels, and linked paper metadata; comments can contain important caveats or research implications. Cross-check quantitative claims against the paper's arXiv/journal primary source. Separate paper results, interpretation, and any connection to the user's own research.

Preserve paper-specific technical terms instead of translating them away. Keep terms such as `FIB`, `cacheable FIB`, `prefix`, `hole filling`, `cache hiding`, `LRU`/`LFU`, `Line Card`, `Packet Queuing Emulator`, `trace-driven emulation`, `RouteViews`, `RIB`, and `NTP reflection attack` in the visible deck; add a short Japanese explanation alongside them when the audience needs it.

For synthetic datasets, state how they were generated and what they do not reproduce. Do not describe a non-random or transformed benchmark as a generic random workload.

## Research-introduction content

For a research-introduction deck, include the publication context near the beginning:

- when and where it was presented (conference/event, date or year, and city/country when available);
- who presented it and their affiliation;
- one compact method summary and one compact result summary before the detailed slides.

Keep this information concise and audience-facing. Do not expose workflow metadata such as GitHub issue numbers, extraction-tool names, temporary asset directories, or internal build notes in the visible deck. Preserve provenance in source comments, asset README files, or the final reference slide only when it is useful to the audience.

## Evaluation methodology review

For lookup papers, make the evaluation input explicit rather than calling it a “trace” without qualification:

- Distinguish FIB/prefix-table snapshots from packet traces. If the paper does not use destination-packet sequences, say so explicitly; do not imply traffic popularity, temporal locality, hit rate, or conflict behavior was measured.
- If the paper provides a trace-statistics table, include the complete inventory (for example, `T1`–`T9`) with the paper's identifiers and key fields such as date, duration, link rate, and packet count; do not summarize the table only as “nine traces.”
- Preserve the trace table's original research labels (`Trace`, `Date`, `Time`, `Link`, `No. packets`) when they are useful for matching the paper, while explaining the meaning in Japanese nearby.
- Record the source and scale of real tables (for example, route-collector snapshots), and for synthetic tables record the generator, mapping, size sweep, and which prefix-side characteristics are preserved.
- Define how each metric is constructed. For memory accesses, state whether parallel engines report a sum, average, or worst-case maximum; for memory, state the denominator and unit (for example, bytes/byte of prefix versus bytes/prefix).
- State hardware assumptions used to convert accesses into latency, such as memory frequency, bus width, node size, and whether the reported value is a worst case.
- Put the data-generation caveat beside the evaluation results, not only in references, when the synthetic input cannot reproduce traffic-side behavior.

## Authoring and revision loop

1. Read the Quarto × dom-to-pptx section in `/home/yuzugon/slides/README.md` and inspect the existing template/CSS before authoring. The demo's `HOW-TO.md` is only a compatibility pointer; locate the current demo path rather than assuming a date if the path changes.
2. Treat the shared `/home/yuzugon/slides/template.pptx`, the demo's `template-css-kit/theme.css`, and `template-css-kit/layouts.css` as the global template sources. The PPTX supplies the master/theme/layout package; the CSS kit supplies the editable HTML geometry. Copy the CSS kit into the dated deck, and keep paper-specific diagrams and spacing in the deck's `export.css`. If a template-level fix is discovered, update the shared source first and then refresh deck copies so future decks inherit it.
3. For a multi-topic research deck, create ordered section folders such as `00-intro`, `01-paper-a`, `02-paper-b`, `03-paper-c`, and `04-power`. Only `00-intro` may use the large cover/title treatment; later sections start with ordinary slide headers and do not add another large chapter-title slide. Keep each section's `.qmd`, CSS, prepared HTML, per-slide PPTX parts, and preview together. Create or update the dated deck directory around these sections, preserve user edits in dirty worktrees, and reuse an existing `.qmd`/CSS structure when revising.
4. Use short slide titles, one claim per visual area, and native HTML/CSS diagrams. Keep labels from wrapping across arrows or nodes; use explicit `white-space: nowrap` only for labels where wrapping would change meaning. In Quarto heading attributes, write every class with a leading dot (for example, `{.layout-text-image .image-wide .partition-slide}`); otherwise the intended geometry classes may remain in the heading text and never reach the `<section>`.
5. For mixed text-and-figure slides, reserve the two regions with explicit geometry (`position:absolute` plus fixed `left`/`width`, or an equivalently verified layout). Do not rely on a responsive grid alone when a figure will be injected into the PPTX after HTML export; verify that every text box ends before the figure box begins.
6. After every source or CSS change, rerender Quarto and rerun the export preparation step. Export from the fresh prepared HTML; never mix stale output from an earlier source revision.
7. Use a bounded direct export for each section with a selector such as `.reveal .slides > section`. For a multi-topic deck, create the section-local one-slide PPTX packages with `scripts/export-slides.cjs`, then merge the ordered section directories with `scripts/merge-section-slides.cjs`. The headless Chrome step can still hang intermittently, so inspect the exact converter PID and simplify the problematic DOM/CSS when needed.
8. Patch the merged direct PPTX, then always apply the shared `/home/yuzugon/slides/template.pptx` as the final packaging step unless the user explicitly selects another template. Apply the template once, after section merging; do not template-package each section separately. After template application, rerun the OOXML relationship checks and remove any duplicate template-master slide-number shape when using a slide-level footer. See [references/rebuild-workflow.md](references/rebuild-workflow.md).
9. Keep a visible footer on every slide as `<footer class="slide-footer"><span class="slide-number">N/</span></footer>` so the demo patcher recognizes it. Run the supplied `patch-pptx.cjs` so the `N` becomes an OOXML `a:fld type="slidenum"` field, then run `scripts/remove-slide-number-slash.cjs` when the user wants the current page only. Do not add `/total` unless the user asks for it. Do not rely on a template-master number alone: some viewers hide that shape.
10. Run PDF conversion and inspect the cover, dense text slides, diagram-heavy slides, results, and references. Check both visual spacing and editable-PPTX invariants. For a sectioned deck, confirm that the final slide count equals the sum of section slide counts and that only the first section contains the large cover/title treatment.

## Design and color discipline

- Keep the base palette restrained: white or light gray backgrounds, dark gray text, and thin neutral borders.
- Use red only for the important point: a warning, bottleneck, conclusion, failure, or decision that the audience must notice.
- Use blue sparingly for supporting structure: section headers, secondary emphasis, stable reference paths, or a calm comparison baseline.
- Make the shared theme and `template.pptx` agree on the same blue/red semantic palette; keep legacy orange/teal/purple/green aliases mapped to blue rather than introducing additional saturated colors.
- Do not assign a different saturated color to every component. Teal, orange, and other accents are optional and should appear only when they encode a real distinction; otherwise remove them.
- Preserve the same semantic color across the deck. Color should explain hierarchy, not decorate every box.
- Keep internal production details out of slide copy. Figure captions should explain the figure's meaning, not name the extraction pipeline.

For procedures or ordered explanations, use a real HTML `<ol>` with the shared ordered-list class so dom-to-pptx emits PowerPoint's native numbering. Do not draw numbered circles, insert circled digits, or hand-build number badges.

## Image and CSS conversion hazards

The dom-to-pptx exporter may convert CSS effects into auxiliary SVG/PNG images instead of native PowerPoint shapes. In particular, `border-left`, `border-top`, gradients, and pseudo-elements such as `::before` can produce relationships like `../media/image-*.png` or `image-*.svg` without a corresponding file in `ppt/media/`. This causes PowerPoint or another viewer to report that an image cannot be displayed. For the detailed relationship check and safer CSS forms, read [references/image-debugging.md](references/image-debugging.md).

Prefer real child elements with flat backgrounds for visual accents:

```html
<div class="box"><div class="accent-bar"></div><div class="box-content">...</div></div>
```

Use `.accent-bar` as an ordinary positioned rectangle. Replace gradients with several flat `div` segments. Avoid pseudo-elements for essential visual information. After export, compare every image relationship target in `ppt/slides/_rels/*.rels` with the actual `ppt/media/*` entries. If a relationship is dangling, fix the CSS/exporter before handing off the deck; a successful PDF render does not prove that the PPTX is healthy or editable.

## Figures, charts, and paper images

Support paper figures as real PPTX pictures while keeping surrounding captions, labels, and callouts editable. Choose the representation deliberately:

- Recreate simple diagrams, flowcharts, and bar/line charts with HTML/CSS or native DOM elements when the audience may need to edit individual components.
- Use the original figure as an embedded image when fidelity matters more than editability. Keep the source asset in the dated deck directory, together with its provenance and caption.
- For a figure that contains several panels, prefer one complete image plus an editable caption unless individual panels need to be discussed separately. If panels are cropped, preserve the original aspect ratio and record the crop in the source.

The basic source form is:

```html
<figure class="figure-frame" aria-label="Prefix length distribution">
  <img class="figure" src="assets/prefix-length-distribution.png" alt="Prefix length distribution">
  <figcaption>Figure 3. Prefix length distribution.</figcaption>
</figure>
```

Use `embed-resources: true` in the Quarto format when the direct exporter can process the image safely. In the current demo environment, `dom-to-pptx` 2.1.1 can wait indefinitely on `<img>` in some runs. For that case, put only a fixed-size placeholder in the DOM, export the slide geometry, and inject the image afterward as an OOXML `p:pic` with a slide relationship. The demo's `scripts/add-images.cjs` is the reference implementation; copy it into the dated deck and replace its slide coordinates/options with deck-specific figure specs.

```html
<div class="figure-frame">
  <div class="figure-slot" aria-label="Prefix length distribution"></div>
  <div class="figure-caption">Figure 3. Prefix length distribution.</div>
</div>
```

```bash
node "$DEMO_ROOT/scripts/add-images.cjs" \
  "$DECK_DIR/$STEM.dom-to-pptx.patched.pptx" \
  "$DECK_DIR/$STEM.figures.pptx" \
  --figure-slide 5 \
  --image "$DECK_DIR/assets/prefix-length-distribution.png"
```

For maximum PowerPoint compatibility, prefer PNG for raster figures and charts. Use SVG only when the target PowerPoint version has been tested; if it reports that an image cannot be displayed, convert the SVG media to PNG and update the corresponding relationship and content type. Do not expect an imported figure to become editable chart data: an injected image is editable as a picture, while only a DOM/native-shape reconstruction is editable component by component.

Always give the figure a bounded frame, explicit `width`/`height`, and `object-fit: contain` or an equivalent aspect-ratio rule. Do not stretch a scientific plot. Render raster assets at least 2× their displayed pixel size when text inside the figure must remain legible, and inspect the exported slide at 100% zoom. Keep the caption outside the bitmap so it remains searchable and editable.

## MathJax and SVG compatibility

When a deck contains LaTeX, use MathJax to pre-render the equations. The normal pipeline is Markdown/HTML → MathJax SVG → `dom-to-pptx`; the result is a visual equation, not a native PowerPoint equation object.

- Raw MathJax SVG in the live DOM can make headless export hang. Prefer a fixed-size, empty math placeholder during layout, then inject the rendered equation asset after the slide geometry is known.
- If PowerPoint rejects the result or reports that an image cannot be displayed, convert SVG media in the final PPTX to PNG and repair each slide relationship. A filename-only `.svg` → `.png` replacement is invalid when the slide still contains `asvg:svgBlip`: rewrite the high-resolution fallback as a normal `a:blip`, remove the obsolete low-resolution/SVG relationship, and delete stale `/ppt/media/*.svg` content-type overrides. Keep the original MathJax source alongside the deck so equations remain reproducible.
- If equations were injected as ordinary SVG pictures after the DOM export, rasterize all SVG media first, then run the relationship repair helper; otherwise the SVG files may remain referenced without a valid PowerPoint content type even when no `asvg:svgBlip` remains.
- Render MathJax assets at 4× or higher device scale when they are inserted as PNG pictures. A 1× or 2× equation stretched across several inches becomes visibly coarse; the final PPTX should use the high-resolution asset and should not retain a PNG relationship pretending to be an SVG.
- A direct multi-slide export is especially useful here because all media and relationships are created in one package. Check every `../media/...` target after equation injection and again after template application.
- Do not claim that equations are editable PowerPoint math unless the deck uses a separate OMML insertion workflow.

## Verification invariants

- The final PPTX passes `unzip -t`.
- The number of `ppt/slides/slide*.xml` parts equals the intended slide count, and every prepared HTML has a corresponding slide part.
- The direct export and the final template-applied PPTX each contain one coherent slide/media relationship graph; every image target in `ppt/slides/_rels/*.rels` exists under `ppt/media/`.
- After template application, keep one template-owned slide master and only its referenced layouts/themes. Remove generated master/theme copies; stale duplicates can trigger PowerPoint repair and change the apparent header width.
- If figures were injected after export, each intended figure has a corresponding `p:pic`, image relationship, media ZIP entry, and content-type declaration; the caption remains in the slide XML as editable text.
- For every mixed text-and-figure slide, inspect the rendered PDF at 100% and confirm that the maximum text-box right edge is smaller than the figure's left edge; a valid PDF alone does not prove that the visual regions are separated.
- With the custom footer strategy, each slide XML contains exactly one `type="slidenum"` field and the copied master contains zero. This prevents both missing footers and duplicate `1/1/`-style output.
- A PDF conversion has the expected page count and shows current-page footers such as `1`, `2`, and the last page number when the total is intentionally hidden.
- There are no accidental external image references. If images are genuinely needed, embed them and verify their relationship targets; otherwise keep the deck shape/text-only.

## Download and handoff

If the interface reports that images cannot be displayed or that automatic downloads were blocked, treat that as a preview/multiple-download issue first. Hand off the single PPTX/PDF artifact rather than asking the user to download every PNG. In Chrome, the per-site setting is under `chrome://settings/content/automaticDownloads`; prefer allowing only the current site rather than globally allowing all sites.

For a requested GitHub upload, use a dedicated artifact path or branch when practical, link the final PPTX and PDF from the issue, and verify both links after posting. Keep the source deck and intermediate files local unless the user explicitly asks to upload them too.

## When the converter appears broken

First retry the bounded direct full-deck export and inspect the exact HTML/CSS that triggers the hang. Use the per-slide retry helper only to isolate the failing section; do not merge its outputs into a final deck without a media-aware merge implementation and a complete relationship audit. Clone or patch the demo implementation only when a deterministic minimal input reproduces a real code defect or the user explicitly asks for an upstream fix. A transient Chrome wait is not evidence that the paper content or CSS is broken.
