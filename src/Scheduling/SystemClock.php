<?php

declare(strict_types=1);

namespace Kekke\Mononoke\Scheduling;

use DateTimeImmutable;

final class SystemClock implements Clock
{
    public function now(): DateTimeImmutable
    {
        return new DateTimeImmutable();
    }
}
