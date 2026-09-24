# typo3-extension-migration

A Claude Code plugin that moves TYPO3 extensions from one LTS line to the next,
anywhere from **v10 to v14**, and proves the result on every line it claims to support.

It is for extension code (your `Classes/`, `Configuration/`, `Resources/`).
It does not upgrade TYPO3 installations or sites.

## What you get

| Piece | Kind | What it does |
|---|---|---|
| `typo3-extension-migration` | skill | End-to-end workflow: recon → plan → automate → hand migration → prove → report, one major per hop, with a resumable `.migration/ledger.md` |
| `assess` | skill | Read-only sizing: versions, tooling, legacy API hits per hop, S/M/L/XL rating |
| `automate` | skill | Sets up and runs TYPO3 Rector + Fractor for one target major, in reviewable commits |
| `verify` | skill | Runs the quality gate per declared TYPO3 line and reports measured results |
| `legacy-scout` | agent (Haiku) | Fast parallel occurrence hunts per area |
| `migration-strategist` | agent (Opus) | Hop sequence, disjoint work packages, risks |
| `code-migrator` | agent (Sonnet) | Edits inside one work package and proves its slice |
| `migration-reviewer` | agent (Opus) | Adversarial review of the finished diff |
| guard hook | PreToolUse | Blocks `--no-verify`, test deletion and Rector/Fractor runs on `vendor/` |

Supporting material in `skills/typo3-extension-migration/`:

- `references/`: per-hop migration cards (v10→v11 … v13→v14), version matrix, dual-version support, non-PHP assets, troubleshooting
- `data/rules-*.tsv`: machine-readable legacy API rules used by the scanner
- `scripts/inventory.sh`, `scripts/scan-legacy-api.sh`, `scripts/quality-gate.sh`
- `templates/`: rector, fractor, phpstan, php-cs-fixer, phpunit and CI starting points

## Install

```bash
# as a marketplace (this repository is its own marketplace)
/plugin marketplace add hojalatheef/typo3-extension-migration
/plugin install typo3-extension-migration@typo3-extension-migration

# or for local development
claude --plugin-dir /path/to/typo3-extension-migration
```

Requirements on the machine running Claude Code: `bash`, `git`, `jq`, `grep`, `composer`, `php`.

## Use

Just ask:

- "Migrate this extension from TYPO3 11 to 13."
- "Add TYPO3 14 support but keep 13 working."
- "How much work is it to get this extension onto v14?"

Or invoke the skills directly:

```text
/typo3-extension-migration:assess 14
/typo3-extension-migration:typo3-extension-migration
/typo3-extension-migration:automate 13
/typo3-extension-migration:verify
```

The scripts also run without Claude:

```bash
skills/typo3-extension-migration/scripts/inventory.sh path/to/ext
skills/typo3-extension-migration/scripts/scan-legacy-api.sh --from 11 --to 13 --path path/to/ext
skills/typo3-extension-migration/scripts/quality-gate.sh path/to/ext
```

## How "done" is defined

A migration is finished when `quality-gate.sh` exits 0 with each declared
TYPO3 line installed, no test was removed or skipped to get there, no hook was
bypassed, and the reviewer agent has no open blocker. A tool that is not
installed shows up as `SKIPPED`, which is reported as a gap and never counted
as a pass.

The guard hook applies to Claude's own shell commands only. If you really
need to bypass a git hook, run the command yourself (for example `! git commit
--no-verify ...` in the prompt), or disable the plugin for that session.

## Develop

```bash
scripts/selftest.sh                 # manifests, frontmatter, rule syntax, scanner fixture, hook behaviour
claude plugin validate .            # Claude Code's own manifest validation
claude plugin eval . --runs 1       # behavioural evals in evals/
```

Adding a rule: append a row to the matching `data/rules-*.tsv`
(`id target level ext regex hint`, tab-separated, POSIX ERE), add or extend
the card in the matching `references/vNN-to-vMM.md`, and run the self-test.

## Author

Maintained by **Hoja Mustaffa Abdul Latheef** ([jweiland.net](https://jweiland.net), <hlatheef@jweiland.net>).

## License

GPL-2.0-or-later. See [LICENSE](LICENSE).
