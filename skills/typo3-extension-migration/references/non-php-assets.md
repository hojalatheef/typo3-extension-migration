# Migrations outside PHP classes

TYPO3 Rector covers PHP (classes, TCA arrays, ext_localconf.php, ext_tables.php, ext_emconf.php).
Everything else is either Fractor (`a9f/typo3-fractor`) or manual. Run Fractor with the same level as Rector
(`Typo3LevelSetList::UP_TO_TYPO3_<N>`) and review every diff.

## Automation coverage

| Area | Fractor | Manual |
| --- | --- | --- |
| TypoScript / TSconfig | Legacy conditions to Symfony expression syntax, `getTSFE()` in conditions, `loginUser`/`usergroup` conditions, `page` conditions, `<INCLUDE_TYPOSCRIPT:>` to `@import`, removed `config.*` options (e.g. `config.language`, `sys_language_*`, `concatenateJs/Css`, `simulateStaticDocuments`), `typolink.useCacheHash`, removed TSconfig options | Moving files to the auto-load locations, static template to Site Set, `lib.*` rewrites, custom userFunc conditions, data processors |
| FlexForm XML | Remove `<TCEforms>` wrapper, `items` to associative keys, `eval=int/double2` to `type=number`, `eval=email`, `eval=required`/`null` flags, `internal_type=folder`, colorpicker to `type=color`, password types | Switching to `type=file`, `renderType` changes not covered, sheet restructuring |
| Fluid templates | `f:be.infobox` severity constants, `noCacheHash`/`useCacheHash` removal, `f:case default` to `f:defaultCase` | ViewHelper namespace changes, custom ViewHelpers (PHP, i.e. Rector), removed ViewHelpers, layout paths |
| YAML (Form, Services) | Form `EmailFinisher` options, form translation file keys | Services.yaml changes |
| XLIFF | Available as processor | Moving to XLIFF 2 / cleanup |
| htaccess | Remove `uploads/` rules from the default file | Server config |
| composer.json | Generic rules (add/remove packages) | `extra.typo3/cms` keys, constraints |
| JS / CSS | none | Everything |
| Configuration/*.php (Icons, Modules, JavaScriptModules) | none (Rector has some rules for registration moves) | Mostly manual |

Full rule list: `packages/typo3-fractor/docs/typo3-fractor-rules.md` in the Fractor repository.

## TypoScript and TSconfig

| Topic | Change | Version |
| --- | --- | --- |
| Conditions | `[globalVar = ...]`, `[PIDinRootline = ...]` etc. to `[tree.rootLineIds ...]`, `[request...]`, `[site(...)]` expression syntax | Old syntax removed in v10 |
| `getTSFE()` in conditions | Use `request.getPageArguments()`, `frontend.page`, `site()` | Deprecated in later lines; Fractor migrates |
| Includes | `<INCLUDE_TYPOSCRIPT: source="FILE:...">` to `@import 'EXT:my_ext/Configuration/TypoScript/setup.typoscript'` | `@import` since v9; old syntax deprecated and removed later |
| File endings | `.txt`/`.ts` to `.typoscript` / `.tsconfig` | Some auto-loading only picks up the new endings |
| Page TSconfig | Place in `Configuration/page.tsconfig`; loaded automatically. Remove `ExtensionManagementUtility::addPageTSConfig()` from ext_localconf.php | v12.0 |
| User TSconfig | Place in `Configuration/user.tsconfig`; loaded automatically. Remove `addUserTSConfig()` | v13.0 |
| Site-scoped page TSconfig | `page.tsconfig` inside a Site Set or site config folder | v13.1 (sets) |
| Static templates | `addStaticFile()` in `Configuration/TCA/Overrides/sys_template.php` still works; for v13+ also offer a Site Set | v13.1+ |
| `config.*` cleanup | Many options removed with the new frontend rendering (language, charset, doctype switches) | v12 / v13 |

Parser changes: v12 introduced a new TypoScript parser. It is stricter about unbalanced braces, conditions
inside braces (not allowed) and `[end]`/`[global]`. Check the Template module / TypoScript tree view
for parse errors after upgrading.

## FlexForms

- Remove the `<TCEforms>` wrapper around `<config>`/`<label>` (not needed since v12; Fractor does this).
- Use the same config vocabulary as TCA: `type=number`, `type=email`, `type=datetime`, `type=link`,
  `type=file`, `required=1`, `items` with `label`/`value`.
- Register the FlexForm in TCA Overrides: `ExtensionManagementUtility::addPiFlexFormValue()` still works up
  to v13. For content element-based plugins (v13+, v14 default), set it via
  `$GLOBALS['TCA']['tt_content']['types'][<CType>]['columnsOverrides']['pi_flexform']['config']['ds']`
  or the `addPlugin()`/`registerPlugin()` FlexForm argument, depending on the target line.
- Plugins registered as `list_type` subtypes are deprecated in v13.4. Migrate to CType plugins
  (`ExtensionUtility::PLUGIN_TYPE_CONTENT_ELEMENT`) and ship an upgrade wizard for existing records.

## Fluid

| Topic | Change |
| --- | --- |
| Namespaces | `{namespace x=Vendor\Ext\ViewHelpers}` or `xmlns:x="http://typo3.org/ns/Vendor/Ext/ViewHelpers"`; register global ones in `$GLOBALS['TYPO3_CONF_VARS']['SYS']['fluid']['namespaces']` |
| Custom ViewHelpers | Declare every argument in `initializeArguments()` (`registerArgument`). Undeclared arguments throw. Replace `renderStatic()` / `CompileWithRenderStatic` with `render()` and `$this->arguments` / `$this->renderingContext` (removed in newer Fluid) |
| Escaping | Set `$escapeOutput`/`$escapeChildren` explicitly. Don't rely on defaults |
| Request access | `$this->renderingContext->getAttribute(ServerRequestInterface::class)` (newer lines) instead of `getControllerContext()` (removed v12) |
| Removed VHs | e.g. `f:widget.*` (removed v11); grep templates against the removed-ViewHelper entries in each changelog |
| Paths | TypoScript `templateRootPaths` numeric keys; Site Set / v13 `PAGEVIEW` for page templates |

## Services.yaml

```yaml
services:
  _defaults:
    autowire: true
    autoconfigure: true
    public: false
  Vendor\MyExt\:
    resource: '../Classes/*'
    exclude: '../Classes/Domain/Model/*'
```

- Classes fetched via `GeneralUtility::makeInstance()` from non-DI code (hooks, userFuncs, some legacy
  entry points) must be `public: true` or be constructor-free.
- Event listeners: `tags: [{ name: event.listener, identifier: '...' }]`; v13+ `#[AsEventListener]`.
- Commands: `console.command` tag; v12+ also `#[AsCommand]` (Symfony).
- Backend controllers: `backend.controller` tag or the `#[AsController]` attribute (check which the lowest supported line has).
- Exclude Extbase models, DTOs and version-specific compat classes from the resource scan.

## ext_localconf.php / ext_tables.php

| Legacy | Replacement | Since |
| --- | --- | --- |
| `ExtensionUtility::registerModule()` / `addModule()` in ext_tables.php | `Configuration/Backend/Modules.php` | v12 |
| `IconRegistry->registerIcon()` in ext_localconf.php | `Configuration/Icons.php` | v11.4 |
| `addPageTSConfig()` | `Configuration/page.tsconfig` | v12 |
| `addUserTSConfig()` | `Configuration/user.tsconfig` | v13 |
| `allowTableOnStandardPages()` | TCA `ctrl.security.ignorePageTypeRestriction` | v12 |
| `$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']` hooks | PSR-14 events (check changelog per hook) | ongoing |
| `addLLrefForTCAdescr()` (CSH) | removed; use TCA `description` | v12 |
| `PageRenderer->loadRequireJsModule()` | `loadJavaScriptModule()` | v12 |
| `defined('TYPO3_MODE') or die()` | `defined('TYPO3') or die()` | v11 (constant removed v12) |

Keep ext_localconf.php/ext_tables.php free of code that needs a request or a booted DI container.

## ext_emconf.php vs composer.json

- composer.json is authoritative in Composer mode and mandatory for all extensions since v14.0.
- ext_emconf.php is deprecated since v14.2. To drop it, composer.json must contain
  `extra.typo3/cms.version` (or top-level `version`) and `extra.typo3/cms.Package.providesPackages` (`{}`
  when empty). Keep it while you support v13 or older in classic mode or publish via TER/Tailor.
- `extra.typo3/cms.extension-key` is required.
- Keep constraints identical in both files (see `version-matrix.md`).

## JavaScript

| From | To | Since |
| --- | --- | --- |
| RequireJS AMD modules (`define([...])`, `Resources/Public/JavaScript/*.js` loaded via `TYPO3/CMS/MyExt/Foo`) | Native ES modules with `import`/`export`, mapped in `Configuration/JavaScriptModules.php` | v12 (RequireJS deprecated), v13 (removed) |
| `loadRequireJsModule('TYPO3/CMS/MyExt/Foo')` | `loadJavaScriptModule('@vendor/my-ext/foo.js')` | v12 |
| jQuery-dependent backend JS | Core no longer guarantees jQuery for new modules; use native DOM / Lit | v12+ |
| `TYPO3.jQuery`, `top.TYPO3.*` globals | Import the core ES modules (`@typo3/backend/...`) | v12+ |

```php
<?php
// Configuration/JavaScriptModules.php
return [
    'dependencies' => ['backend'],
    'imports' => [
        '@vendor/my-ext/' => 'EXT:my_ext/Resources/Public/JavaScript/',
    ],
];
```

For 11+12 dual support you have to ship both: AMD for 11, ESM for 12. That is a strong reason not to
dual-support that pair.

## Icons.php

```php
<?php
// Configuration/Icons.php
use TYPO3\CMS\Core\Imaging\IconProvider\SvgIconProvider;

return [
    'my-ext-plugin' => [
        'provider' => SvgIconProvider::class,
        'source' => 'EXT:my_ext/Resources/Public/Icons/plugin.svg',
    ],
];
```

## Backend Modules.php

```php
<?php
// Configuration/Backend/Modules.php
return [
    'web_myext' => [
        'parent' => 'web',
        'position' => ['after' => 'web_info'],
        'access' => 'user',
        'path' => '/module/web/myext',
        'labels' => 'LLL:EXT:my_ext/Resources/Private/Language/locallang_mod.xlf',
        'iconIdentifier' => 'my-ext-module',
        'extensionName' => 'MyExt',
        'controllerActions' => [
            \Vendor\MyExt\Controller\BackendController::class => ['index', 'show'],
        ],
    ],
];
```

- Extbase modules: `extensionName` + `controllerActions`. Non-Extbase: `routes` with `target`.
- Module controllers use `ModuleTemplateFactory` / `ModuleTemplate` and return a `ResponseInterface`.
- Check `parent` identifiers and `position` targets against the core modules of the target line.

## Site Sets (v13.1+)

```
Configuration/Sets/MyExt/
  config.yaml          name: vendor/my-ext, label, dependencies
  setup.typoscript
  constants.typoscript
  settings.definitions.yaml
  page.tsconfig
```

- Sets replace static TypoScript templates for site-based setups; settings replace most constants.
- For 12+13 dual support keep `sys_template` static includes and add the Set on top. The v12 site ignores
  the folder.

## XLIFF

- File locations: `Resources/Private/Language/locallang*.xlf`; `EXT:` references in `LLL:`.
- Remove `.xml` (llxml) language files; convert to XLIFF.
- Keep full `LLL:EXT:my_ext/Resources/Private/Language/<file>.xlf:<key>` references. They work on every line.
- Target-language files (`de.locallang.xlf`) usually come from Crowdin/translation server. Don't hand-edit
  them in the migration.
