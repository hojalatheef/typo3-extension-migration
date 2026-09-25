# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- v12 → v13 card "ext_tables.sql: columns now derived from TCA": new **Keep** list (tables without TCA, non-TCA columns, indexes, MM tables with their own `uid` key) and a **Prove it** step with before/after schema compare and the changes to expect on 14.3.
- v12 → v13 card "TCA ctrl `cruser_id` leftover": also remove hard-coded writes in import code; the DB compare drops the column in two runs.
- Troubleshooting: rows for a schema compare that silently printed nothing, `Duplicate entry` on an auto-created MM table, and `Unknown column 'cruser_id'`.

## [1.0.0] - 2026-09-25

### Added

- `scripts/changelog-lookup.sh`: prints the official TYPO3 core changelog entry for a changelog id, issue number or keyword, from the vendor core or a cached sparse clone of `TYPO3/typo3`. The main skill, `code-migrator` and `migration-reviewer` use it instead of guessing.
- README: workflow flowchart, agent roles and how the agents communicate.
- GitHub CI workflow (`npm test` and `claude plugin validate --strict`) with a status badge in the README.
- `package.json` (private) with `npm test`, lint and `release:check` scripts; the self-test checks that its version matches `plugin.json`.

### Changed

- License is now MIT (was GPL-2.0-or-later).

## [0.1.0] - 2026-09-24

### Added

- Main `typo3-extension-migration` skill with a hop-by-hop workflow and resumable ledger.
- `assess`, `automate` and `verify` skills.
- Agents: `legacy-scout`, `migration-strategist`, `code-migrator`, `migration-reviewer`.
- Rule-driven legacy API scanner, inventory and quality-gate scripts.
- Migration cards for v10→v11, v11→v12, v12→v13 and v13→v14, plus cross-cutting references and config templates.
- PreToolUse guard hook and plugin self-test.
