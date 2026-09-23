<?php

// .php-cs-fixer.dist.php - TYPO3 Core coding standard via typo3/coding-standards.
// Version: ^0.9 needs PHP 8.2, ^0.8 PHP 8.1, ^0.7 PHP 8.0, ^0.6 PHP 7.2+.
// Alternative: composer exec typo3-coding-standards setup extension   (generates this file)
// Run: vendor/bin/php-cs-fixer fix --dry-run --diff

declare(strict_types=1);

$config = \TYPO3\CodingStandards\CsFixerConfig::create();
$config->getFinder()
    ->in(__DIR__)
    ->exclude(['.Build', 'vendor', 'var', 'public', 'node_modules']);

// Cache outside the source tree:
$config->setCacheFile(__DIR__ . '/.Build/.cache/.php-cs-fixer.cache');

return $config;
