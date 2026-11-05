---
name: research-figures
description: PPC キャッシュ研究（MPLC・VPLC、research-routing-table-cache）のグラフを作る・直すときの注意点。Issue・Wiki・スライド・論文に載せる図を matplotlib などで描くとき、軸・色・凡例・trace の表示名・出力形式を決めるとき、既存の図を見直すときに使う。
---

# 研究のグラフを作るときの注意

正本は `research-routing-table-cache` main の `docs/guidelines/figures.md`。**描く前に必ず正本を読む**（下の要点は抜粋で、食い違ったら正本に従う）。

```bash
repo=~/research-routing-table-cache; [ -d "$repo" ] || repo=~/yuzugon/research-routing-table-cache  # banana
git -C "$repo" fetch -q origin main && git -C "$repo" show origin/main:docs/guidelines/figures.md
```

スライドに貼る図は skill `research-slides`、LaTeX に入れる図は skill `research-tex` も読む。色の選び方の詳細は skill `dataviz`。

## 要点

- **出どころ**: 図もスクリプトにして commit・push し、`researchctl run` で作る（skill `researchctl`）。入力は `run:RUN_ID/パス` で渡し、数値を手で書き写さない。図の近くに Run ID とスクリプトの commit 固定リンクを書く。
- **書かない**: 非匿名 trace の IP・プレフィクス。private trace の取得元の名前（Academic A / Academic B と書く）。
- **名前**: 方式名は MPLC・VPLC（旧称 MP・LTPC・PS・VIL は使わない）。trace の表示名と並び順はこれまでの図とそろえる。ラベル・凡例・注記は日本語。
- **軸**: 縦軸は基本 0 から（対数軸などで外すときは図から分かるように）。量と単位を書く（「ミス率 [%]」）。目盛り 3〜5 個、grid は控えめ。
- **条件を図に書く**: 総 entry 数、way 数、index、trace の本数、packet 数、電力モデルの前提。平均は算術か幾何か・何本か（比の平均は幾何平均）。除いた trace の本数。
- **見た目**: 初期設定のまま使わない。色は `#2a78d6`、`#eb6834`、`#1baf7a`、`#7a5ad6`（同じ方式は図をまたいで同じ色、4 色程度まで）。赤×緑を避ける。色だけでなく線種・マーカー・ハッチでも区別。凡例はなるべく直接書く。日本語フォントを明示し、豆腐が出ていないか画像を開いて確かめる。
- **出力**: PDF（ベクタ）と PNG（dpi 150 以上）を同じスクリプトから出す。出力は run の `--output` に。ユーザが手で直したファイルを上書きしない。
