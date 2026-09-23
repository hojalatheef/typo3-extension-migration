<?php

// rector.php - TYPO3 Rector config for an extension (ssch/typo3-rector ^3, rector/rector ^2).
// Placeholders:
//   __TARGET_MAJOR__     lowest TYPO3 major you support, e.g. 13 (dual 13+14 => 13)
//   __PHP_VERSION__      Rector PhpVersion constant for the lowest PHP you support, e.g. PHP_82
//   __PHP_LEVEL_SET__    matching LevelSetList constant, e.g. UP_TO_PHP_82
//   __TYPO3_CONSTRAINT__ ext_emconf 'typo3' range, e.g. '13.4.0-14.3.99'
//   __PHP_CONSTRAINT__   ext_emconf 'php' range, e.g. '8.2.0-8.5.99'
// Run: vendor/bin/rector process --dry-run   (then without --dry-run, review the diff)

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\TypeDeclaration\Rector\StmtsAwareInterface\SafeDeclareStrictTypesRector;
use Rector\ValueObject\PhpVersion;
use Ssch\TYPO3Rector\CodeQuality\General\ExtEmConfRector;
use Ssch\TYPO3Rector\Configuration\Typo3Option;
use Ssch\TYPO3Rector\Set\Typo3LevelSetList;
use Ssch\TYPO3Rector\Set\Typo3SetList;

return RectorConfig::configure()
    ->withPaths([
        __DIR__ . '/Classes',
        __DIR__ . '/Configuration',
        __DIR__ . '/Tests',
        __DIR__ . '/ext_emconf.php',
        __DIR__ . '/ext_localconf.php',
        __DIR__ . '/ext_tables.php',
    ])
    ->withPhpVersion(PhpVersion::__PHP_VERSION__)
    ->withSets([
        LevelSetList::__PHP_LEVEL_SET__,
        Typo3SetList::CODE_QUALITY,
        Typo3SetList::GENERAL,
        Typo3LevelSetList::UP_TO_TYPO3___TARGET_MAJOR__,
        // PHPUnit 10+ attributes (needs rector/rector's PHPUnit sets, bundled in rector ^2):
        // \Rector\PHPUnit\Set\PHPUnitSetList::ANNOTATIONS_TO_ATTRIBUTES,
    ])
    // Teaches Rector's PHPStan about TYPO3 (GeneralUtility::makeInstance return types etc.)
    ->withPHPStanConfigs([Typo3Option::PHPSTAN_FOR_RECTOR_PATH])
    ->withImportNames(importShortClasses: false, removeUnusedImports: true)
    ->withConfiguredRule(ExtEmConfRector::class, [
        ExtEmConfRector::TYPO3_VERSION_CONSTRAINT => '__TYPO3_CONSTRAINT__',
        ExtEmConfRector::PHP_VERSION_CONSTRAINT => '__PHP_CONSTRAINT__',
        ExtEmConfRector::ADDITIONAL_VALUES_TO_BE_REMOVED => [],
    ])
    // When dropping an old line, uncomment to remove Typo3Version checks below the new minimum:
    // ->withConfiguredRule(
    //     \Ssch\TYPO3Rector\CodeQuality\General\RemoveTypo3VersionChecksRector::class,
    //     [\Ssch\TYPO3Rector\CodeQuality\General\RemoveTypo3VersionChecksRector::TARGET_VERSION => __TARGET_MAJOR__]
    // )
    ->withSkip([
        __DIR__ . '/.Build',
        __DIR__ . '/vendor',
        __DIR__ . '/var',
        __DIR__ . '/public',
        __DIR__ . '/node_modules',
        // TER/Tailor cannot handle declare(strict_types=1) in ext_emconf.php
        SafeDeclareStrictTypesRector::class => [
            __DIR__ . '/ext_emconf.php',
        ],
    ]);
