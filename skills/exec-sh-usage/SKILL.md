---
name: exec-sh-usage
description: Maintain and operate `exec.sh` for cache simulator runs. Use when Codex needs to explain, update, or troubleshoot `exec.sh`, especially when migrating runtime settings from `.env` to CLI flags (`-cachetype`, `-capacity-*`, `-refbits-*`) while keeping only `DATABASE_URL` and `DEBUG_MODE` as environment variables.
---

# Exec.sh Usage

## Overview
Standardize how `exec.sh` builds and runs `./main` commands.
Keep runtime tuning values in script variables and pass them as CLI flags.

## Workflow
1. Read `exec.sh` and current `main.go` flag definitions before editing.
2. Keep policy: only `DATABASE_URL` and `DEBUG_MODE` remain environment-variable based.
3. Move non-exempt settings to script variables and pass them in the `cmd=(...)` array.
4. Preserve behavior for trace iteration, optional `sudo`, and optional flags (`-max`, `-dbupdate`, `-bench`, `-recordCachehit`).
5. Validate with `bash -n exec.sh` and ensure execute permission when needed.

## Parameter Mapping
Replace `.env`-driven settings using this mapping.

- `CACHE_TYPE` -> `-cachetype`
- `CAPACITY_START` -> `-capacity-start`
- `CAPACITY_END` -> `-capacity-end`
- `CAPACITY_MULTIPLIER` -> `-capacity-step`
- `REFBITS_START` -> `-refbits-start`
- `REFBITS_END` -> `-refbits-end`
- `REFBITS_MULTIPLIER` -> `-refbits-step`

Keep these as environment variables.

- `DATABASE_URL`
- `DEBUG_MODE`

## Editing Pattern
Use this shape in `exec.sh`.

```bash
CACHE_TYPE="UnifiedCache"
CAPACITY_START=6
CAPACITY_END=14
CAPACITY_STEP=1
REFBITS_START=32
REFBITS_END=32
REFBITS_STEP=1

cmd=(
  ./main
  -rulefile "$RULEFILE"
  -trace "$TRACE"
  -cachetype "$CACHE_TYPE"
  -capacity-start "$CAPACITY_START"
  -capacity-end "$CAPACITY_END"
  -capacity-step "$CAPACITY_STEP"
  -refbits-start "$REFBITS_START"
  -refbits-end "$REFBITS_END"
  -refbits-step "$REFBITS_STEP"
)
```

Append optional flags conditionally.

```bash
if (( MAX_PROCESS > 0 )); then
  cmd+=( -max "$MAX_PROCESS" )
fi
if [[ "$ENABLE_DBUPDATE" == "true" ]]; then
  cmd+=( -dbupdate )
fi
if [[ "$ENABLE_BENCH" == "true" ]]; then
  cmd+=( -bench )
fi
if [[ "$ENABLE_RECORD_CACHE_HIT" == "true" ]]; then
  cmd+=( -recordCachehit )
fi
```

## Conversation-Aligned Example
When asked to:

- convert `.env` usage so only `DATABASE_URL` and `DEBUG_MODE` stay in env
- update `exec.sh` to the same format

Execute in this order.

1. Add/confirm flags in `main.go`.
2. Pass those values from `exec.sh` variables as CLI flags.
3. Keep `DATABASE_URL` and `DEBUG_MODE` unchanged as env-based behavior.
4. Run script syntax validation and report changed flags clearly.

## Output Expectations
In the final response:

- list changed files
- list added or changed CLI flags
- report validation commands and outcomes
- note any skipped checks and the reason
