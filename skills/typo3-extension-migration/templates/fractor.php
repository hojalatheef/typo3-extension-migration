<?php

// fractor.php - Fractor config for non-PHP files (a9f/typo3-fractor ^1; runs on PHP >= 8.2).
// Placeholders:
//   __TARGET_MAJOR__  lowest TYPO3 major you support, e.g. 13 (same as rector.php)
// Run: vendor/bin/fractor process --dry-run   (then without --dry-run, review the diff)

declare(strict_types=1);

use a9f\Fractor\Configuration\FractorConfiguration;
use a9f\Fractor\ValueObject\Indent;
use a9f\FractorTypoScript\Configuration\TypoScriptProcessorOption;
use a9f\FractorXml\Configuration\XmlProcessorOption;
use a9f\Typo3Fractor\Set\Typo3LevelSetList;
use Helmich\TypoScriptParser\Parser\Printer\PrettyPrinterConfiguration;

return FractorConfiguration::configure()
    ->withPaths([
        __DIR__ . '/Configuration',
        __DIR__ . '/Resources/Private',
    ])
    ->withSets([
        Typo3LevelSetList::UP_TO_TYPO3___TARGET_MAJOR__,
    ])
    ->withSkip([
        '*/node_modules/*',
        '*/vendor/*',
        '*/.Build/*',
        // Skip a single rule or a whole processor if its output doesn't fit, e.g.:
        // \a9f\FractorFluid\FluidFileProcessor::class,
    ])
    // Match your existing formatting so Fractor doesn't reformat untouched files.
    ->withOptions([
        TypoScriptProcessorOption::INDENT_SIZE => 4,
        TypoScriptProcessorOption::INDENT_CHARACTER => PrettyPrinterConfiguration::INDENTATION_STYLE_SPACES,
        TypoScriptProcessorOption::ADD_CLOSING_GLOBAL => false,
        TypoScriptProcessorOption::INCLUDE_EMPTY_LINE_BREAKS => true,
        TypoScriptProcessorOption::INDENT_CONDITIONS => true,
        XmlProcessorOption::INDENT_CHARACTER => Indent::STYLE_SPACE,
        XmlProcessorOption::INDENT_SIZE => 4,
    ]);
