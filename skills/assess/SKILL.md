---
name: assess
description: Size up a TYPO3 extension migration before any code changes. Reports the current and declared TYPO3/PHP versions, available QA tooling, the legacy API hits for each hop up to a target major, and an effort and risk rating. Use when the user asks how hard, how long or how risky it is to bring an extension to TYPO3 11, 12, 13 or 14, or wants a pre-upgrade audit.
argument-hint: "[target-major, e.g. 14] [path]"
allowed-tools: Read, Grep, Glob, Bash(*/inventory.sh*), Bash(*/scan-legacy-api.sh*), Bash(git status*), Bash(git log*)
---

# Assess a TYPO3 extension migration

Read-only. Change nothing.

Arguments: `$ARGUMENTS`. The first number is the target major (default 14). A
path, if given, is the extension directory (default: current directory).

## Snapshot at load time

!`"${CLAUDE_SKILL_DIR}/../typo3-extension-migration/scripts/inventory.sh" . 2>&1 | head -40`

## Steps

1. If the snapshot above did not come from an extension directory (no
   `composer.json` with `typo3/cms-core`, no `ext_emconf.php`), ask for the
   path and run `../typo3-extension-migration/scripts/inventory.sh <path>`
   again.
2. Work out the source major from the lowest major in the constraints. Every
   hop from there to the target is one scan:
   `../typo3-extension-migration/scripts/scan-legacy-api.sh --from <N> --to <N+1> --path <path> --format md`
3. Look up any rule id you need to explain in
   `../typo3-extension-migration/references/v*-to-v*.md`.
4. Check for signals the scan cannot see:
   - hooks registered through `$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']`
   - XCLASSes
   - raw SQL (`$GLOBALS['TYPO3_DB']`, `->executeQuery`)
   - custom ViewHelpers
   - a custom backend module
   - `list_type` plugins
   - JavaScript under `Resources/Public/JavaScript`
5. Rate the effort:

| Rating | Typical signal |
| --- | --- |
| S | one hop, fewer than 20 hits, Rector covers most of them, tests exist |
| M | one or two hops, 20–80 hits, some TCA/Fluid/JS work |
| L | three or more hops, a backend module or XCLASS rewrite, no tests |
| XL | v10 → v14 on a large extension with hooks, raw SQL and custom JS |

## Output

Keep it on one screen:

- **Current → target:** declared constraints, installed core, PHP floor for each hop
- **Hits per hop:** count by level (removed / breaking / deprecated), plus the five heaviest rules
- **What Rector/Fractor will likely handle** and **what needs hands**
- **Missing safety net:** no tests, no PHPStan, no CI (each makes the rating heavier)
- **Rating** (S/M/L/XL) with one sentence of why
- **Suggested next step:** usually the main `typo3-extension-migration` skill with the agreed target
