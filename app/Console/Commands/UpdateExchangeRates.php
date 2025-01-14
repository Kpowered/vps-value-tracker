<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use App\Models\ExchangeRate;
use Carbon\Carbon;

class UpdateExchangeRates extends Command
{
    protected $signature = 'exchange-rates:update';
    protected $description = 'Update exchange rates from Fixer.io';

    public function handle()
    {
        $response = Http::get('http://data.fixer.io/api/latest', [
            'access_key' => '9fc7824eeb86c023e2ba423a80f17f9b',
            'base' => 'EUR',
            'symbols' => 'USD,CNY,GBP,CAD,JPY'
        ]);

        if ($response->successful()) {
            $rates = $response->json()['rates'];
            $now = Carbon::now();

            foreach ($rates as $currency => $rate) {
                ExchangeRate::updateOrCreate(
                    ['currency' => $currency],
                    [
                        'rate' => $rate,
                        'updated_at' => $now
                    ]
                );
            }

            $this->info('Exchange rates updated successfully.');
        } else {
            $this->error('Failed to update exchange rates.');
        }
    }
} 