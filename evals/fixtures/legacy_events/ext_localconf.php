<?php

defined('TYPO3_MODE') or die();

\TYPO3\CMS\Extbase\Utility\ExtensionUtility::configurePlugin(
    'LegacyEvents',
    'List',
    [\Acme\LegacyEvents\Controller\EventController::class => 'list,show'],
    [\Acme\LegacyEvents\Controller\EventController::class => 'list']
);

$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['t3lib/class.t3lib_tcemain.php']['processDatamapClass'][]
    = \Acme\LegacyEvents\Hooks\DataHandlerHook::class;
