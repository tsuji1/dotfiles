---
name: research-slides
description: PPC キャッシュ研究（MPLC・VPLC）のゼミ・発表スライド（pptx）を作る・直すときの注意点。スライドの構成・文字の大きさ・フォント・配色・図の貼り方を決めるとき、既存の pptx を python-pptx や PowerPoint（COM）で直すとき・結合するときに使う。
---

# 研究のスライド（pptx）を作る・直すときの注意

正本は `research-routing-table-cache` main の `docs/guidelines/slides.md`。**作る・直す前に必ず正本を読む**（下の要点は抜粋で、食い違ったら正本に従う）。

```bash
repo=~/research-routing-table-cache; [ -d "$repo" ] || repo=~/yuzugon/research-routing-table-cache  # banana
git -C "$repo" fetch -q origin main && git -C "$repo" show origin/main:docs/guidelines/slides.md
```

スライドに貼るグラフは skill `research-figures` にも従う。

## 作り方

Marp・Quarto などの変換は使わず、pptx を直接扱う。

- **編集**: python-pptx のスクリプトを書く。デッキに合わせたフォント・色・表の書き方は、作業フォルダの `slidelib.py` のような共通モジュールにまとめ、スライドごとに書き直さない。
- **結合・非表示スライドの照合・見た目の確認**: Windows の PowerPoint 本体を pywin32（COM）で動かす。編集したスライドは画像に書き出して開き、文字のはみ出し・豆腐・18pt 未満が無いかを目で確かめる。
- **Issue の読み取り**: WSL の `gh`。

## 要点

- **ユーザが編集した pptx を上書きしない**: 直す前に PowerPoint で編集されたかを確かめる。編集済みなら生成スクリプトで作り直さず、直す文面を示すか、許可を得て該当箇所だけ書き換える（先に別名でバックアップ）。生成スクリプトの出力先はユーザのファイルと別名にする。
- **構成**: 1 スライド 1 分・1 スライド 1 メッセージ。先に枚数とストーリーを決める。見出しに結論を書く。時系列の章立てにせず、研究の目的と MPLC の課題に沿って並べる。ページ番号は「現在 / 全体」。
- **文字**: すべて 18pt 以上（図の中・注記・出典も）。灰色の小さい文字は使わない。Run ID と commit はノートに書く。ゴシック系（Noto Sans CJK JP、BIZ UD ゴシック、游ゴシック、メイリオ）を使い、MS ゴシック・HG・MS 明朝は使わない。英数字は欧文フォント。強調は太字から、3 つ以上重ねない。
- **レイアウトと配色**: 余白を取り、左端・上端をそろえる。背景は白、色は 4 色まで、強調色は最重要箇所だけ。PowerPoint の標準色を使わない。MPLC・VPLC の色はグラフとそろえる。図形は塗りか枠線のどちらかだけ。矢印・枠は控えめに。
- **図**: 16:9 に合う横長（2:1〜3:1）で、貼る大きさで作る（貼って縮めない）。差し替えは画像だけ入れ替えて位置と大きさを保つ。
- **内容**: 数値は run の出力から引き、Issue か artifact の表で確かめられるようにする。方式名・trace 名・private trace の扱いは `research-figures` と同じ。
