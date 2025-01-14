<?php

use App\Http\Controllers\VpsController;
use App\Http\Controllers\Auth\LoginController;
use Illuminate\Support\Facades\Route;

// 公开路由
Route::get('/', [VpsController::class, 'index'])->name('home');

// 认证路由
Route::get('login', [LoginController::class, 'showLoginForm'])->name('login');
Route::post('login', [LoginController::class, 'login']);
Route::post('logout', [LoginController::class, 'logout'])->name('logout');

// 需要认证的路由
Route::middleware(['auth'])->group(function () {
    Route::resource('vps', VpsController::class)->except(['index', 'show']);
});

require __DIR__.'/auth.php'; 