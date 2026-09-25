#!/usr/bin/env bash
# selftest.sh — structural and behavioural checks for this plugin repository.
# Run from anywhere; exits non-zero on the first category that fails.

set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
skill="skills/typo3-extension-migration"
fail=0
ok()   { printf '  ok    %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "manifests"
for j in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
  jq -e . "$j" >/dev/null 2>&1 && ok "$j is valid JSON" || bad "$j is not valid JSON"
done
v_plugin="$(jq -r .version .claude-plugin/plugin.json)"
grep -q "## \[$v_plugin\]" CHANGELOG.md && ok "CHANGELOG has $v_plugin" || bad "CHANGELOG lacks entry for $v_plugin"

echo "frontmatter"
for f in skills/*/SKILL.md agents/*.md; do
  head -1 "$f" | grep -q '^---$' || { bad "$f: no frontmatter"; continue; }
  fm="$(awk 'NR==1{next} /^---$/{exit} {print}' "$f")"
  grep -q '^description: .\{40,\}' <<<"$fm" || bad "$f: description missing or too short"
  if [[ "$f" == agents/* ]]; then
    grep -Eq '^model: (opus|sonnet|haiku|inherit|claude-)' <<<"$fm" || bad "$f: model missing"
    grep -q '^name: ' <<<"$fm" || bad "$f: name missing"
  fi
done
ok "skills and agents carry frontmatter"

echo "reference links"
while IFS= read -r ref; do
  [[ -e "$skill/$ref" ]] || bad "SKILL.md references missing $ref"
done < <(grep -Eo '(references|templates|scripts)/[A-Za-z0-9_.*-]+' "$skill/SKILL.md" | grep -v -e '\*' -e 'vNN' | sort -u)
ok "main skill links resolve"

echo "rules"
rules=0
for t in "$skill"/data/rules-*.tsv; do
  [[ -e "$t" ]] || { bad "no rule files"; break; }
  n=0
  while IFS= read -r line; do
    n=$((n+1)); [[ $n -eq 1 || -z "$line" || "$line" == \#* ]] && continue
    cols="$(awk -F'\t' '{print NF}' <<<"$line")"
    [[ "$cols" == 6 ]] || { bad "$t:$n has $cols columns"; continue; }
    IFS=$'\t' read -r id target level ext regex hint <<<"$line"
    [[ "$target" =~ ^1[0-5]$ ]] || bad "$t:$n target '$target'"
    [[ "$level" =~ ^(removed|breaking|deprecated)$ ]] || bad "$t:$n level '$level'"
    echo | grep -E -- "$regex" >/dev/null 2>&1; [[ $? -le 1 ]] || bad "$t:$n regex does not compile: $regex"
    rules=$((rules+1))
  done < "$t"
done
dups="$(cat "$skill"/data/rules-*.tsv | cut -f1 | grep -v '^id$' | sort | uniq -d)"
[[ -z "$dups" ]] || bad "duplicate rule ids: $dups"
ok "$rules rules parsed"

echo "scripts"
if command -v shellcheck >/dev/null; then
  shellcheck -S warning "$skill"/scripts/*.sh hooks/scripts/*.sh scripts/*.sh && ok "shellcheck" || bad "shellcheck"
else echo "  skip  shellcheck not installed"; fi
bash -n "$skill"/scripts/*.sh hooks/scripts/*.sh && ok "bash -n"

echo "scanner on fixture"
out="$("$skill/scripts/scan-legacy-api.sh" --from 11 --to 12 --path evals/fixtures/legacy_events --format json)"
hits="$(jq '.matched_rules' <<<"$out")"
(( hits >= 5 )) && ok "fixture v11→v12 matched $hits rules" || bad "fixture v11→v12 matched only $hits rules"

echo "changelog lookup"
lookup="$skill/scripts/changelog-lookup.sh"
"$lookup" >/dev/null 2>&1; [[ $? -eq 2 ]] && ok "no query exits 2" || bad "no query should exit 2"
tmp="$(mktemp -d)"
cl="$tmp/.Build/vendor/typo3/cms-core/Documentation/Changelog/12.0"
mkdir -p "$cl"
printf 'Breaking: #98443 - Extension recordlist merged into backend\n\nrecordlist text\n' > "$cl/Breaking-98443-ExtensionRecordlistMergedIntoBackend.rst"
printf 'Index\n' > "$cl/Index.rst"
XDG_CACHE_HOME="$tmp/cache" "$lookup" 98443 --path "$tmp" --no-fetch | grep -q 'recordlist text' \
  && ok "finds an issue number in the vendor copy" || bad "issue number lookup failed"
XDG_CACHE_HOME="$tmp/cache" "$lookup" recordlist --path "$tmp" --no-fetch --list | grep -q 'Breaking-98443' \
  && ok "keyword search lists the entry" || bad "keyword search failed"
XDG_CACHE_HOME="$tmp/cache" "$lookup" 11111 --path "$tmp" --no-fetch >/dev/null 2>&1; [[ $? -eq 1 ]] \
  && ok "unknown id exits 1" || bad "unknown id should exit 1"
rm -rf "$tmp"

echo "guard hook"
probe() {
  local out
  out="$(jq -n --arg c "$1" '{tool_input:{command:$c}}' | hooks/scripts/guard-bash.sh)"
  [[ -z "$out" ]] && { echo allow; return; }
  jq -r '.hookSpecificOutput.permissionDecision // "allow"' <<<"$out"
}
for c in 'git commit -m wip --no-verify' 'git commit -nm wip' 'rm -rf Tests/Unit' 'rm Tests/Unit/FooTest.php' 'vendor/bin/rector process vendor'; do
  [[ "$(probe "$c")" == deny ]] && ok "denies: $c" || bad "should deny: $c"
done
for c in 'git commit -m "fix -n handling"' 'git commit -am wip' 'vendor/bin/rector process Classes' 'rm -rf var/cache'; do
  [[ "$(probe "$c")" == allow ]] && ok "allows: $c" || bad "should allow: $c"
done

echo
(( fail )) && { echo "SELFTEST FAILED"; exit 1; }
echo "SELFTEST PASSED"
