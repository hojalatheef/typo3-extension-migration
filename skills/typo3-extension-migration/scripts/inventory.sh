#!/usr/bin/env bash
# inventory.sh — print a factual snapshot of a TYPO3 extension before migrating it.
#
# Usage: inventory.sh [extension-dir] [--json]
#
# Reports: extension key, declared TYPO3/PHP constraints (composer.json and
# ext_emconf.php), installed core version if vendor/ exists, available QA
# tooling, git state and a rough size breakdown. Read-only; never modifies files.

set -euo pipefail

dir="."
json=0
for arg in "$@"; do
  case "$arg" in
    --json) json=1 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) dir="$arg" ;;
  esac
done
cd "$dir"

have() { command -v "$1" >/dev/null 2>&1; }

composer_field() {
  # $1 = jq path; falls back to a crude grep when jq is missing.
  if [[ -f composer.json ]] && have jq; then
    jq -r "$1 // empty" composer.json 2>/dev/null || true
  fi
}

ext_key="$(composer_field '.extra."typo3/cms"."extension-key"')"
[[ -z "$ext_key" ]] && ext_key="$(basename "$(pwd)")"
package="$(composer_field '.name')"
core_req="$(composer_field '.require."typo3/cms-core"')"
php_req="$(composer_field '.require.php')"

emconf_typo3=""
emconf_php=""
if [[ -f ext_emconf.php ]]; then
  emconf_typo3="$(grep -Eo "'typo3'[[:space:]]*=>[[:space:]]*'[^']*'" ext_emconf.php | head -1 | sed -E "s/.*=>[[:space:]]*'([^']*)'/\1/")" || true
  emconf_php="$(grep -Eo "'php'[[:space:]]*=>[[:space:]]*'[^']*'" ext_emconf.php | head -1 | sed -E "s/.*=>[[:space:]]*'([^']*)'/\1/")" || true
fi

installed_core=""
for lock in composer.lock .Build/composer.lock; do
  if [[ -f "$lock" ]] && have jq; then
    installed_core="$(jq -r '.packages[] | select(.name=="typo3/cms-core") | .version' "$lock" 2>/dev/null | head -1)"
    [[ -n "$installed_core" ]] && break
  fi
done

# Lowest major mentioned in the core constraint = the line we migrate from.
from_major="$(printf '%s %s' "$core_req" "$emconf_typo3" | grep -Eo '(^|[^0-9.])1[0-9]\.' | grep -Eo '1[0-9]' | sort -n | head -1)" || true
to_major_declared="$(printf '%s %s' "$core_req" "$emconf_typo3" | grep -Eo '(^|[^0-9.])1[0-9]\.' | grep -Eo '1[0-9]' | sort -n | tail -1)" || true

tool_state() {
  local bin="$1" cfg="$2" state="absent"
  for b in vendor/bin/"$bin" .Build/bin/"$bin" .Build/vendor/bin/"$bin"; do
    [[ -x "$b" ]] && state="installed" && break
  done
  for c in $cfg; do
    [[ -e "$c" ]] && state="$state+config" && break
  done
  printf '%s' "$state"
}

rector="$(tool_state rector 'rector.php Build/rector.php Build/rector/rector.php')"
fractor="$(tool_state fractor 'fractor.php Build/fractor.php Build/fractor/fractor.php')"
phpstan="$(tool_state phpstan 'phpstan.neon phpstan.neon.dist Build/phpstan.neon Build/phpstan/phpstan.neon')"
phpcsf="$(tool_state php-cs-fixer '.php-cs-fixer.php .php-cs-fixer.dist.php Build/php-cs-fixer.php Build/php-cs-fixer/config.php')"
phpunit="$(tool_state phpunit 'phpunit.xml phpunit.xml.dist Build/phpunit Build/UnitTests.xml Tests/UnitTests.xml')"

count() { find . \( -path ./vendor -o -path ./.Build -o -path ./node_modules -o -path ./.git -o -path ./var -o -path ./public \) -prune -o -type f \( "$@" \) -print 2>/dev/null | wc -l | tr -d ' '; }
n_php="$(count -name '*.php')"
n_fluid="$(count -name '*.html')"
n_ts="$(count -name '*.typoscript' -o -name '*.tsconfig')"
n_xml="$(count -name '*.xml')"
n_js="$(count -name '*.js' -o -name '*.mjs')"
n_tests="$( [[ -d Tests ]] && find Tests -name '*Test.php' | wc -l | tr -d ' ' || echo 0)"

git_state="not a git repo"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  dirty="$(git status --porcelain | wc -l | tr -d ' ')"
  git_state="branch=$(git symbolic-ref --short -q HEAD 2>/dev/null || echo detached) uncommitted=$dirty"
fi

ddev="no"; [[ -d .ddev ]] && ddev="yes"
has_ext_tables="no"; [[ -f ext_tables.php ]] && has_ext_tables="yes"
has_emconf="no"; [[ -f ext_emconf.php ]] && has_emconf="yes"

if [[ $json -eq 1 ]]; then
  jq -n \
    --arg ext_key "$ext_key" --arg package "$package" \
    --arg core_req "$core_req" --arg php_req "$php_req" \
    --arg emconf_typo3 "$emconf_typo3" --arg emconf_php "$emconf_php" \
    --arg installed_core "$installed_core" \
    --arg from_major "$from_major" --arg to_major_declared "$to_major_declared" \
    --arg rector "$rector" --arg fractor "$fractor" --arg phpstan "$phpstan" \
    --arg phpcsfixer "$phpcsf" --arg phpunit "$phpunit" \
    --arg php "$n_php" --arg fluid "$n_fluid" --arg typoscript "$n_ts" \
    --arg xml "$n_xml" --arg js "$n_js" --arg tests "$n_tests" \
    --arg git "$git_state" --arg ddev "$ddev" \
    --arg ext_tables "$has_ext_tables" --arg ext_emconf "$has_emconf" \
    '{extension:{key:$ext_key,package:$package,has_ext_emconf:$ext_emconf,has_ext_tables:$ext_tables},
      constraints:{composer_core:$core_req,composer_php:$php_req,emconf_typo3:$emconf_typo3,emconf_php:$emconf_php,
                   lowest_major:$from_major,highest_major:$to_major_declared,installed_core:$installed_core},
      tooling:{rector:$rector,fractor:$fractor,phpstan:$phpstan,php_cs_fixer:$phpcsfixer,phpunit:$phpunit,ddev:$ddev},
      files:{php:$php,fluid:$fluid,typoscript:$typoscript,xml:$xml,js:$js,tests:$tests},
      git:$git}'
  exit 0
fi

cat <<EOF
TYPO3 extension inventory
  extension key ........ $ext_key
  composer package ..... ${package:-<none>}
  core constraint ...... ${core_req:-<none>}   (ext_emconf: ${emconf_typo3:-<none>})
  php constraint ....... ${php_req:-<none>}   (ext_emconf: ${emconf_php:-<none>})
  majors declared ...... ${from_major:-?} .. ${to_major_declared:-?}
  installed core ....... ${installed_core:-<not installed>}
  ext_emconf.php ....... $has_emconf     ext_tables.php: $has_ext_tables
  tooling .............. rector=$rector fractor=$fractor phpstan=$phpstan
                         php-cs-fixer=$phpcsf phpunit=$phpunit ddev=$ddev
  files ................ php=$n_php fluid=$n_fluid typoscript/tsconfig=$n_ts xml=$n_xml js=$n_js tests=$n_tests
  git .................. $git_state
EOF
