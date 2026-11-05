---
name: research-tex
description: PPC キャッシュ研究（MPLC・VPLC）のゼミのレジュメ・修論・論文を LaTeX で書く・直すときの注意点。ビルド（LuaLaTeX・latexmk・biber）、学術的な文章の書き方、図表とキャプション、参考文献の書式を決めるとき、書いた文書を読み返すときに使う。
---

# 研究の LaTeX 文書（レジュメ・論文）を書くときの注意

正本は `research-routing-table-cache` main の `docs/guidelines/tex.md`。**書く・直す前に必ず正本を読む**（下の要点は抜粋で、食い違ったら正本に従う）。

```bash
repo=~/research-routing-table-cache; [ -d "$repo" ] || repo=~/yuzugon/research-routing-table-cache  # banana
git -C "$repo" fetch -q origin main && git -C "$repo" show origin/main:docs/guidelines/tex.md
```

文書に入れるグラフは skill `research-figures` にも従う。

## 要点

- **ビルド**: LuaLaTeX（`ltjsarticle`、`luatexja-fontspec`、IPAex）＋ latexmk・biber。例は `slides/semi/all/20261016/` の `latexmkrc`・`build-resume.sh`。ビルドもスクリプトにして記録できるようにする。
- **書いたあと**: 必ず全体を読み返し、矛盾と表記ゆれ（方式名、用語、単位、数字、送り仮名）を無くす。
- **文章**: 学術的に書く（「〜たり」「なので」「すごく」を使わない）。「という XX」を避ける。曖昧な語は数値にする。パーセントとポイントを区別する。複数条件の実験を「変化させて」と書かない。過去の予測ではなく測定結果を書く。段落は字下げ。箇条書きの前に一言入れ、句点の有無を統一。subsection が 1 つなら分けない。
- **図表**: 図はベクタ（PDF）。キャプションは図の下・表の上、配置は `[t]`。すべて `\cref` で本文から参照し、参照順に並べる。キャプションに比較の条件を書く。図は入れる幅で作り（`\the\linewidth` で確かめる）、文字の大きさとフォントを本文に合わせる。白黒でも区別できるようにする。表は `siunitx` で小数点をそろえ、`booktabs` で罫線を最小限に（縦線なし）。`\includegraphics` の近くに `%` で Run ID と commit を書く。
- **参考文献**: 書式（著者、題目、誌名・会議名、巻・号、ページ、年）と略し方を統一。Web は URL と参照日。引用していない文献は並べない。
- **名前**: 方式名・trace 名・private trace の扱いは `research-figures` と同じ。

## 修士論文

修論は repo `tsuji1/tsuji-MastersThesis`（private、ローカル `~/tsuji-MastersThesis`）。管理は research-routing-table-cache の [#126](https://github.com/tsuji1/research-routing-table-cache/issues/126)。

- main に push すると CI が PDF をビルドし、Release `latest` と #126 に載せる。ローカルでビルドしなくてよい。
- 図は repo に PDF で commit する（Cloud LaTeX で repo だけでビルドできるように。svg は使わない）。
- 新しい図は research-routing-table-cache 側で `researchctl run` で作り、修論 repo の `figures/SOURCES.tsv` に Run ID と run 内のパスを書いて `scripts/fetch-figures.sh` で取り込む。手で cp しない。`\includegraphics` の近くに `% run: RUN_ID / script: repo@commit:path` を書く。`scripts/fetch-figures.sh --check` で元の run と一致するか確かめる。
- 卒論の図は `figures/legacy/`（run の記録なし）。本文では `figures/legacy/...` と明示して参照し、作り直したら `figures/` の図に差し替える。棚卸しは `figures/legacy/INVENTORY.md`。
- 先生に原稿を渡すときは tag を打つ（例: `draft-2026-11-20`）。
