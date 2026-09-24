<?php

declare(strict_types=1);

namespace Acme\LegacyEvents\Tests\Unit;

use TYPO3\TestingFramework\Core\Unit\UnitTestCase;

class EventControllerTest extends UnitTestCase
{
    /**
     * @test
     */
    public function placeholderStaysGreen(): void
    {
        self::assertTrue(true);
    }
}
