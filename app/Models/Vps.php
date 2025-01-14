<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Vps extends Model
{
    protected $fillable = [
        'vendor_name',
        'cpu_model',
        'cpu_cores',
        'memory_gb',
        'storage_gb',
        'bandwidth_gb',
        'price',
        'currency',
        'start_date',
        'end_date',
    ];

    protected $dates = [
        'start_date',
        'end_date',
    ];

    public function getRemainingValueAttribute()
    {
        $now = Carbon::now();
        $remainingDays = $now->diffInDays($this->end_date);
        return $this->price * $remainingDays / 365;
    }

    public function getRemainingValueCnyAttribute()
    {
        $value = $this->remaining_value;
        if ($this->currency === 'CNY') {
            return $value;
        }

        $rate = ExchangeRate::where('currency', $this->currency)->first();
        if (!$rate) {
            return null;
        }

        $eurValue = $value / $rate->rate;
        $cnyRate = ExchangeRate::where('currency', 'CNY')->first();
        
        return $eurValue * $cnyRate->rate;
    }
} 