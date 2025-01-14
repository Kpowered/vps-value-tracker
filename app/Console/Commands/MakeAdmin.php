<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;

class MakeAdmin extends Command
{
    protected $signature = 'make:admin';
    protected $description = 'Create an admin user';

    public function handle()
    {
        $email = $this->ask('请输入管理员邮箱');
        $password = $this->secret('请输入管理员密码');
        $confirmPassword = $this->secret('请确认密码');

        if ($password !== $confirmPassword) {
            $this->error('密码不匹配！');
            return 1;
        }

        User::create([
            'name' => 'Admin',
            'email' => $email,
            'password' => Hash::make($password),
        ]);

        $this->info('管理员账户创建成功！');
        return 0;
    }
} 