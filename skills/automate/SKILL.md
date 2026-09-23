---
name: automate
description: Run the automated part of a TYPO3 extension migration. Sets up and runs TYPO3 Rector for PHP and Fractor for TypoScript, FlexForms, Fluid and YAML against one target major, reviews the diff and commits it in reviewable steps. Use when the user asks to "run rector", "apply fractor", "do the automatic migrations" or set up Rector/Fractor for TYPO3 10–14.
argument-hint: "<target-major> [path]"
---

# Automated migration with Rector and Fractor

Arguments: `$ARGUMENTS` (target major, then an optional extension path).

Templates are in `../typo3-extension-migration/templates/`. Set and package
names for each major are in
`../typo3-extension-migration/references/version-matrix.md`.

## 1. Preconditions

- The git tree is clean, and you're on a migration branch.
- `composer.json` already allows the target core (for example `^13.4`) and `composer update -W` succeeded. Rector sets and the installed core must match.
- The tools are installed as dev dependencies, for example `composer require --dev ssch/typo3-rector a9f/typo3-fractor`. Check the matrix for the right versions.

## 2. Configure

If the extension has no `rector.php` or `fractor.php`, copy the templates and fill in:

- the paths to process: only the extension's own code (`Classes`, `Configuration`, `Tests`, `ext_*.php`, `Resources/Private`)
- the target level set for the major
- the PHP level that matches the target's PHP floor
- skips for `vendor`, `.Build`, `var`, `public` and `node_modules`

If a config already exists, change only the target level and paths. Keep the
project's own rules and skips.

## 3. Run, one tool at a time

```bash
vendor/bin/rector process --dry-run      # read the diff before applying
vendor/bin/rector process
git add -A && git commit -m "[TASK] Apply TYPO3 Rector level set v<N>"

vendor/bin/fractor process --dry-run
vendor/bin/fractor process
git add -A && git commit -m "[TASK] Apply Fractor migrations for TYPO3 v<N>"

vendor/bin/php-cs-fixer fix              # if configured: keep style commits separate
git add -A && git commit -m "[TASK] Apply coding standards after automated migration"
```

When reading the dry-run diff, look for:

- **Renamed public API** in `Classes/` that other extensions may call. Flag it for the report.
- **Rules that guessed:** an `@var` type pulled from a docblock, or a changed nullable signature. Verify those by hand.
- **Changes in `Tests/`.** Keep them, but check that the assertions still test the same thing.

If a rule produces broken code, don't hand-edit around it again and again.
Skip that single rule in the config with a comment explaining why, and add
the affected locations to `.migration/ledger.md` as manual work.

## 4. Measure what is left

```bash
../typo3-extension-migration/scripts/quality-gate.sh --skip functional
../typo3-extension-migration/scripts/scan-legacy-api.sh --from <N-1> --to <N>
```

Every rule id still matching and every failing gate line becomes a ledger
entry for hand migration. Report the before/after hit counts to the user.
