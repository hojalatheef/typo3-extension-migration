# Supporting two LTS lines from one codebase

Typical pairs: 12.4 + 13.4 (a 12 LTS extension that also works on 13) and 13.4 + 14.3 (the usual pair
in 2026). Supporting more than two lines is rarely worth the cost.

## 1. Declare the range

composer.json:

```json
{
  "require": {
    "php": "^8.2",
    "typo3/cms-core": "^13.4 || ^14.3",
    "typo3/cms-extbase": "^13.4 || ^14.3",
    "typo3/cms-fluid": "^13.4 || ^14.3"
  },
  "require-dev": {
    "typo3/testing-framework": "^9.0",
    "saschaegerer/phpstan-typo3": "^2.2 || ^3.1"
  },
  "extra": {
    "typo3/cms": {
      "extension-key": "my_ext",
      "web-dir": ".Build/public"
    }
  }
}
```

ext_emconf.php (still needed for v13 classic mode and TER):

```php
'constraints' => [
    'depends' => [
        'typo3' => '13.4.0-14.3.99',
        'php' => '8.2.0-8.5.99',
    ],
],
```

Rules:
- The PHP lower bound is the lower line's minimum; do not use syntax newer than that (e.g. no PHP 8.3 typed
  class constants if 8.2 is still allowed).
- The Rector level is the lower line (`UP_TO_TYPO3_13` for 13+14). Rules for the higher line are applied only
  by hand, behind feature detection.
- The Rector `PhpVersion` / `withPhpSets(php82: true)` is the lower PHP bound.

## 2. Feature detection

Prefer detecting the API itself over comparing version numbers. Version numbers are fine for behaviour
changes that have no symbol to test for.

| Technique | Use when | Example |
| --- | --- | --- |
| `class_exists()` / `interface_exists()` | A class was added or removed | `class_exists(\TYPO3\CMS\Core\Attribute\AsEventListener::class)` |
| `method_exists()` | A method was added, renamed or removed | `method_exists($request, 'getAttribute')` |
| `Typo3Version` | Behaviour changed without a symbol change | see below |
| `ReflectionMethod` / parameter count | A signature changed | only as a last resort |

```php
use TYPO3\CMS\Core\Information\Typo3Version;
use TYPO3\CMS\Core\Utility\GeneralUtility;

$isV14 = GeneralUtility::makeInstance(Typo3Version::class)->getMajorVersion() >= 14;
```

`Typo3Version` exists since 10.3 and has no dependencies, so `new Typo3Version()` also works in
ext_localconf.php, TCA and Services.php. Do not use the `TYPO3_version` / `TYPO3_branch` constants
(removed in v12).

Keep the branches small: put the version-specific code behind one adapter class or a private method,
mark it `// @todo remove when dropping v13`, and grep for it when you drop the old line.
`RemoveTypo3VersionChecksRector` (typo3-rector) removes `Typo3Version` checks automatically later.

### Attributes that may not exist on the lower line

A PHP attribute whose class doesn't exist is ignored at runtime, so `#[AsEventListener]` on 12.4
won't fail, but it won't register the listener either. Register such services in `Services.yaml`
(works everywhere) or conditionally in `Services.php`. PHPStan will report the unknown class on the lower
line; ignore it there or scope the rule.

## 3. Conditional service registration (Configuration/Services.php)

`Services.yaml` can't branch. Keep the shared config in YAML and add a `Services.php` next to it for the
version-dependent parts; TYPO3 loads both.

```php
<?php
declare(strict_types=1);

use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;
use TYPO3\CMS\Core\Information\Typo3Version;

return static function (ContainerConfigurator $container, ContainerBuilder $builder): void {
    $services = $container->services()->defaults()->autowire()->autoconfigure();

    if ((new Typo3Version())->getMajorVersion() >= 14) {
        $services->set(\Vendor\MyExt\Compat\V14\PageRendererAdapter::class);
        $services->alias(\Vendor\MyExt\Compat\PageRendererAdapterInterface::class,
            \Vendor\MyExt\Compat\V14\PageRendererAdapter::class);
    } else {
        $services->set(\Vendor\MyExt\Compat\V13\PageRendererAdapter::class);
        $services->alias(\Vendor\MyExt\Compat\PageRendererAdapterInterface::class,
            \Vendor\MyExt\Compat\V13\PageRendererAdapter::class);
    }
};
```

Exclude the `Compat/V*` directories from the YAML resource scan
(`exclude: '../Classes/Compat/*'`), or the scan will autowire a class whose dependencies don't exist on the
running line. The container is compiled and cached (`var/cache/code/di`), so flush caches after switching
core versions locally.

## 4. TCA across versions

- Put all changes to foreign tables in `Configuration/TCA/Overrides/*.php`; these run on every line.
- Own tables: `Configuration/TCA/<table>.php` returns the array. Branch inside it if needed:

```php
$v = (new \TYPO3\CMS\Core\Information\Typo3Version())->getMajorVersion();
$tca = [ /* shared definition */ ];
if ($v < 13) {
    // v13 auto-creates enablecolumns/language fields from ctrl; v12 needs explicit columns
    $tca['columns']['hidden'] = [ /* ... */ ];
}
return $tca;
```

- Write the TCA syntax of the higher line when the lower line accepts it. The TCA migration layer then
  handles it without deprecations. Examples: `items` with `label`/`value` keys (12+), `type => 'number'`,
  `type => 'datetime'`, `type => 'link'`, `required => true` (12+). If the lower line is 11, it does not
  know these; branch or keep the old syntax.
- Keep an eye on deprecation logs for TCA migrations on the higher line. They list the exact keys to change
  before the next major removes the migration.
- Do not use `ExtensionManagementUtility` methods deprecated on the higher line when a TCA-array
  alternative exists on both.

## 5. CI matrix

Test every declared line at both ends of its PHP range. Minimum for 13+14:

| TYPO3 | PHP | Composer | Jobs |
| --- | --- | --- | --- |
| ^13.4 | 8.2 | `--prefer-lowest` | unit, functional |
| ^13.4 | 8.5 | highest | unit, functional, phpstan |
| ^14.3 | 8.2 | highest | unit, functional |
| ^14.3 | 8.5 | highest | unit, functional, phpstan, rector --dry-run, fractor --dry-run |

- Install per cell: `composer require --no-update "typo3/cms-core:^14.3"` (plus the other `typo3/cms-*`),
  then `composer update`. Don't commit composer.lock for an extension.
- Run php-cs-fixer once, on the newest PHP.
- Run PHPStan per core line. Keep one baseline per line if the lines differ
  (`phpstan-baseline-v13.neon`, `phpstan-baseline-v14.neon`, chosen via an env-specific config).
- Run Rector `--dry-run` only on the job matching the lower-line level; its job is to catch regressions,
  not to migrate.
- Optional "next" job with `allow-failure` against `dev-main` of core.

Template: `templates/github-ci.yml`.

## 6. When NOT to support two lines

- The lower line is out of free community support (as of 2026-09: v12 and older). Tag a last release for it
  and move on; ELTS customers can pin that tag.
- The code would need branches in many places: e.g. the extension hooks deep into the backend UI,
  FormEngine, the page module, or `TypoScriptFrontendController` internals that changed between the lines.
  More than a handful of adapters means two branches (`release/13`, `main`) are cheaper.
- The lower line needs a PHP version the higher line has dropped, or the tooling majors don't overlap
  (testing-framework, PHPStan 1 vs 2).
- The JS/backend-module stack changed (v11 to v12: RequireJS to ES modules, `Modules.php`). Dual-supporting
  11+12 usually means keeping both registration styles. Only do it if the extension is small.
- You can't test the lower line in CI. Untested dual support is only a claim, so don't declare it.

When dropping a line: tighten composer.json and ext_emconf.php in the same commit, remove the matrix cells,
delete the `Compat` code for that line, and run `RemoveTypo3VersionChecksRector` with the new minimum.
