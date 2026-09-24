<?php

declare(strict_types=1);

namespace Acme\LegacyEvents\Hooks;

use TYPO3\CMS\Core\DataHandling\DataHandler;

class DataHandlerHook
{
    public function processDatamap_afterDatabaseOperations($status, $table, $id, array $fields, DataHandler $dataHandler): void
    {
        if ($table !== 'tx_legacyevents_domain_model_event') {
            return;
        }
        $GLOBALS['TYPO3_DB']->exec_UPDATEquery($table, 'uid=' . (int)$id, ['tstamp' => time()]);
    }
}
