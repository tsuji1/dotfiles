---
name: marp-japanese-pptx
description: Create editable Japanese PPTX slide decks using the local Marp-compatible Markdown workflow. Use when the user asks to make or rebuild slides/PPTX with the previous method, Marp, Markdown source, Japanese font correction, or editable PPTX under /home/yuzugon/slides.
---

# Marp Japanese PPTX

## Workflow

Use the local Marp workflow, not `python-pptx`, when the user asks for the previous slide method.

1. Create a dated deck directory under `/home/yuzugon/slides/YYYYMMDD/` unless the user specifies another location.
2. Write a Marp-compatible `.md` source deck with front matter:
   - `marp: true`
   - `theme: default`
   - `paginate: false`
   - `size: 16:9`
   - `lang: ja-JP`
   - a `style` block that loads `/mnt/c/Windows/Fonts/YuGothM.ttc` as `Yu Gothic Medium` and uses `Noto Sans CJK JP` fallback.
   - when `/home/yuzugon/slides/template.pptx` exists and its actual master slides can be applied, use that template. If Marp cannot apply the master slides directly, do not approximate them with background colors or decorative bars; keep the slide background white.
3. Keep slide text concise and presentation-ready. Put source report paths in an HTML comment near the top.
4. Do not use Marp pagination; PowerPoint/template handling adds page numbers separately when needed.
5. Do not use Markdown backtick formatting in Marp slide sources. Avoid inline code spans and fenced code blocks in visible slide content; write identifiers as plain text instead.
6. Render with Marp:

```bash
cd /home/yuzugon
marp --allow-local-files \
  --browser-path /usr/bin/google-chrome \
  --pptx --pptx-editable slides/YYYYMMDD/deck-name.md \
  -o slides/YYYYMMDD/deck-name.pptx
```

7. Run the bundled Japanese PPTX normalizer:

```bash
python3 /home/yuzugon/.codex/skills/marp-japanese-pptx/scripts/fix_pptx_japanese.py \
  slides/YYYYMMDD/deck-name.pptx
```

8. Verify the output:

```bash
ls -lh slides/YYYYMMDD/deck-name.pptx
unzip -l slides/YYYYMMDD/deck-name.pptx | rg "ppt/slides/slide[0-9]+\\.xml" | wc -l
unzip -p slides/YYYYMMDD/deck-name.pptx ppt/slides/slide1.xml | rg "lang=\"ja-JP\"|Yu Gothic Medium|Noto Sans CJK JP" | head
```

## Marp Front Matter Template

```markdown
---
marp: true
theme: default
paginate: false
size: 16:9
title: Deck title
lang: ja-JP
math: katex
style: |
  @font-face {
    font-family: "Yu Gothic Medium";
    src: url("file:///mnt/c/Windows/Fonts/YuGothM.ttc");
    font-weight: 500;
  }
  section {
    font-family: "Yu Gothic Medium", "Yu Gothic", "Noto Sans CJK JP", "Meiryo", sans-serif;
    font-weight: 500;
    letter-spacing: 0;
  }
  code, pre {
    font-family: "Noto Sans Mono CJK JP", "Ubuntu Sans Mono", "DejaVu Sans Mono", monospace;
  }
  table {
    font-size: 24px;
  }
---
```

## Notes

- Use `--allow-local-files` for local images/assets.
- Use `--pptx-editable` so PowerPoint can edit text and shapes.
- Use `paginate: false`; do not emit Marp page numbers.
- Do not use backticks in Marp slide source visible text.
- If a PowerPoint template master cannot be applied directly through Marp, keep a plain white slide background instead of recreating the template with CSS background colors.
- If Marp/Chrome is blocked by sandboxing, rerun the same Marp command with escalation.
- Do not call this workflow `markitdown`; the local previous method is Marp Markdown to PPTX.
- Keep generated `.md` sources next to `.pptx` files so decks can be regenerated.
