---
name: verify
description: Prove a migrated TYPO3 extension works on every TYPO3 line it declares. Runs the full quality gate (composer validate, lint, coding standards, Rector/Fractor dry-run, PHPStan, unit and functional tests) per supported core version and reports a per-line verdict from real output. Use before calling a migration done, before a release, or when the user asks "does it work on v12 and v13".
argument-hint: "[path]"
---

# Verify a migrated extension

The migration is done when the gate exits 0 on every declared line, as
measured here. If one line passes and another fails, or a line hasn't been
run, it is not done.

## 1. Which lines to prove

Read the `typo3/cms-core` constraint in `composer.json` (and `ext_emconf.php`,
which must agree with it). Each `||` branch is a line to prove, for example
`^12.4 || ^13.4` means two runs.

## 2. Run per line

Save the current composer state first:

```bash
cp composer.json /tmp/composer.json.bak && [ -f composer.lock ] && cp composer.lock /tmp/composer.lock.bak
```

For each line, lowest first:

```bash
composer require "typo3/cms-core:^<line>" -W --no-interaction   # add sibling typo3/cms-* packages as needed
../typo3-extension-migration/scripts/quality-gate.sh .
```

Afterwards, restore both files and run `composer install`.

If the project uses DDEV or a `Build/Scripts/runTests.sh` (the core-style test
runner), prefer that and pass the core version through its own flags. It
often contains the database and PHP matrix that functional tests need.

## 3. Review

Dispatch the **migration-reviewer** agent with:

- the branch diff (`git diff <base>...HEAD`)
- the target lines and the gate output per line
- `.migration/ledger.md`

Fix every finding rated `blocker`, then run the gate again for the affected lines.

## 4. Report

```text
TYPO3 12.4 (PHP 8.1)  gate: PASSED   phpstan 0 · unit 142/142 · functional 38/38
TYPO3 13.4 (PHP 8.3)  gate: PASSED   phpstan 0 · unit 142/142 · functional 38/38
Skipped: none
Reviewer: 0 blocker, 2 minor (listed below)
```

Take the numbers from the logs the gate printed, never from memory. Report
any `SKIPPED` line or missing test suite as a coverage gap, and don't count
it as a pass.
