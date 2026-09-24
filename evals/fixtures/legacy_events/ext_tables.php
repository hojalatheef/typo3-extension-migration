<?php

defined('TYPO3_MODE') or die();

\TYPO3\CMS\Extbase\Utility\ExtensionUtility::registerModule(
    'LegacyEvents',
    'web',
    'events',
    '',
    [\Acme\LegacyEvents\Controller\EventController::class => 'list'],
    ['access' => 'user,group', 'labels' => 'LLL:EXT:legacy_events/Resources/Private/Language/locallang_mod.xlf']
);

\TYPO3\CMS\Core\Utility\ExtensionManagementUtility::allowTableOnStandardPages('tx_legacyevents_domain_model_event');
