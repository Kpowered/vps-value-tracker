from fastapi import FastAPI, Request, Form, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import aiosqlite
import aiohttp
from datetime import datetime, timedelta
import json
from passlib.context import CryptContext
from jose import JWTError, jwt
from fastapi.security import OAuth2PasswordBearer
from fastapi import Depends, Cookie
import secrets
from typing import Optional

app = FastAPI()

# HTML模板直接嵌入到代码中
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>VPS Value Tracker</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container py-4">
        <div class="d-flex justify-content-between mb-4">
            <h1>VPS Value Tracker</h1>
            {% if user %}
                <button class="btn btn-primary" onclick="showAddVpsModal()">添加 VPS</button>
            {% else %}
                <button class="btn btn-outline-primary" onclick="showLoginModal()">登录</button>
            {% endif %}
        </div>

        <div class="table-responsive">
            <table class="table">
                <thead>
                    <tr>
                        <th>商家</th>
                        <th>配置</th>
                        <th>价格</th>
                        <th>剩余价值(CNY)</th>
                        <th>到期时间</th>
                    </tr>
                </thead>
                <tbody id="vpsTable">
                    {% for vps in vps_list %}
                    <tr>
                        <td>{{ vps.vendor_name }}</td>
                        <td>
                            {{ vps.cpu_cores }}核 {{ vps.cpu_model }}<br>
                            {{ vps.memory }}GB 内存<br>
                            {{ vps.storage }}GB 硬盘<br>
                            {{ vps.bandwidth }}GB 流量
                        </td>
                        <td>{{ vps.price }} {{ vps.currency }}</td>
                        <td class="remaining-value" 
                            data-price="{{ vps.price }}"
                            data-currency="{{ vps.currency }}"
                            data-end-date="{{ vps.end_date }}">
                            计算中...
                        </td>
                        <td>{{ vps.end_date }}</td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>

    <!-- 登录模态框 -->
    <div class="modal fade" id="loginModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">登录</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="loginForm">
                        <div class="mb-3">
                            <label class="form-label">用户名</label>
                            <input type="text" class="form-control" name="username" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">密码</label>
                            <input type="password" class="form-control" name="password" required>
                        </div>
                        <button type="submit" class="btn btn-primary">登录</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- 添加VPS模态框 -->
    <div class="modal fade" id="addVpsModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">添加 VPS</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="addVpsForm">
                        <div class="mb-3">
                            <label class="form-label">商家名称</label>
                            <input type="text" class="form-control" name="vendor_name" required>
                        </div>
                        <div class="row mb-3">
                            <div class="col">
                                <label class="form-label">CPU核心数</label>
                                <input type="number" class="form-control" name="cpu_cores" required>
                            </div>
                            <div class="col">
                                <label class="form-label">CPU型号</label>
                                <input type="text" class="form-control" name="cpu_model">
                            </div>
                        </div>
                        <div class="row mb-3">
                            <div class="col">
                                <label class="form-label">内存(GB)</label>
                                <input type="number" class="form-control" name="memory" required>
                            </div>
                            <div class="col">
                                <label class="form-label">硬盘(GB)</label>
                                <input type="number" class="form-control" name="storage" required>
                            </div>
                        </div>
                        <div class="row mb-3">
                            <div class="col">
                                <label class="form-label">流量(GB)</label>
                                <input type="number" class="form-control" name="bandwidth" required>
                            </div>
                            <div class="col">
                                <label class="form-label">价格</label>
                                <input type="number" class="form-control" name="price" step="0.01" required>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">货币</label>
                            <select class="form-control" name="currency" required>
                                <option value="CNY">人民币</option>
                                <option value="USD">美元</option>
                                <option value="EUR">欧元</option>
                                <option value="GBP">英镑</option>
                                <option value="CAD">加元</option>
                                <option value="JPY">日元</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">到期时间</label>
                            <input type="date" class="form-control" name="end_date" required>
                        </div>
                        <button type="submit" class="btn btn-primary">添加</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // JavaScript代码
        async function loadVpsList() {
            const response = await fetch('/api/vps');
            const data = await response.json();
            // 更新表格...
        }

        async function login(event) {
            event.preventDefault();
            const form = event.target;
            const response = await fetch('/api/login', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(Object.fromEntries(new FormData(form)))
            });
            if (response.ok) {
                location.reload();
            }
        }

        async function addVps(event) {
            event.preventDefault();
            const form = event.target;
            const response = await fetch('/api/vps', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(Object.fromEntries(new FormData(form)))
            });
            if (response.ok) {
                location.reload();
            }
        }

        document.getElementById('loginForm').addEventListener('submit', login);
        document.getElementById('addVpsForm').addEventListener('submit', addVps);
    </script>
</body>
</html>
'''

# 数据库初始化
async def init_db():
    async with aiosqlite.connect('vps.db') as db:
        await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE,
                password TEXT
            )
        ''')
        await db.execute('''
            CREATE TABLE IF NOT EXISTS vps (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                vendor_name TEXT,
                cpu_cores INTEGER,
                cpu_model TEXT,
                memory INTEGER,
                storage INTEGER,
                bandwidth INTEGER,
                price REAL,
                currency TEXT,
                start_date TEXT,
                end_date TEXT,
                user_id INTEGER
            )
        ''')
        await db.commit()

@app.on_event("startup")
async def startup_event():
    await init_db()

# 配置
SECRET_KEY = secrets.token_urlsafe(32)
FIXER_API_KEY = "9fc7824eeb86c023e2ba423a80f17f9b"
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# 汇率缓存
exchange_rates_cache = {"timestamp": 0, "rates": {}}

# 辅助函数
async def get_exchange_rates():
    now = datetime.now().timestamp()
    if now - exchange_rates_cache["timestamp"] > 86400:  # 24小时更新一次
        async with aiohttp.ClientSession() as session:
            async with session.get(f"http://data.fixer.io/api/latest?access_key={FIXER_API_KEY}&base=EUR") as response:
                data = await response.json()
                if data["success"]:
                    exchange_rates_cache["rates"] = data["rates"]
                    exchange_rates_cache["timestamp"] = now
    return exchange_rates_cache["rates"]

async def convert_to_cny(amount: float, currency: str) -> float:
    if currency == "CNY":
        return amount
    rates = await get_exchange_rates()
    if currency in rates and "CNY" in rates:
        # 先转换为EUR，再转换为CNY
        eur_amount = amount / rates[currency]
        return eur_amount * rates["CNY"]
    return amount

async def calculate_remaining_value(price: float, currency: str, end_date: str) -> float:
    end = datetime.strptime(end_date, "%Y-%m-%d")
    days_remaining = (end - datetime.now()).days
    if days_remaining < 0:
        return 0
    yearly_value = await convert_to_cny(price, currency)
    return round(yearly_value * days_remaining / 365, 2)

# API路由实现
@app.post("/api/login")
async def login(username: str = Form(...), password: str = Form(...)):
    async with aiosqlite.connect('vps.db') as db:
        async with db.execute('SELECT * FROM users WHERE username = ?', [username]) as cursor:
            user = await cursor.fetchone()
            
        if not user:
            # 创建第一个用户
            hashed_password = pwd_context.hash(password)
            await db.execute('INSERT INTO users (username, password) VALUES (?, ?)', 
                           [username, hashed_password])
            await db.commit()
            return {"success": True}
            
        if not pwd_context.verify(password, user[2]):
            raise HTTPException(status_code=401, detail="Invalid credentials")
            
        token = jwt.encode({"sub": username}, SECRET_KEY)
        response = {"success": True}
        response.headers["Set-Cookie"] = f"session={token}; Path=/; HttpOnly"
        return response

@app.post("/api/vps")
async def add_vps(vps_data: dict, session: str = Cookie(None)):
    if not session:
        raise HTTPException(status_code=401)
    
    try:
        payload = jwt.decode(session, SECRET_KEY)
        username = payload["sub"]
    except JWTError:
        raise HTTPException(status_code=401)

    async with aiosqlite.connect('vps.db') as db:
        # 获取用户ID
        async with db.execute('SELECT id FROM users WHERE username = ?', [username]) as cursor:
            user = await cursor.fetchone()
            if not user:
                raise HTTPException(status_code=401)
                
        # 添加VPS信息
        await db.execute('''
            INSERT INTO vps (
                vendor_name, cpu_cores, cpu_model, memory, storage, bandwidth,
                price, currency, start_date, end_date, user_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
            vps_data["vendor_name"], vps_data["cpu_cores"], vps_data["cpu_model"],
            vps_data["memory"], vps_data["storage"], vps_data["bandwidth"],
            vps_data["price"], vps_data["currency"],
            datetime.now().strftime("%Y-%m-%d"), vps_data["end_date"],
            user[0]
        ])
        await db.commit()
    return {"success": True}

@app.get("/api/vps")
async def get_vps():
    async with aiosqlite.connect('vps.db') as db:
        db.row_factory = aiosqlite.Row
        async with db.execute('SELECT * FROM vps ORDER BY end_date DESC') as cursor:
            vps_list = await cursor.fetchall()
            
        # 计算剩余价值
        result = []
        for vps in vps_list:
            vps_dict = dict(vps)
            vps_dict["remaining_value"] = await calculate_remaining_value(
                vps["price"], vps["currency"], vps["end_date"]
            )
            result.append(vps_dict)
            
    return result

# 修改首页路由，添加用户信息
@app.get("/", response_class=HTMLResponse)
async def home(request: Request, session: str = Cookie(None)):
    user = None
    if session:
        try:
            payload = jwt.decode(session, SECRET_KEY)
            user = {"username": payload["sub"]}
        except JWTError:
            pass
            
    async with aiosqlite.connect('vps.db') as db:
        db.row_factory = aiosqlite.Row
        async with db.execute('SELECT * FROM vps ORDER BY end_date DESC') as cursor:
            vps_list = await cursor.fetchall()
            
    return HTMLResponse(content=HTML_TEMPLATE.replace(
        "{% if user %}", "{% if " + str(bool(user)) + " %}"
    ).replace(
        "{{ vps_list }}", str([dict(vps) for vps in vps_list])
    )) 