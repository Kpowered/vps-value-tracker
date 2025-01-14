#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}开始安装 VPS Value Tracker...${NC}"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 检测系统版本
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo "无法检测操作系统版本"
    exit 1
fi

echo -e "${YELLOW}检测到操作系统: $OS $VER${NC}"

# 安装基础工具
apt-get update
apt-get install -y curl wget gnupg2 ca-certificates lsb-release apt-transport-https software-properties-common

# 添加 PHP 仓库
echo -e "${YELLOW}添加 PHP 仓库...${NC}"
curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# 删除之前的 MySQL 仓库配置
rm -f /etc/apt/sources.list.d/mysql.list
rm -f /usr/share/keyrings/mysql.gpg

# 安装 MariaDB
echo -e "${YELLOW}安装 MariaDB...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server

# 确保 MariaDB 服务启动
echo -e "${YELLOW}启动 MariaDB 服务...${NC}"
systemctl enable mariadb
systemctl start mariadb

# 等待 MariaDB 启动（最多等待 30 秒）
echo -e "${YELLOW}等待 MariaDB 启动...${NC}"
counter=0
while ! systemctl is-active --quiet mariadb && [ $counter -lt 30 ]; do
    sleep 1
    ((counter++))
done

if ! systemctl is-active --quiet mariadb; then
    echo -e "${RED}MariaDB 启动失败${NC}"
    exit 1
fi

# 设置 MariaDB root 密码
echo -e "${YELLOW}配置 MariaDB...${NC}"
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)

# 安全配置
mysql -e "UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

# 验证连接
if ! mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;" 2>/dev/null; then
    echo -e "${RED}MariaDB 配置失败${NC}"
    exit 1
fi

# 添加 Nginx 仓库
echo -e "${YELLOW}添加 Nginx 仓库...${NC}"
curl -sSLo /usr/share/keyrings/nginx-archive-keyring.gpg https://nginx.org/keys/nginx_signing.key
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -sc) nginx" > /etc/apt/sources.list.d/nginx.list

# 更新软件包列表
apt-get update

# 安装 PHP 和其他依赖
echo -e "${YELLOW}安装 PHP 和其他依赖...${NC}"
apt-get install -y nginx php8.1-fpm php8.1-mysql php8.1-mbstring \
    php8.1-xml php8.1-curl php8.1-zip php8.1-cli php8.1-intl \
    composer certbot python3-certbot-nginx git unzip

# 确保 PHP-FPM 服务存在并启动
systemctl enable php8.1-fpm
systemctl start php8.1-fpm

# 创建数据库和用户
read -p "请输入数据库名称 (默认: vps_tracker): " dbname
dbname=${dbname:-vps_tracker}
read -p "请输入数据库用户名 (默认: vps_user): " dbuser
dbuser=${dbuser:-vps_user}
read -s -p "请输入数据库密码: " dbpass
echo

# 删除并重新创建用户和数据库
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS ${dbname};"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DROP USER IF EXISTS '${dbuser}'@'localhost';"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS '${dbuser}'@'localhost' IDENTIFIED BY '${dbpass}';"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${dbuser}'@'localhost';"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# 保存 MySQL root 密码到安全位置
echo "MySQL root 密码: $MYSQL_ROOT_PASSWORD" > /root/.mysql_root_password
chmod 600 /root/.mysql_root_password

# 安装 Laravel 安装器
echo -e "${YELLOW}安装 Laravel 安装器...${NC}"
composer global require laravel/installer

# 创建 Laravel 项目
echo -e "${YELLOW}创建 Laravel 项目...${NC}"
cd /var/www
if [ -d "vps-value-tracker" ]; then
    echo -e "${YELLOW}删除已存在的项目目录...${NC}"
    rm -rf vps-value-tracker
fi

composer create-project laravel/laravel vps-value-tracker
cd vps-value-tracker

# 创建必要的目录和文件
echo -e "${YELLOW}创建项目文件...${NC}"

# 创建 Models 目录
mkdir -p app/Models

# 创建 Vps 模型
cat > app/Models/Vps.php << 'EOF'
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
EOF

# 创建 ExchangeRate 模型
cat > app/Models/ExchangeRate.php << 'EOF'
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
EOF

# 创建 VpsController
mkdir -p app/Http/Controllers
cat > app/Http/Controllers/VpsController.php << 'EOF'
<?php

namespace App\Http\Controllers;

use App\Models\Vps;
use Illuminate\Http\Request;
use Carbon\Carbon;

class VpsController extends Controller
{
    public function index()
    {
        $vpsList = Vps::all();
        return view('vps.index', compact('vpsList'));
    }

    public function create()
    {
        return view('vps.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'vendor_name' => 'required|string|max:255',
            'cpu_model' => 'required|string|max:255',
            'cpu_cores' => 'required|integer|min:1',
            'memory_gb' => 'required|integer|min:1',
            'storage_gb' => 'required|integer|min:1',
            'bandwidth_gb' => 'required|integer|min:1',
            'price' => 'required|numeric|min:0',
            'currency' => 'required|string|size:3',
        ]);

        $validated['start_date'] = Carbon::now();
        $validated['end_date'] = Carbon::now()->addYear();

        Vps::create($validated);

        return redirect()->route('vps.index')->with('success', 'VPS added successfully');
    }

    public function destroy(Vps $vps)
    {
        $vps->delete();
        return redirect()->route('vps.index')->with('success', 'VPS deleted successfully');
    }
}
EOF

# 创建布局目录
mkdir -p resources/views/layouts

# 创建布局文件
cat > resources/views/layouts/app.blade.php << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VPS Value Tracker</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
</head>
<body class="bg-gray-100">
    <nav class="bg-white shadow mb-4">
        <div class="container mx-auto px-4 py-4">
            <div class="flex justify-between">
                <a href="{{ route('vps.index') }}" class="text-xl font-bold">VPS Value Tracker</a>
                @auth
                    <div>
                        <a href="{{ route('vps.create') }}" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">Add VPS</a>
                        <form action="{{ route('logout') }}" method="POST" class="inline">
                            @csrf
                            <button type="submit" class="text-gray-600 hover:text-gray-800 ml-4">Logout</button>
                        </form>
                    </div>
                @else
                    <a href="{{ route('login') }}" class="text-gray-600 hover:text-gray-800">Login</a>
                @endauth
            </div>
        </div>
    </nav>

    <main class="container mx-auto px-4">
        @yield('content')
    </main>
</body>
</html>
EOF

# 创建 VPS 视图目录
mkdir -p resources/views/vps

# 创建 index 视图
cat > resources/views/vps/index.blade.php << 'EOF'
@extends('layouts.app')

@section('content')
<div class="bg-white rounded-lg shadow p-6">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">VPS List</h1>
        @auth
            <a href="{{ route('vps.create') }}" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
                Add New VPS
            </a>
        @endauth
    </div>

    @if(session('success'))
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
            {{ session('success') }}
        </div>
    @endif

    <div class="overflow-x-auto">
        <table class="min-w-full table-auto">
            <thead>
                <tr class="bg-gray-100">
                    <th class="px-4 py-2">Vendor</th>
                    <th class="px-4 py-2">CPU</th>
                    <th class="px-4 py-2">Memory</th>
                    <th class="px-4 py-2">Storage</th>
                    <th class="px-4 py-2">Bandwidth</th>
                    <th class="px-4 py-2">Price</th>
                    <th class="px-4 py-2">Remaining Value</th>
                    <th class="px-4 py-2">Expires</th>
                    @auth
                        <th class="px-4 py-2">Actions</th>
                    @endauth
                </tr>
            </thead>
            <tbody>
                @forelse($vpsList as $vps)
                <tr class="border-b hover:bg-gray-50">
                    <td class="px-4 py-2">{{ $vps->vendor_name }}</td>
                    <td class="px-4 py-2">{{ $vps->cpu_model }} ({{ $vps->cpu_cores }} cores)</td>
                    <td class="px-4 py-2">{{ $vps->memory_gb }} GB</td>
                    <td class="px-4 py-2">{{ $vps->storage_gb }} GB</td>
                    <td class="px-4 py-2">{{ $vps->bandwidth_gb }} GB</td>
                    <td class="px-4 py-2">
                        {{ number_format($vps->price, 2) }} {{ $vps->currency }}
                    </td>
                    <td class="px-4 py-2">
                        {{ number_format($vps->remaining_value, 2) }} {{ $vps->currency }}
                        <br>
                        <span class="text-sm text-gray-600">
                            ≈ ¥{{ number_format($vps->remaining_value_cny, 2) }}
                        </span>
                    </td>
                    <td class="px-4 py-2">{{ $vps->end_date->format('Y-m-d') }}</td>
                    @auth
                        <td class="px-4 py-2">
                            <form action="{{ route('vps.destroy', $vps) }}" method="POST" class="inline">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="text-red-600 hover:text-red-800"
                                        onclick="return confirm('Are you sure you want to delete this VPS?')">
                                    Delete
                                </button>
                            </form>
                        </td>
                    @endauth
                </tr>
                @empty
                <tr>
                    <td colspan="9" class="px-4 py-8 text-center text-gray-500">
                        No VPS records found. @auth Click "Add New VPS" to add one. @endauth
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
EOF

# 创建 create 视图
cat > resources/views/vps/create.blade.php << 'EOF'
@extends('layouts.app')

@section('content')
<div class="max-w-2xl mx-auto bg-white rounded-lg shadow p-6">
    <h2 class="text-2xl font-bold mb-6">Add New VPS</h2>

    <form method="POST" action="{{ route('vps.store') }}">
        @csrf

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="mb-4">
                <label for="vendor_name" class="block text-gray-700 mb-2">Vendor Name</label>
                <input type="text" name="vendor_name" id="vendor_name" 
                    class="form-input w-full rounded" required>
            </div>

            <div class="mb-4">
                <label for="cpu_model" class="block text-gray-700 mb-2">CPU Model</label>
                <input type="text" name="cpu_model" id="cpu_model" 
                    class="form-input w-full rounded" required>
            </div>

            <div class="mb-4">
                <label for="cpu_cores" class="block text-gray-700 mb-2">CPU Cores</label>
                <select name="cpu_cores" id="cpu_cores" class="form-select w-full rounded" required>
                    @for($i = 1; $i <= 32; $i++)
                        <option value="{{ $i }}">{{ $i }}</option>
                    @endfor
                </select>
            </div>

            <div class="mb-4">
                <label for="memory_gb" class="block text-gray-700 mb-2">Memory (GB)</label>
                <select name="memory_gb" id="memory_gb" class="form-select w-full rounded" required>
                    @foreach([1, 2, 4, 8, 16, 32, 64, 128] as $size)
                        <option value="{{ $size }}">{{ $size }} GB</option>
                    @endforeach
                </select>
            </div>

            <div class="mb-4">
                <label for="storage_gb" class="block text-gray-700 mb-2">Storage (GB)</label>
                <input type="number" name="storage_gb" id="storage_gb" 
                    class="form-input w-full rounded" required>
            </div>

            <div class="mb-4">
                <label for="bandwidth_gb" class="block text-gray-700 mb-2">Bandwidth (GB)</label>
                <input type="number" name="bandwidth_gb" id="bandwidth_gb" 
                    class="form-input w-full rounded" required>
            </div>

            <div class="mb-4">
                <label for="price" class="block text-gray-700 mb-2">Price (per year)</label>
                <input type="number" step="0.01" name="price" id="price" 
                    class="form-input w-full rounded" required>
            </div>

            <div class="mb-4">
                <label for="currency" class="block text-gray-700 mb-2">Currency</label>
                <select name="currency" id="currency" class="form-select w-full rounded" required>
                    <option value="CNY">CNY - Chinese Yuan</option>
                    <option value="USD">USD - US Dollar</option>
                    <option value="EUR">EUR - Euro</option>
                    <option value="JPY">JPY - Japanese Yen</option>
                </select>
            </div>
        </div>

        <div class="mt-6">
            <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
                Add VPS
            </button>
            <a href="{{ route('home') }}" class="ml-2 text-gray-600 hover:text-gray-800">
                Cancel
            </a>
        </div>
    </form>
</div>
@endsection
EOF

# 更新 .env 文件
sed -i "s/APP_NAME=.*/APP_NAME=\"VPS Value Tracker\"/" .env
sed -i "s/APP_ENV=.*/APP_ENV=production/" .env
sed -i "s/APP_DEBUG=.*/APP_DEBUG=false/" .env
sed -i "s/APP_URL=.*/APP_URL=http:\/\/${domain:-localhost}/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${dbname}/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${dbuser}/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${dbpass}/" .env

# 添加 Fixer API key
echo "FIXER_API_KEY=9fc7824eeb86c023e2ba423a80f17f9b" >> .env

# 设置目录权限
chown -R www-data:www-data /var/www/vps-value-tracker
chmod -R 755 /var/www/vps-value-tracker
chmod -R 775 storage bootstrap/cache

# 运行数据库迁移
php artisan migrate:fresh --force

# 清除缓存
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# 创建管理员账户
echo -e "${YELLOW}创建管理员账户${NC}"
password=$(openssl rand -base64 12)
php artisan tinker << EOF
use App\Models\User;
User::truncate();
User::create(['name' => 'Admin', 'email' => 'admin@example.com', 'password' => Hash::make('${password}')]);
EOF

echo -e "${GREEN}管理员账户创建成功！${NC}"
echo -e "管理员密码: ${password}"
echo -e "请保存此密码，它只会显示一次。"

# 配置Nginx
echo -e "${YELLOW}正在配置Nginx...${NC}"
read -p "请输入域名 (如果没有请直接回车): " domain

# 删除所有默认和可能冲突的配置
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/vps-tracker
rm -f /etc/nginx/sites-available/vps-tracker
rm -f /etc/nginx/conf.d/*.conf

# 确保目录存在
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

if [ -n "$domain" ]; then
    # 配置带域名的Nginx配置
    cat > /etc/nginx/sites-available/vps-tracker << EOF
server {
    listen 80;
    server_name ${domain:-_};
    root /var/www/vps-value-tracker/public;
    
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    
    index index.php;
    
    charset utf-8;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    
    error_page 404 /index.php;
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
else
    # 配置不带域名的Nginx配置
    cat > /etc/nginx/sites-available/vps-tracker << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    root /var/www/vps-value-tracker/public;
    index index.php;
    
    charset utf-8;
    
    # 安全头部
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    
    error_page 404 /index.php;
    
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
fi

# 创建符号链接
ln -sf /etc/nginx/sites-available/vps-tracker /etc/nginx/sites-enabled/

# 测试 Nginx 配置
nginx -t

# 如果配置测试成功，重启 Nginx
if [ $? -eq 0 ]; then
    systemctl restart nginx
else
    echo -e "${RED}Nginx 配置测试失败${NC}"
    exit 1
fi

# 如果指定了域名，配置 SSL
if [ -n "$domain" ]; then
    echo -e "${YELLOW}正在配置SSL...${NC}"
    certbot --nginx -d ${domain} --non-interactive --agree-tos --email admin@${domain} || {
        echo -e "${RED}SSL 配置失败，但网站仍可通过 HTTP 访问${NC}"
    }
fi

# 配置定时任务
echo "* * * * * cd /var/www/vps-value-tracker && php artisan schedule:run >> /dev/null 2>&1" | crontab -

# 创建迁移文件
mkdir -p database/migrations

# VPS 表迁移
cat > database/migrations/2024_01_14_000001_create_vps_table.php << 'EOF'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('vps', function (Blueprint $table) {
            $table->id();
            $table->string('vendor_name');
            $table->string('cpu_model');
            $table->integer('cpu_cores');
            $table->integer('memory_gb');
            $table->integer('storage_gb');
            $table->integer('bandwidth_gb');
            $table->decimal('price', 10, 2);
            $table->string('currency', 3);
            $table->timestamp('start_date');
            $table->timestamp('end_date');
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('vps');
    }
};
EOF

# 汇率表迁移
cat > database/migrations/2024_01_14_000002_create_exchange_rates_table.php << 'EOF'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateExchangeRatesTable extends Migration
{
    public function up()
    {
        Schema::create('exchange_rates', function (Blueprint $table) {
            $table->id();
            $table->string('currency', 3);
            $table->decimal('rate', 10, 4);
            $table->timestamp('updated_at');
        });
    }

    public function down()
    {
        Schema::dropIfExists('exchange_rates');
    }
}
EOF

# 更新路由文件
cat > routes/web.php << 'EOF'
<?php

use App\Http\Controllers\VpsController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('vps.index');
});

Route::get('/vps', [VpsController::class, 'index'])->name('vps.index');

Route::middleware(['auth'])->group(function () {
    Route::get('/vps/create', [VpsController::class, 'create'])->name('vps.create');
    Route::post('/vps', [VpsController::class, 'store'])->name('vps.store');
    Route::delete('/vps/{vps}', [VpsController::class, 'destroy'])->name('vps.destroy');
});

require __DIR__.'/auth.php';
EOF

# 创建 auth 路由文件
cat > routes/auth.php << 'EOF'
<?php

use App\Http\Controllers\Auth\AuthenticatedSessionController;
use App\Http\Controllers\Auth\RegisteredUserController;
use Illuminate\Support\Facades\Route;

Route::middleware('guest')->group(function () {
    Route::get('login', [AuthenticatedSessionController::class, 'create'])
        ->name('login');

    Route::post('login', [AuthenticatedSessionController::class, 'store']);
});

Route::middleware('auth')->group(function () {
    Route::post('logout', [AuthenticatedSessionController::class, 'destroy'])
        ->name('logout');
});
EOF

# 创建认证控制器目录
mkdir -p app/Http/Controllers/Auth

# 创建 AuthenticatedSessionController
cat > app/Http/Controllers/Auth/AuthenticatedSessionController.php << 'EOF'
<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AuthenticatedSessionController extends Controller
{
    public function create()
    {
        return view('auth.login');
    }

    public function store(LoginRequest $request)
    {
        $request->authenticate();
        $request->session()->regenerate();
        return redirect()->intended('/');
    }

    public function destroy(Request $request)
    {
        Auth::guard('web')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect('/');
    }
}
EOF

# 创建 LoginRequest
mkdir -p app/Http/Requests/Auth
cat > app/Http/Requests/Auth/LoginRequest.php << 'EOF'
<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'password' => ['required', 'string'],
        ];
    }

    public function authenticate(): void
    {
        // 获取第一个用户（管理员）
        $admin = \App\Models\User::first();
        
        if (!$admin || !password_verify($this->password, $admin->password)) {
            throw ValidationException::withMessages([
                'password' => ['Invalid password.'],
            ]);
        }

        Auth::login($admin, $this->boolean('remember'));
    }
}
EOF

# 创建 User 模型
cat > app/Models/User.php << 'EOF'
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
    ];
}
EOF

# 创建认证视图目录
mkdir -p resources/views/auth

# 创建登录视图
cat > resources/views/auth/login.blade.php << 'EOF'
@extends('layouts.app')

@section('content')
<div class="max-w-md mx-auto bg-white rounded-lg shadow p-6">
    <h2 class="text-2xl font-bold mb-6">Login</h2>

    <form method="POST" action="{{ route('login') }}">
        @csrf

        <div class="mb-4">
            <label for="password" class="block text-gray-700 mb-2">Password</label>
            <input type="password" name="password" id="password" class="form-input w-full rounded" required autofocus>
            @error('password')
                <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
            @enderror
        </div>

        <div class="mb-6">
            <label class="flex items-center">
                <input type="checkbox" name="remember" class="form-checkbox">
                <span class="ml-2">Remember me</span>
            </label>
        </div>

        <button type="submit" class="w-full bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
            Login
        </button>
    </form>
</div>
@endsection
EOF

# 创建用户表迁移
cat > database/migrations/2014_10_12_000000_create_users_table.php << 'EOF'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->rememberToken();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
EOF

# 创建 make:admin 命令
mkdir -p app/Console/Commands
cat > app/Console/Commands/MakeAdmin.php << 'EOF'
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
        // 删除所有现有用户
        User::truncate();

        $password = $this->secret('Enter admin password') ?: 'admin123';

        User::create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => Hash::make($password),
        ]);

        $this->info('Admin user created successfully!');
        $this->info("Password: " . ($password === 'admin123' ? 'admin123 (default)' : '(as entered)'));
    }
}
EOF

# 创建 Kernel.php
cat > app/Console/Kernel.php << 'EOF'
<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    protected $commands = [
        \App\Console\Commands\MakeAdmin::class,
    ];

    protected function schedule(Schedule $schedule)
    {
        // $schedule->command('inspire')->hourly();
    }

    protected function commands()
    {
        $this->load(__DIR__.'/Commands');
        require base_path('routes/console.php');
    }
}
EOF

# 更新 .env 文件
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${dbname}/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${dbuser}/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${dbpass}/" .env

# 清除缓存
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

echo -e "${GREEN}安装完成！${NC}"
echo -e "MySQL root 密码已保存到 /root/.mysql_root_password"
echo -e "管理员密码: ${password}"
if [ -n "$domain" ]; then
    echo -e "请访问 https://${domain} 来使用您的VPS Value Tracker"
else
    echo -e "请访问 http://服务器IP 来使用您的VPS Value Tracker"
fi 