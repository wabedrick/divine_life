<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Schedule automated branch report generation every Sunday at 11:59 PM
Schedule::command('reports:generate-weekly-branch')
    ->weeklyOn(0, '23:59')
    ->description('Generate automated weekly branch reports for super admin');
