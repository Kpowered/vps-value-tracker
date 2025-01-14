<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ExchangeRate extends Model
{
    public $timestamps = false;
    
    protected $fillable = [
        'currency',
        'rate',
        'updated_at'
    ];

    protected $dates = [
        'updated_at'
    ];
} 