<?php

declare(strict_types=1);

namespace Acme\LegacyEvents\Controller;

use TYPO3\CMS\Core\Utility\GeneralUtility;
use TYPO3\CMS\Extbase\Mvc\Controller\ActionController;
use TYPO3\CMS\Extbase\Object\ObjectManager;
use TYPO3\CMS\Extbase\Persistence\Generic\PersistenceManager;

class EventController extends ActionController
{
    public function listAction(): void
    {
        $persistence = GeneralUtility::makeInstance(ObjectManager::class)->get(PersistenceManager::class);
        $category = (int)GeneralUtility::_GP('category');
        $pageId = $GLOBALS['TSFE']->id;
        $this->view->assignMultiple([
            'category' => $category,
            'pageId' => $pageId,
            'lang' => $GLOBALS['TSFE']->sys_language_uid,
        ]);
    }

    public function showAction(int $event = 0): void
    {
        if ($event === 0) {
            $this->forward('list');
        }
        $this->view->assign('event', $event);
    }
}
