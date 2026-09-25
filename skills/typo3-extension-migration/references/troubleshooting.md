# Troubleshooting upgrades

Before you debug anything else: flush all caches, including the DI container.

```bash
vendor/bin/typo3 cache:flush            # core CLI (v11+); v10: typo3-console or Install Tool
rm -rf var/cache/code/di var/cache/code/core   # composer mode; classic mode: typo3temp/var/cache/
composer dump-autoload
```

## Dependency injection

| Symptom | Cause | Fix |
| --- | --- | --- |
| `The "Vendor\X" service or alias has been removed or inlined when the container was compiled. You should either make it public, or stop using the container directly` | Service fetched via `GeneralUtility::makeInstance()` / `$container->get()` but not public | `public: true` on that service in Services.yaml, or inject it. Common for hooks, userFuncs, DataHandler hooks, Extbase validators, ViewHelpers fetched by name |
| `Cannot autowire service "Vendor\X": argument "$foo" of method "__construct()" has no type-hint` / `references class "Y" but no such service exists` | Scalar/untyped argument, interface without alias, or class not in the resource scan | Add `arguments: { $foo: '%env(...)%' }`, add an alias for the interface, or fix `resource`/`exclude` in Services.yaml |
| `Cannot autowire ... references class "TYPO3\CMS\...\Z" ... no such service exists` after a core upgrade | The core class was removed/renamed or became non-injectable on the new line | Check the changelog for the replacement; Rector often knows the rename |
| Constructor injection "does nothing", properties null | Class instantiated with `new` or `makeInstance()` bypassing DI with a non-public service; or `Services.yaml` missing entirely | Add `Configuration/Services.yaml`, make the class public or inject it, flush DI cache |
| `ArgumentCountError: Too few arguments to function __construct()` | Same as above: object created outside the container | Same as above |
| Changes to Services.yaml ignored | DI container cached | Flush `var/cache/code/di` (a normal "flush frontend caches" is not enough) |
| Event listener not called | Missing tag/attribute, wrong event class after rename, or attribute class doesn't exist on this line | Check System > Configuration > Event Listeners (EXT:lowlevel) for the registration |
| `Circular reference detected for service` | Two services inject each other, often introduced when replacing `makeInstance` with injection | Inject a factory / lazy service, or split the class |

## Autoloading and Composer

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Class "Vendor\MyExt\..." not found` after moving to composer.json autoload | PSR-4 mapping wrong or autoloader not rebuilt | Check `autoload.psr-4` (`"Vendor\\MyExt\\": "Classes/"`), run `composer dump-autoload`; classic mode: "Rebuild PHP autoload information" in Install Tool / `typo3 extension:setup` |
| `Class ... not found` for a core class after `composer update` | Class removed in the new major | Changelog + Rector; don't add aliases for core classes |
| `The TYPO3 extension package "vendor/pkg" does not define an extension key in its composer.json` | `extra.typo3/cms.extension-key` missing | Add it (must match the directory name / TER key) |
| Extension not active after upgrade in composer mode | Since v11 composer mode, every installed `typo3-cms-extension` package is active; `PackageStates.php` no longer used | Require/remove the package with Composer, then `typo3 extension:setup` |
| Composer can't resolve after bumping core | A `typo3/cms-*` package or dev tool (testing-framework, phpstan-typo3) still pinned to the old major | Bump all together; see `version-matrix.md` |
| `Your requirements could not be resolved ... typo3/cms-core ^14.4` | Non-existent minor | Use `^14.3` |
| Classic mode: extension "is not compatible" | ext_emconf.php `depends` not updated, or composer.json missing (mandatory since v14.0) | Update both files |

## Rector / Fractor

| Symptom | Cause | Fix |
| --- | --- | --- |
| Rector runs for ages / edits files in `vendor/` or `.Build/` | `withPaths([__DIR__])` includes everything | List source dirs explicitly (`Classes`, `Configuration`, `Tests`, `ext_*.php`) and `withSkip` `.Build`, `vendor`, `var`, `public` |
| `Class "TYPO3\CMS\..." not found` / "could not be autoloaded" inside Rector | Rector can't see TYPO3 classes | Run it inside the installed project (`composer install` first) or add `withAutoloadPaths` |
| Rector output uses APIs missing on the lower supported line | Level set higher than the lowest supported major | Set `Typo3LevelSetList::UP_TO_TYPO3_<lowest>` |
| TER upload fails after Rector run | `SafeDeclareStrictTypesRector` added `declare(strict_types=1)` to `ext_emconf.php` | Skip `*/ext_emconf.php` for that rule |
| Rector "Allowed memory size exhausted" | Large scan or cache | `--memory-limit=2G`, `--clear-cache`, narrow paths |
| Fractor refuses to run | PHP < 8.2 | Run it in a PHP 8.2+ container; it only edits files |
| Fractor reformats every TypoScript/XML file | Default indentation differs from yours | `withOptions` (`TypoScriptProcessorOption::INDENT_*`, `XmlProcessorOption::INDENT_*`) |

## PHPStan

| Symptom | Cause | Fix |
| --- | --- | --- |
| Thousands of new errors after upgrade | Level raised at the same time, new core type declarations, or `.Build`/`vendor` in `paths` | Change one thing at a time; keep level, restrict `paths` to own code, regenerate baseline per step: `vendor/bin/phpstan analyse --generate-baseline` |
| Baseline entries "Ignored error pattern ... was not matched" | Code fixed or messages changed on the new PHPStan/core | Regenerate baseline; keep `reportUnmatchedIgnoredErrors: true` so it shrinks |
| Different results per core line | Core types differ between lines | Separate baselines per line, or `phpVersion`/conditional config |
| `$GLOBALS['TYPO3_REQUEST']`, `GeneralUtility::makeInstance()`, Context aspects typed as `mixed` | phpstan-typo3 extension not loaded | Include `vendor/saschaegerer/phpstan-typo3/extension.neon` or use `phpstan/extension-installer` |
| Composer conflict on phpstan-typo3 | 1.x = PHPStan 1, 2.x = core 13.4.3+, 3.x = core 14 | `"^2.2 \|\| ^3.1"` for 13+14 |

## testing-framework / PHPUnit

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Class "TYPO3\TestingFramework\Core\Unit\UnitTestCase" not found` | testing-framework not installed or wrong major for this core | `require-dev` the major covering your core (see matrix) |
| Bootstrap fails: `Unable to determine path to entry script` / root path errors | Web dir unknown to the bootstrap | Set `extra.typo3/cms.web-dir` (e.g. `.Build/public`) and `config.vendor-dir` (`.Build/vendor`); older frameworks: export `TYPO3_PATH_ROOT` / `TYPO3_PATH_APP` |
| `bootstrap file ... UnitTestsBootstrap.php not found` | Path in phpunit XML still points to old location | Point to `.Build/vendor/typo3/testing-framework/Resources/Core/Build/UnitTestsBootstrap.php` (same folder for `FunctionalTestsBootstrap.php`) |
| Functional tests: `Missing typo3DatabaseName` / cannot connect | No DB env vars | For SQLite: `typo3DatabaseDriver=pdo_sqlite`. MySQL: `typo3DatabaseName/Host/Username/Password` |
| Functional tests: extension "not found" / not loaded | TF 8+ loads extensions as Composer packages; path-only loading is gone | Add the extension (and test fixture extensions) as packages; use `$testExtensionsToLoad = ['vendor/my-ext']` or the key, and `$coreExtensionsToLoad` for sysexts beyond the minimal set |
| PHPUnit: `@test` annotations ignored / "No tests executed" | PHPUnit 10+ dropped doc-block annotations for metadata (12 removed them completely) | Use `#[Test]`, `#[DataProvider]`; Rector `PHPUnitSetList::ANNOTATIONS_TO_ATTRIBUTES` |
| Data provider errors "must be public static" | PHPUnit 10+ | Make providers `public static` |
| Tests fail on deprecations only | `failOnDeprecation="true"` in the XML | Fix the deprecation; this setting is intended |
| `setUp()` state leaks between tests | `resetSingletonInstances` not set | `protected bool $resetSingletonInstances = true;` |
| CSV fixture import errors | Column removed in new core schema | Update fixtures; drop fields the schema no longer has |

## Fluid / frontend

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Undeclared arguments passed to ViewHelper Vendor\...: foo. Valid arguments are: ...` | Template passes an argument the ViewHelper doesn't register (stricter in newer Fluid) | `registerArgument()` in `initializeArguments()`, or remove the argument from the template |
| `ViewHelper class "..." does not exist` | Namespace not registered, or VH removed in core | Check `xmlns:` / `{namespace}` and the changelog |
| `Call to undefined method ...::renderStatic()` / trait not found | `CompileWithRenderStatic` / `renderStatic` removed | Implement `render()` |
| Output double-escaped or raw HTML escaped | Escaping defaults changed / wrong flags | Set `$escapeOutput = false` only where intended; use `f:format.raw` deliberately |
| Plugin renders nothing after upgrade | `list_type` plugin not migrated to CType, missing TypoScript include, or Site Set not added | Run upgrade wizards, check TypoScript tree, add set to site |
| TypoScript change has no effect | Parser rejected the file (v12+ strict parser), or file not auto-loaded because of old extension | Check the TypoScript tree view for errors; rename to `.typoscript` / `.tsconfig` |
| Backend module missing | Still registered in ext_tables.php (v12+ requires `Configuration/Backend/Modules.php`) | Move registration; flush caches |
| Backend JS 404 / `require is not defined` | RequireJS module on v13+ | Convert to ES module + `Configuration/JavaScriptModules.php` |
| Icons missing | `IconRegistry` call removed, `Icons.php` not present | Add `Configuration/Icons.php`; flush caches |

## Database and upgrade wizards

| Symptom | Cause | Fix |
| --- | --- | --- |
| SQL errors on new columns | Schema not updated | `vendor/bin/typo3 extension:setup` or Install Tool > Analyze Database Structure |
| `ext_tables.sql` parse error | Old syntax (e.g. explicit TCA-managed columns that core now auto-creates, `KEY` lengths) | Remove core-managed columns (v13 auto-creates many from TCA ctrl) and fix syntax |
| Content missing after plugin migration | Upgrade wizard not run | `vendor/bin/typo3 upgrade:list` / `upgrade:run` |
