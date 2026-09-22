#!/usr/bin/env bash
# scan-legacy-api.sh — find code that will break between two TYPO3 majors.
#
# Usage: scan-legacy-api.sh --to 13 [--from 12] [--path DIR] [--format md|tsv|json] [--rules DIR] [--ahead]
#
# Rules live in ../data/rules-*.tsv (columns: id target level ext regex hint).
# A rule is applied when from < target <= to. Output lists every rule that
# matched with hit count and the first locations. Exit code: 0 = no hits,
# 1 = hits found, 2 = usage error. --ahead also applies rules for the major
# after --to (deprecated now, removed next), to prepare the following hop. This is a heuristic pre-scan; it does not
# replace the Extension Scanner, Rector dry-run or PHPStan.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rules_dir="$here/../data"
from=""
to=""
path="."
format="md"
max_locations=5
ahead=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from) from="$2"; shift 2 ;;
    --to) to="$2"; shift 2 ;;
    --path) path="$2"; shift 2 ;;
    --format) format="$2"; shift 2 ;;
    --rules) rules_dir="$2"; shift 2 ;;
    --max-locations) max_locations="$2"; shift 2 ;;
    --ahead) ahead=1; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$to" ]] && { echo "--to <major> is required (10..14)" >&2; exit 2; }
if [[ -z "$from" ]]; then
  from="$("$here/inventory.sh" "$path" --json 2>/dev/null | jq -r '.constraints.lowest_major // empty' 2>/dev/null || true)"
  [[ -z "$from" ]] && from=$((to - 1))
fi
(( from < to )) || { echo "--from ($from) must be lower than --to ($to)" >&2; exit 2; }

shopt -s nullglob
rule_files=("$rules_dir"/rules-*.tsv)
(( ${#rule_files[@]} )) || { echo "no rule files in $rules_dir" >&2; exit 2; }

includes_for() {
  local out=() e
  IFS=',' read -ra exts <<< "$1"
  for e in "${exts[@]}"; do
    case "$e" in
      php) out+=(--include='*.php') ;;
      html) out+=(--include='*.html') ;;
      typoscript) out+=(--include='*.typoscript' --include='setup.txt' --include='constants.txt' --include='*.ts') ;;
      tsconfig) out+=(--include='*.tsconfig' --include='*TSconfig*.txt') ;;
      xml) out+=(--include='*.xml' --include='*.xlf') ;;
      yaml) out+=(--include='*.yaml' --include='*.yml') ;;
      js) out+=(--include='*.js' --include='*.mjs') ;;
      sql) out+=(--include='*.sql') ;;
      *) out+=(--include="*.$e") ;;
    esac
  done
  printf '%s\n' "${out[@]}"
}

excludes=(--exclude-dir=vendor --exclude-dir=.Build --exclude-dir=node_modules
          --exclude-dir=.git --exclude-dir=var --exclude-dir=public --exclude-dir=Contrib)

results="$(mktemp)"
trap 'rm -f "$results"' EXIT

for file in "${rule_files[@]}"; do
  while IFS=$'\t' read -r id target level ext regex hint; do
    [[ -z "$id" || "$id" == "id" || "$id" == \#* ]] && continue
    [[ "$target" =~ ^[0-9]+$ ]] || continue
    (( target > from && target <= to + ahead )) || continue
    inc=()
    while IFS= read -r line; do inc+=("$line"); done < <(includes_for "$ext")
    hits="$(grep -rnE "${excludes[@]}" "${inc[@]}" -- "$regex" "$path" 2>/dev/null || true)"
    [[ -z "$hits" ]] && continue
    n="$(printf '%s\n' "$hits" | wc -l | tr -d ' ')"
    locs="$(printf '%s\n' "$hits" | head -n "$max_locations" | cut -d: -f1,2 | sed "s#^$path/##" | paste -sd' ' -)"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$target" "$level" "$id" "$n" "$hint" "$locs" >> "$results"
  done < "$file"
done

sort -t$'\t' -k1,1n -k2,2 -k4,4nr "$results" -o "$results"
total_rules="$(wc -l < "$results" | tr -d ' ')"

case "$format" in
  tsv)
    printf 'target\tlevel\tid\thits\thint\tlocations\n'
    cat "$results"
    ;;
  json)
    jq -R -s --arg from "$from" --arg to "$to" '
      split("\n") | map(select(length>0) | split("\t")
        | {target:(.[0]|tonumber), level:.[1], id:.[2], hits:(.[3]|tonumber), hint:.[4], locations:(.[5]|split(" "))})
      | {from:($from|tonumber), to:($to|tonumber), matched_rules:length, findings:.}' "$results"
    ;;
  md)
    echo "## Legacy API pre-scan: v$from → v$to"
    echo
    if [[ "$total_rules" == 0 ]]; then
      echo "No rule matched. Still run the Extension Scanner and a Rector dry-run."
    else
      echo "| Breaks in | Level | Rule | Hits | Fix | First locations |"
      echo "|---|---|---|---|---|---|"
      awk -F'\t' '{printf "| v%s | %s | `%s` | %s | %s | %s |\n", $1, $2, $3, $4, $5, $6}' "$results"
      echo
      echo "$total_rules rule(s) matched. Cards for each rule id: references/v*-to-v*.md"
    fi
    ;;
  *) echo "unknown format: $format" >&2; exit 2 ;;
esac

[[ "$total_rules" == 0 ]]
