# TYPO3 version matrix (v10 - v14)

Source of truth for constraints, tooling versions and set names. Checked 2026-09. When in doubt, re-check
`https://get.typo3.org/api/v1/major/` (dates, PHP range) and Packagist (tool constraints).

## Core lines

| Major | LTS minor | LTS released | Regular support ends | ELTS ends (paid) | PHP (min - max) |
|---|---|---|---|---|---|
| 10 | 10.4 | 2020-04-21 | 2023-04-30 | 2027-04-30 | 7.2 - 7.4 |
| 11 | 11.5 | 2021-10-05 | 2024-10-31 | 2028-10-31 | 7.4.1 - 8.3 |
| 12 | 12.4 | 2023-04-25 | 2026-04-30 | 2030-04-30 | 8.1 - 8.4 |
| 13 | 13.4 | 2024-10-15 | 2027-12-31 | 2030-12-31 | 8.2 - 8.5 |
| 14 | 14.3 | 2026-04-21 | 2029-06-30 | 2032-06-30 | 8.2 - 8.5 |

As of 2026-09: only 13.4 and 14.3 receive free community updates. 10/11/12 are ELTS-only.
Pre-LTS sprint releases (x.0 - x.3 before the LTS) are unsupported once the LTS is out.

## Constraints to write

| Target | composer.json `require` | ext_emconf.php `constraints.depends.typo3` | PHP in composer.json | ext_emconf `php` |
|---|---|---|---|---|
| v10 | `"typo3/cms-core": "^10.4"` | `'10.4.0-10.4.99'` | `"^7.2"` | `'7.2.0-7.4.99'` |
| v11 | `"typo3/cms-core": "^11.5"` | `'11.5.0-11.5.99'` | `"^7.4 \|\| ^8.0"` | `'7.4.0-8.3.99'` |
| v12 | `"typo3/cms-core": "^12.4"` | `'12.4.0-12.4.99'` | `"^8.1"` | `'8.1.0-8.4.99'` |
| v13 | `"typo3/cms-core": "^13.4"` | `'13.4.0-13.4.99'` | `"^8.2"` | `'8.2.0-8.5.99'` |
| v14 | `"typo3/cms-core": "^14.3"` | `'14.3.0-14.3.99'` (typo3-rector's default template uses `'14.0.0-14.3.99'`) | `"^8.2"` | `'8.2.0-8.5.99'` |
| v13 + v14 | `"^13.4 \|\| ^14.3"` | `'13.4.0-14.3.99'` | `"^8.2"` | `'8.2.0-8.5.99'` |
| v12 + v13 | `"^12.4 \|\| ^13.4"` | `'12.4.0-13.4.99'` | `"^8.1"` | `'8.1.0-8.5.99'` |
| v11 + v12 | `"^11.5 \|\| ^12.4"` | `'11.5.0-12.4.99'` | `"^7.4 \|\| ^8.0"` | `'7.4.0-8.4.99'` |

Every other `typo3/cms-*` system extension you require (extbase, fluid, frontend, backend, ...) must carry
the same constraint as `typo3/cms-core`.

ext_emconf.php status:
- v14.0: a valid `composer.json` is mandatory for every extension, also in classic mode.
- v14.2: `ext_emconf.php` is deprecated (Deprecation #108345). You can leave it out once `composer.json` has
  `extra.typo3/cms.version` (or top-level `version`) and `extra.typo3/cms.Package.providesPackages` (`{}` if
  there are none). Keep it as long as you publish to TER via Tailor, or support v13 or older.
- `extra.typo3/cms.extension-key` must be present in composer.json (required since v11 composer installers).

## Tooling per target

| Target | typo3/testing-framework | PHPUnit | saschaegerer/phpstan-typo3 | PHPStan |
|---|---|---|---|---|
| v10 | `^6` | 8.4 / 9 | `^1.9` (1.10.0 is the last one covering 10.4) | 1.x |
| v11 | `^6` or `^7` | 9 / 10 | `^1.10` | 1.x |
| v12 | `^7` or `^8` | 10 / 11 | `^1.10` | 1.x |
| v13 | `^8` or `^9` | 10-13 | `^2.0` (requires core ^13.4.3); 1.10.x also covers 13 with PHPStan 1 | 2.x |
| v14 | `^9` (10.x on main targets 14/15, not tagged yet) | 11 / 12 / 13 | `^3.0` (requires core ^14.0) | 2.1.33+ |

testing-framework support details: 6.x = TYPO3 10/11 (PHP >= 7.2), 7.x = 11/12 (PHP >= 7.4),
8.x = 12/13 (PHP >= 8.1), 9.x = 13/14 (PHP >= 8.2). Pick the one major that covers both lines when dual-supporting.

phpstan-typo3 has no single major covering v13 and v14. For a 13+14 matrix require
`"saschaegerer/phpstan-typo3": "^2.2 || ^3.1"` and let Composer resolve per job.

### TYPO3 Rector (`ssch/typo3-rector`)

- v1: TYPO3 7 - 12. v2/v3: TYPO3 10 - 14, PHP files only. v3 requires `rector/rector ^2`.
- Classes: `Ssch\TYPO3Rector\Set\Typo3LevelSetList` (cumulative) and `Ssch\TYPO3Rector\Set\Typo3SetList` (single major).

| Target | Level set (use this) | Single-version set | `RemoveTypo3VersionChecksRector::TARGET_VERSION` |
|---|---|---|---|
| v10 | `Typo3LevelSetList::UP_TO_TYPO3_10` | `Typo3SetList::TYPO3_10` | 10 |
| v11 | `Typo3LevelSetList::UP_TO_TYPO3_11` | `Typo3SetList::TYPO3_11` | 11 |
| v12 | `Typo3LevelSetList::UP_TO_TYPO3_12` | `Typo3SetList::TYPO3_12` | 12 |
| v13 | `Typo3LevelSetList::UP_TO_TYPO3_13` | `Typo3SetList::TYPO3_13` | 13 |
| v14 | `Typo3LevelSetList::UP_TO_TYPO3_14` | `Typo3SetList::TYPO3_14` | 14 |

Also available: `Typo3SetList::CODE_QUALITY`, `Typo3SetList::GENERAL`, `Typo3Option::PHPSTAN_FOR_RECTOR_PATH`
(`Ssch\TYPO3Rector\Configuration\Typo3Option`), `ExtEmConfRector` (updates ext_emconf constraints).

Dual support: set the level to the LOWEST supported major. Rules from a higher level may emit code that
does not exist on the lower line.

### Fractor (`a9f/typo3-fractor`)

- Install `a9f/typo3-fractor` only; it pulls `a9f/fractor`, `a9f/fractor-fluid`, `-typoscript`, `-xml`,
  `-yaml`, `-htaccess`, `-xliff`. Current major: 1.x. Needs PHP >= 8.2 to run (it can run in a separate
  PHP 8.2+ container against older code).
- Classes: `a9f\Fractor\Configuration\FractorConfiguration`, `a9f\Typo3Fractor\Set\Typo3LevelSetList`
  (`UP_TO_TYPO3_7` ... `UP_TO_TYPO3_14`), `a9f\Typo3Fractor\Set\Typo3SetList` (`TYPO3_7` ... `TYPO3_14`).

### Coding standards (`typo3/coding-standards`)

| Version | PHP |
|---|---|
| 0.9 | ^8.2 |
| 0.8 | ^8.1 |
| 0.7 | ^8.0 |
| 0.6 | ^7.2 \|\| ^8.0 |

Run php-cs-fixer on one fixed PHP job in CI rather than across the matrix.

## Constraint mistakes to catch

| Mistake | Why it breaks | Correct |
|---|---|---|
| `^14.4`, `^13.5`, `^12.5`, `^11.6` | The minor does not exist; Composer cannot resolve. LTS is the last minor of each line. | `^14.3`, `^13.4`, `^12.4`, `^11.5` |
| `'14.4.0-14.4.99'` or `'13.0.0-13.9.99'` in ext_emconf | Wrong upper bound; the Extension Manager rejects the extension or allows versions that don't exist | `'14.3.0-14.3.99'`, `'13.4.0-13.4.99'` |
| Replacing `^12.4` with `^13.4` while the plan says "support 12 and 13" | Drops the old line without anyone noticing | `^12.4 \|\| ^13.4`, and check the CI matrix still has a 12 job |
| composer.json and ext_emconf.php disagree | Composer mode and classic mode/TER allow different versions | Update both in the same commit (or let `ExtEmConfRector` do it) |
| Only `typo3/cms-core` bumped, `typo3/cms-extbase` etc. left at old major | Unresolvable or silently pinned install | Bump every `typo3/cms-*` together |
| `"typo3/cms-core": "*"` or `">=12"` | Claims compatibility with future majors that were never tested | Caret per LTS line |
| PHP lower bound below core's minimum (e.g. `^7.4` with only v13) | Misleading; installs fail on the core side | Match the lowest supported core's PHP min |
| testing-framework major not covering every core in the matrix | Resolution fails in one CI cell | Pick the major that spans both (see table) |
| Constraint `^14.3` in composer.json but CI matrix still `^14.0@dev` | CI tests something you don't ship | Keep matrix values equal to the declared constraints |
| `dev-main` / `@dev` on core in `require` | Unstable installs for users | Only use in a CI "next" job, never in the shipped constraint |
