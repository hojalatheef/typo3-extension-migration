#!/usr/bin/env bash
# guard-bash.sh — PreToolUse hook for Bash.
#
# Blocks shortcuts that make a TYPO3 migration look finished when it is not:
#   * git commit/push with --no-verify (or -n on commit)
#   * deleting or emptying test files/directories
#   * running rector/fractor "process" without --dry-run on vendor/ paths
# Everything else passes through untouched. Reads the hook payload on stdin.

set -euo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[[ -z "$cmd" ]] && exit 0

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

no_verify='git[[:space:]][^|;&]*--no-verify'
short_n='git[[:space:]]+commit[^|;&"'\'']*[[:space:]]-[a-mo-zA-Z]*n[a-zA-Z]*([[:space:]]|$)'
if printf '%s' "$cmd" | grep -Eq -- "$no_verify" || printf '%s' "$cmd" | grep -Eq -- "$short_n"; then
  deny "typo3-extension-migration: skipping git hooks is not allowed. Run the command the hook runs (see .git/hooks or the pre-commit config), fix what it reports, then commit again."
fi

if printf '%s' "$cmd" | grep -Eq '(rm|git[[:space:]]+rm)[[:space:]][^|;&]*Tests/(Unit|Functional|Acceptance)|(rm|git[[:space:]]+rm)[[:space:]][^|;&]*[A-Za-z0-9_]+Test\.php'; then
  deny "typo3-extension-migration: removing tests to get a green run is not allowed. Fix the test or the code; if a test is truly obsolete, explain why to the user and let them delete it."
fi

if printf '%s' "$cmd" | grep -Eq '(rector|fractor)[[:space:]]+process' \
   && ! printf '%s' "$cmd" | grep -Eq -- '--dry-run' \
   && printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])(\./)?(vendor|\.Build)/?([[:space:]]|$)'; then
  deny "typo3-extension-migration: refusing to rewrite vendor code. Point rector/fractor at the extension's own paths."
fi

exit 0
