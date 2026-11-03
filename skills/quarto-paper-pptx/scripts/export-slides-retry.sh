#!/usr/bin/env bash
set -u

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 SLIDE_HTML_DIR DOM_TO_PPTX_CLI [TITLE] [AUTHOR]" >&2
  exit 2
fi

slide_dir=$1
dom_to_pptx_cli=$2
title=${3:-Paper}
author=${4:-}
timeout_seconds=${SLIDE_EXPORT_TIMEOUT_SECONDS:-75}
max_retries=${SLIDE_EXPORT_RETRIES:-1}
log_dir=$(mktemp -d)
trap 'rm -rf "$log_dir"' EXIT

if [ ! -d "$slide_dir" ]; then
  echo "Missing slide HTML directory: $slide_dir" >&2
  exit 1
fi
if [ ! -x "$dom_to_pptx_cli" ]; then
  echo "Missing executable dom-to-pptx CLI: $dom_to_pptx_cli" >&2
  exit 1
fi

mapfile -t slide_htmls < <(find "$slide_dir" -maxdepth 1 -type f -name 'slide-*.html' -print | sort -V)
if [ "${#slide_htmls[@]}" -eq 0 ]; then
  echo "No slide HTML inputs found in $slide_dir" >&2
  exit 1
fi

failed=0
for html in "${slide_htmls[@]}"; do
  base=$(basename "$html" .html)
  output="$slide_dir/$base.pptx"
  log_file="$log_dir/$base.log"
  succeeded=0
  attempt=0
  while [ "$attempt" -le "$max_retries" ]; do
    if timeout "${timeout_seconds}s" "$dom_to_pptx_cli" export "$html" \
      --inject --no-pseudo --selector '.reveal .slides > section' \
      --width 13.333333 --height 7.5 \
      --browser-width 1280 --browser-height 720 \
      --title "$title" --author "$author" --output "$output" \
      >"$log_file" 2>&1; then
      succeeded=1
      break
    fi
    attempt=$((attempt + 1))
    if [ "$attempt" -le "$max_retries" ]; then
      echo "$base: retry $attempt/$max_retries"
    fi
  done
  if [ "$succeeded" -eq 1 ]; then
    echo "$base: ok"
  else
    echo "$base: failed after $((max_retries + 1)) attempt(s)" >&2
    tail -n 12 "$log_file" >&2
    failed=1
  fi
done

if [ "$failed" -ne 0 ]; then
  exit 1
fi
