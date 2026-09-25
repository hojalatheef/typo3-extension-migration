# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `scripts/changelog-lookup.sh`: prints the official TYPO3 core changelog entry for a changelog id, issue number or keyword, from the vendor core or a cached sparse clone of `TYPO3/typo3`. The main skill, `code-migrator` and `migration-reviewer` use it instead of guessing.
- README: workflow flowchart, agent roles and how the agents communicate.
- GitHub CI workflow with a status badge in the README.
- `package.json` (private) with `npm test`, lint and `release:check` scripts; the self-test checks that its version matches `plugin.json`.

## [0.1.0] - 2026-09-24

### Added

- Main `typo3-extension-migration` skill with a hop-by-hop workflow and resumable ledger.
- `assess`, `automate` and `verify` skills.
- Agents: `legacy-scout`, `migration-strategist`, `code-migrator`, `migration-reviewer`.
- Rule-driven legacy API scanner, inventory and quality-gate scripts.
- Migration cards for v10→v11, v11→v12, v12→v13 and v13→v14, plus cross-cutting references and config templates.
- PreToolUse guard hook and plugin self-test.
