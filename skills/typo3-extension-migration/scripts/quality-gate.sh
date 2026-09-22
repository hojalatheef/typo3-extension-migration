#!/usr/bin/env bash
# quality-gate.sh — run every check the extension ships with and report one verdict.
#
# Usage: quality-gate.sh [extension-dir] [--skip functional] [--only phpstan,unit]
#
# Detects binaries in vendor/bin, .Build/bin or .Build/vendor/bin and runs, when
# present: composer validate, php -l, php-cs-fixer (dry-run), rector (dry-run),
# fractor (dry-run), phpstan, phpunit unit + functional. A missing tool is
# reported as SKIPPED, never as passed. Exit 0 only if nothing FAILED.

set -uo pipefail

dir="."
skip=""
only=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip) skip="$2"; shift 2 ;;
    --only) only="$2"; shift 2 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) dir="$1"; shift ;;
  esac
done
cd "$dir" || exit 2

bin() {
  local b
  for b in vendor/bin/"$1" .Build/bin/"$1" .Build/vendor/bin/"$1"; do
    [[ -x "$b" ]] && { printf '%s' "$b"; return 0; }
  done
  return 1
}
first() { local f; for f in "$@"; do [[ -e "$f" ]] && { printf '%s' "$f"; return 0; }; done; return 1; }
wanted() {
  [[ -n "$only" && ",$only," != *",$1,"* ]] && return 1
  [[ ",$skip," == *",$1,"* ]] && return 1
  return 0
}

declare -a names=() verdicts=()
failed=0
log_dir="$(mktemp -d)"

step() {
  # step <name> <command...>
  local name="$1"; shift
  wanted "$name" || return 0
  printf '── %-12s %s\n' "$name" "$*"
  if "$@" >"$log_dir/$name.log" 2>&1; then
    names+=("$name"); verdicts+=("PASS")
  else
    names+=("$name"); verdicts+=("FAIL (exit $?)"); failed=1
    tail -n 25 "$log_dir/$name.log" | sed 's/^/   │ /'
  fi
}
skipped() { wanted "$1" || return 0; names+=("$1"); verdicts+=("SKIPPED: $2"); }

step composer composer validate --no-check-publish --no-interaction

lint_php() {
  find . \( -path ./vendor -o -path ./.Build -o -path ./var -o -path ./node_modules \) -prune -o -name '*.php' -print0 \
    | xargs -0 -n1 -P4 php -l >/dev/null
}
step lint lint_php

if b="$(bin php-cs-fixer)"; then
  cfg="$(first .php-cs-fixer.php .php-cs-fixer.dist.php Build/php-cs-fixer.php Build/php-cs-fixer/config.php)" \
    && step cs "$b" fix --dry-run --diff --config="$cfg" \
    || step cs "$b" fix --dry-run --diff
else skipped cs "php-cs-fixer not installed"; fi

if b="$(bin rector)"; then
  cfg="$(first rector.php Build/rector.php Build/rector/rector.php)" \
    && step rector "$b" process --dry-run --no-progress-bar --config="$cfg" \
    || skipped rector "no rector.php"
else skipped rector "rector not installed"; fi

if b="$(bin fractor)"; then
  cfg="$(first fractor.php Build/fractor.php Build/fractor/fractor.php)" \
    && step fractor "$b" process --dry-run --config="$cfg" \
    || skipped fractor "no fractor.php"
else skipped fractor "fractor not installed"; fi

if b="$(bin phpstan)"; then
  cfg="$(first phpstan.neon phpstan.neon.dist Build/phpstan.neon Build/phpstan/phpstan.neon)" \
    && step phpstan "$b" analyse --no-progress --memory-limit=1G -c "$cfg" \
    || step phpstan "$b" analyse --no-progress --memory-limit=1G
else skipped phpstan "phpstan not installed"; fi

if b="$(bin phpunit)"; then
  if cfg="$(first Build/phpunit/UnitTests.xml Build/phpunit.unit.xml phpunit.unit.xml Tests/UnitTests.xml phpunit.xml.dist phpunit.xml)"; then
    [[ -d Tests/Unit ]] && step unit "$b" -c "$cfg" Tests/Unit || skipped unit "no Tests/Unit"
  else skipped unit "no phpunit config"; fi
  if cfg="$(first Build/phpunit/FunctionalTests.xml Build/phpunit.functional.xml phpunit.functional.xml Tests/FunctionalTests.xml)"; then
    [[ -d Tests/Functional ]] && step functional "$b" -c "$cfg" Tests/Functional || skipped functional "no Tests/Functional"
  else skipped functional "no functional phpunit config"; fi
else skipped unit "phpunit not installed"; skipped functional "phpunit not installed"; fi

echo
echo "Quality gate summary ($(pwd))"
for i in "${!names[@]}"; do printf '  %-12s %s\n' "${names[$i]}" "${verdicts[$i]}"; done
echo "  logs: $log_dir"
if (( failed )); then echo "VERDICT: FAILED"; exit 1; fi
echo "VERDICT: PASSED (read SKIPPED lines before calling the migration done)"
