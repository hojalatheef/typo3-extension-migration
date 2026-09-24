---
type: llm
weight: 2
---

PASS if the answer treats this as two hops (11→12, then 12→13) and names at least four of: ObjectManager removal, `$GLOBALS['TSFE']` access, `GeneralUtility::_GP`, Extbase actions that must return a ResponseInterface / `forward()` removal, `registerModule` in ext_tables.php → `Configuration/Backend/Modules.php`, the SC_OPTIONS DataHandler hook, `$GLOBALS['TYPO3_DB']`, TCA `eval`/`renderType` changes (datetime, number, link, required), `cruser_id`, RequireJS `define()` → ES modules. It must also give an effort rating and note the missing QA tooling (no Rector/PHPStan/PHPUnit installed).
FAIL if it claims the upgrade is a constraint bump, invents APIs, or modifies files.
