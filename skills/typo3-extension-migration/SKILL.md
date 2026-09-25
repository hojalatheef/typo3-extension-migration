---
name: typo3-extension-migration
description: Migrate a TYPO3 extension (extension code, not a site or core install) from one LTS line to a newer one anywhere between v10 and v14, or make it support two LTS lines at once. Use when the user asks to upgrade, migrate, modernize or "make compatible with TYPO3 11/12/13/14", when composer refuses a newer typo3/cms-core, when the Extension Scanner, Rector, Fractor or PHPStan report deprecated or removed APIs, or when something breaks after a core update (Fluid ViewHelper errors, DI container errors, missing TSFE, removed hooks, list_type plugins, backend module registration).
---

# TYPO3 extension migration

This skill takes one extension from its current TYPO3 line to a target line
and proves the result on every line it claims to support. It is built around
four ideas:

- **Facts before edits.** The inventory and the rule scan decide the plan, not memory.
- **Machines first, humans second.** Rector and Fractor do the bulk; people and agents fix what the tools cannot.
- **One major at a time.** Hop v11 → v12 → v13, never v11 → v13 in one leap. Each hop ends in a green gate before the next starts.
- **Green means measured.** The migration is finished when `scripts/quality-gate.sh` exits 0 on each supported line, and not before.

Paths below are relative to this skill's directory (`${CLAUDE_SKILL_DIR}`).

## Working state

Keep progress in the extension under `.migration/` (add it to `.gitignore`
unless the user wants it committed):

| File | Holds |
|---|---|
| `.migration/inventory.json` | output of `scripts/inventory.sh --json` |
| `.migration/scan-vNN.md` | rule scan per hop |
| `.migration/plan.md` | hops, work packages, owners, risks |
| `.migration/ledger.md` | one line per finding: `id · file · status (open/fixed/deferred) · note` |

The ledger makes the work resumable: a new session reads it and continues
with the open lines instead of starting over.

## Phase 1: Recon

1. Confirm the working tree is clean and create a branch such as `migration/v13`.
2. Run `scripts/inventory.sh --json > .migration/inventory.json` and read it.
   It shows the extension key, the declared constraints, the installed core,
   the available QA tools and the file mix.
3. Agree with the user on **source line, target line and whether old lines stay supported.**
   Adding v14 while keeping v13 is not the same job as replacing v13 with v14.
   Read `references/version-matrix.md` for the exact constraint strings. Only
   LTS minors exist as targets: 10.4, 11.5, 12.4, 13.4, 14.3.
4. For each hop, run
   `scripts/scan-legacy-api.sh --from <N> --to <N+1> --path . > .migration/scan-v<N+1>.md`.
   Exit 1 only means that something was found.

For a large extension (more than about 150 PHP files, or several areas such as
backend modules, plugins, scheduler tasks and CLI), dispatch **legacy-scout**
agents in parallel, one per area. Each returns occurrences with file:line, so
the plan is based on complete data.

## Phase 2: Plan

Hand the inventory and scans to the **migration-strategist** agent. It writes
`.migration/plan.md` with:

- the hop sequence and, per hop, the composer/ext_emconf changes, the PHP floor and the testing-framework major
- work packages cut along **disjoint file sets** (for example `Classes/Controller`, `Configuration/TCA`, `Resources/Private`) so they can run in parallel without conflicts
- for each package, the reference cards it touches (`references/vNN-to-vMM.md`)
- the risks that need a human decision: dropped features, changed public API, database changes

Show the plan to the user and wait for a go-ahead before large edits.

## Phase 3: Automate (per hop)

Follow the `automate` skill of this plugin. In short:

1. Raise the constraints for this hop in `composer.json` and `ext_emconf.php`, then run `composer update -W`.
2. Copy and adapt `templates/rector.php` and `templates/fractor.php` if the extension has none, pinned to this hop's target.
3. Run a dry run, read the diff, apply, and commit each tool separately (`[TASK] Apply Rector set for TYPO3 v13`).
4. Run a gate: `scripts/quality-gate.sh --skip functional`. The failures that remain define the manual work.

## Phase 4: Hand migration (per hop)

Dispatch one **code-migrator** agent per work package, in parallel. Each one gets:

- its file set, and an instruction to edit nothing outside it
- the ledger lines and reference cards for that set
- the command that proves its slice, such as a PHPStan run on its paths or its unit tests

When a package has to change shared files (`ext_localconf.php`,
`Services.yaml`, `composer.json`), do that serially yourself after the
parallel batch returns. Update the ledger from each agent's report.

Card-specific guidance:

- `references/non-php-assets.md`: TypoScript, TSconfig, FlexForms, Fluid, JS modules, Icons.php, Modules.php
- `references/multi-version-support.md`: when two lines must run from one codebase
- `references/troubleshooting.md`: when an error message doesn't point to a card

When a card's hint isn't enough (a class mapping, a list of removed hooks, the
exact replacement), run `scripts/changelog-lookup.sh <Changelog-ID>` (or an
issue number or keyword) and use the official changelog text instead of
guessing. It reads the vendor core first and falls back to a cached copy of
every core version's changelogs.

## Phase 5: Prove

Follow the `verify` skill. The migration is done only when all of these hold:

- `scripts/quality-gate.sh` exits 0 with the target core installed.
- For dual support, it also exits 0 after `composer require typo3/cms-core:<other line> -W`, and composer.json/composer.lock are restored afterwards.
- No test was deleted or skipped to get there, and no hook was bypassed. The plugin's guard hook blocks `--no-verify` and test deletion.
- The **migration-reviewer** agent has reviewed the full branch diff and nothing it rated `blocker` is left open.

A gate line marked `SKIPPED` is not a pass. Report it as a gap, together with
what would be needed to close it (for example, no functional test setup).

## Phase 6: Report

Give the user:

- the hops done and the constraints now declared
- the gate result per TYPO3 line, quoted from the actual run
- the ledger items left `deferred`, each with a reason
- any breaking change for the extension's own users (removed hooks, renamed classes, a raised PHP floor), phrased so it can go into the changelog

## Model and agent usage

| Agent | Model | Used for |
|---|---|---|
| `legacy-scout` | haiku | fast, read-only occurrence hunts per area |
| `migration-strategist` | opus | plan, hop sequencing, risk calls |
| `code-migrator` | sonnet | edits within one disjoint file set, self-checked |
| `migration-reviewer` | opus | adversarial review of the finished diff per target line |

Run scouts and migrators in parallel. Run the strategist and the reviewer
once each per hop. If the extension is small (under about 40 PHP files), skip
the agents and do the work directly: the phases stay the same.

## Rules that are never bent

- Never use `--no-verify`. Never delete, skip or `markTestSkipped()` a test to get a green run.
- Never edit `vendor/`, and never run Rector or Fractor on it.
- Never widen a constraint to a line that the gate has not proven.
- Never write a minor that does not exist in a constraint. For example, `^14.4` is wrong; use `^14.3`.
- Keep a raised PHP floor or a dropped TYPO3 line visible in the report. Don't bury it.
