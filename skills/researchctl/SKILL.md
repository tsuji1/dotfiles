---
name: researchctl
description: 研究の実験・集計・変換・図の作成を、git に push したスクリプトと researchctl run で実行・記録し、途中過程のデータを Run ID でたどるための手順。PPC キャッシュ研究（osada-ppc-simulator、ppc-result-viewer、research-routing-table-cache、banana での計算）でコマンドやスクリプトを実行するとき、過去の結果・中間ファイルを参照するとき、結果を Issue・Wiki・CHANGELOG に書くときに使う。
---

# researchctl で実験を実行・記録する

研究の作業では、AI が結果を書き写すのではなく、Runner（`researchctl`）が実行そのものを記録する。AI はその記録を読んで分析する。詳細は `research-routing-table-cache` の `tools/researchctl/README.md`。

## 守ること

- どんなに小さなスクリプト（集計 1 つ、図 1 枚、変換 1 回）も、ファイルにして git に commit・push してから `researchctl run` で実行する。
  - `python3 -c`、heredoc（`python3 - <<EOF`）、`bash -c` は Runner が拒否する。Claude Code では研究用ディレクトリでの直接実行（`python3 x.py`、`./x.sh`、`uv run`、`go run`）も hook が拒否する。拒否されても迂回しない。
  - 置き場所: 対象の repo の `scripts/`。使い捨ての集計は `research-routing-table-cache` の `scripts/`（work branch でよい。push は必要）。
- run directory（aloheart `~/research-runs/`、banana `~/yuzugon/research-runs/`）と台帳（`research-runs-ledger`）は変更しない。加工したいときは `researchctl export RUN_ID DEST` の写しか、次の run の入力にする。
- 失敗・中断した run も消さない。やり直しは新しい run。
- Issue・Wiki・CHANGELOG に書く数値には Run ID を付ける。Runner の自動 comment（実測値）と、AI の考察（別 comment）を混ぜない。
- 正式評価（論文・発表）は関係する repo を commit してから `--formal`。
- 重い計算は banana（`ssh banana 'cd ~/yuzugon/... && researchctl run ...'`）。

## グラフ・スライド・LaTeX を作る前に読む

`research-routing-table-cache` main の `docs/guidelines/` に注意点がある。作る前に該当する skill を使い、正本を読む。

- グラフ（Issue・Wiki・スライド・論文の図すべて）: skill `research-figures`（`docs/guidelines/figures.md`）
- スライド（pptx）: skill `research-slides`（`docs/guidelines/slides.md`）。ユーザが編集した pptx を生成スクリプトで上書きしない
- LaTeX の文書（レジュメ・論文）: skill `research-tex`（`docs/guidelines/tex.md`）

## 実行の流れ

```bash
# 1. スクリプトを書いて commit・push
git add scripts/summarize_hitrate.py && git commit -m "..." && git push

# 2. 実行（--issue で Issue に実測値の comment が付く）
researchctl run --issue 83 --name summarize-hitrate \
  --input ~/yuzugon/rules/rib.20250927.1500.unique.rule \
  --output out/hitrate.csv --metrics out/hitrate.csv \
  -- python3 scripts/summarize_hitrate.py --out out/hitrate.csv

# 3. 確認
researchctl show RUN_ID
```

複数 step は TOML（`[[steps]]`）に書いて git に入れ、`researchctl run experiments/x.toml`。

## 途中過程のデータ

run の中に次のものが残るので、どの段階のデータも後から参照できる。

| 何が | どこに |
|---|---|
| 各 step の stdout / stderr | `steps/NN-name/stdout.log`, `stderr.log` |
| 実行中に作られた・変わったファイル（各 step の cwd 以下を自動で比較） | `captured/<絶対パス>`、manifest の `captured`（new / modified / deleted、sha256） |
| スクリプトが `$RESEARCHCTL_OUT` に書いたファイル | `work/` |
| `--output` に指定した出力 | `outputs/<パス>` |
| argv に出てきた小さい設定（`.env` など） | `snapshot/` |
| 未コミット差分 | `git/<repo>.diff` |

- cwd 以外に書く場合は `--capture DIR` を付ける。cwd が大きすぎる（30 万ファイル超）と自動保存は止まり、警告が出る。
- 途中ファイルをスクリプトから確実に残したいときは、`os.environ["RESEARCHCTL_OUT"]` に書く。

## 前の run のデータを使う・たどる

```bash
# 前の run の出力を入力にする（run:RUN_ID/パス はこの host の run directory に置き換わる）
researchctl run --issue 83 --input run:20261027-012600-c82ff2/outputs/out/hitrate.csv \
  -- python3 scripts/plot_hitrate.py run:20261027-012600-c82ff2/outputs/out/hitrate.csv

researchctl path RUN_ID [outputs/...]   # パス（別 host の run なら host:path を出して exit 1）
researchctl which FILE ...              # sha256 でそのファイルを作った run・使った run を探す
researchctl lineage RUN_ID              # 上流（入力に使った run）と下流（出力を使った run）
researchctl list --all --issue 83       # Issue の run の一覧
researchctl verify RUN_ID               # 記録時から変わっていないか
```

前の run のファイルを入力にすると、manifest に `from_run`・`from_path` と、記録時の sha256 と一致するか（`verified`）が残り、一致しなければ実行しない。`researchctl which` で「どの run の記録にもない」と出たファイルは researchctl の外で作られたもので、結果の根拠にしない。

## 結果の読み方

- manifest（`researchctl path RUN_ID manifest.json`）を `jq` で読む: `jq '.status, .steps[].exit_code, .captured[].path'`。
- 大きい集計は、読むスクリプト自体を git に入れて `researchctl run` で実行する（読むだけでもスクリプトなら同じ扱い）。
- MongoDB（`--dbupdate`）の結果は run に入らない。使う値は CSV に export するスクリプトを run で実行して残す。
