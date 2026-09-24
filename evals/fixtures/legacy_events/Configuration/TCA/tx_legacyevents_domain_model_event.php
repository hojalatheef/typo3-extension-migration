<?php

return [
    'ctrl' => [
        'title' => 'Event',
        'label' => 'title',
        'tstamp' => 'tstamp',
        'crdate' => 'crdate',
        'cruser_id' => 'cruser_id',
        'delete' => 'deleted',
        'enablecolumns' => ['disabled' => 'hidden'],
        'iconfile' => 'EXT:legacy_events/Resources/Public/Icons/event.svg',
    ],
    'columns' => [
        'title' => [
            'label' => 'Title',
            'config' => ['type' => 'input', 'size' => 30, 'eval' => 'trim,required'],
        ],
        'start' => [
            'label' => 'Start',
            'config' => ['type' => 'input', 'renderType' => 'inputDateTime', 'eval' => 'datetime,int'],
        ],
        'seats' => [
            'label' => 'Seats',
            'config' => ['type' => 'input', 'eval' => 'int'],
        ],
        'website' => [
            'label' => 'Website',
            'config' => ['type' => 'input', 'renderType' => 'inputLink'],
        ],
        'kind' => [
            'label' => 'Kind',
            'config' => [
                'type' => 'select',
                'renderType' => 'selectSingle',
                'items' => [['Talk', 'talk'], ['Workshop', 'workshop']],
            ],
        ],
    ],
    'types' => ['0' => ['showitem' => 'title, start, seats, website, kind']],
];
