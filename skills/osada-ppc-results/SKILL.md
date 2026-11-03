---
name: osada-ppc-results
description: Work with osada-ppc-simulator result data in MongoDB and generate CSV/graphs, especially UnifiedCache first/second cache miss ratios across powers-of-two capacities using Python and uv.
---

# Osada PPC Results

## Scope
Use this skill in `/home/yuzugon/osada-ppc-simulator` when extracting simulator results from MongoDB and producing result CSVs or graphs.

Prefer Python scripts under `scripts/` for analysis and plotting. If dependencies such as `pymongo` or `matplotlib` are missing, use `uv run --script` with PEP 723 script metadata instead of rewriting the tool in another language.

## Workflow
1. Inspect the existing schema and plotting conventions first: `db/db.go`, `docs/cache/UnifiedCache.md`, and nearby `scripts/plot_*.py`.
2. Put new analysis scripts in `scripts/` and include PEP 723 dependencies when non-stdlib packages are needed.
3. In this environment, run uv with `UV_CACHE_DIR=/tmp/uv-cache` because the default uv cache under `~/.cache` may be read-only.
4. If dependency download or MongoDB access fails due sandbox/network restrictions, rerun the exact needed command with escalation.
5. Validate with `python3 -m py_compile <script>`, `UV_CACHE_DIR=/tmp/uv-cache uv run --script <script> --help`, then the real command.

## UnifiedCache Miss Ratio
For requests like "UnifiedCacheについてMongoDBから結果を取り出してfirstcachemissとsecondcachemissの割合を2^6-2^14までグラフ化":

- Query `db.simulator_results` by default, using `DATABASE_URL` or `mongodb://localhost:27017/`.
- Filter on `simulator_result.type == "UnifiedCache"` and `simulator_result.parameter.size in [2^start_exp..2^end_exp]`.
- Expose optional filters for `rule_file_name`, `trace_file_name`, `simulator_result.processed`, `simulator_result.parameter.way`, and `simulator_result.parameter.cacheindextype`.
- Read compressed current-format counters from:
  - `unified_stat_rows`
  - `first_miss_count_compressed`
  - `second_miss_count_compressed`
- Decode compressed counters as `gzip+uint32le[rows][32]`, then sum every uint32 value.
- Support older documents by also checking `simulator_result.statdetail.cachelinefirstmisscount` and `simulator_result.statdetail.cachelinesecondmisscount`.
- For multiple documents at the same capacity, sum first/second miss counts first, then compute ratios. Do not average per-document percentages.
- Use:
  - `first_ratio = first / (first + second) * 100`
  - `second_ratio = second / (first + second) * 100`
- Include every requested capacity in the CSV; use zero counts and `doc_count=0` when no document exists.
- Plot only capacities that have data and nonzero total misses. Use log2 x-axis labels such as `2^10`.

## Command Pattern
Default command for the 2^6 through 2^14 UnifiedCache graph:

```bash
UV_CACHE_DIR=/tmp/uv-cache uv run --script scripts/plot_unified_miss_ratio_2p6_2p14.py
```

Useful filtered form:

```bash
UV_CACHE_DIR=/tmp/uv-cache uv run --script scripts/plot_unified_miss_ratio_2p6_2p14.py \
  --start-exp 6 \
  --end-exp 14 \
  --way 8 \
  --cache-index-type 5
```

Expected outputs should be a PNG graph and CSV in `scripts/`, and the final response should report generated paths plus any capacities that had no data.

## UnifiedCache Whole-Cache Miss Counts to 2^17

When the request is about first reference misses versus second-or-later misses from the cache as a whole, use whole-cache counters instead of summing per-cacheline first/second counters:

- Generate data with the current simulator so MongoDB documents include:
  - `simulator_result.statdetail.wholecachefirstmisscount`
  - `simulator_result.statdetail.wholecachesecondmisscount`
- Use `--miss-scope whole-cache` and `--plot-unit absolute`.
- For trend checking beyond the practical capacity range, extend graphs through `2^17`.
- Treat `2^14..2^17` as an oversized trend-check region, not the main comparison range. Plot it with `--tail-start-exp 14`, which draws points at and after `2^14` as a lighter dashed tail.
- For first-miss-focused views, use `--ymin 0 --ymax 10000`.

Typical command:

```bash
MPLCONFIGDIR=/tmp/matplotlib UV_CACHE_DIR=/tmp/uv-cache uv run --script scripts/plot_unified_miss_ratio_2p6_2p14.py \
  --start-exp 6 \
  --end-exp 17 \
  --miss-scope whole-cache \
  --plot-unit absolute \
  --ymin 0 \
  --ymax 10000 \
  --tail-start-exp 14 \
  --way 8 \
  --cache-index-type 5
```

If `2^15..2^17` are missing, run only the missing extension range to avoid duplicate DB results:

```bash
./exec.sh --config scripts/env/unified-way8-2p15-2p17.env
```
