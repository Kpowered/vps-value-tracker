from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from datetime import datetime, timedelta
import sqlite3
import httpx
from models import VPS, User
from database import get_db, init_db
import os
from pathlib import Path

app = FastAPI()

# 初始化数据库
init_db()

# 静态文件服务
app.mount("/", StaticFiles(directory="frontend/dist", html=True))

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 添加健康检查端点
@app.get("/health")
async def health_check():
    return {"status": "ok"}

FIXER_API_KEY = os.getenv('FIXER_API_KEY')
rates_cache = {}
last_rates_update = None

async def update_exchange_rates():
    global rates_cache, last_rates_update
    now = datetime.now()
    
    if last_rates_update and (now - last_rates_update).days < 1:
        return
    
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f'http://data.fixer.io/api/latest?access_key={FIXER_API_KEY}&base=EUR'
        )
        data = response.json()
        if data.get('success'):
            rates_cache = data['rates']
            last_rates_update = now

def convert_to_cny(amount: float, from_currency: str) -> float:
    if from_currency == 'CNY':
        return amount
    if not rates_cache:
        return amount  # 如果没有汇率数据，返回原值
    
    # 先转换为EUR，再转换为CNY
    eur_amount = amount / rates_cache[from_currency]
    return eur_amount * rates_cache['CNY']

@app.post("/api/vps")
async def add_vps(vps: VPS, db = Depends(get_db)):
    cursor = db.cursor()
    cursor.execute("""
        INSERT INTO vps (
            vendor, cpu_cores, cpu_model, memory_gb, disk_gb, 
            bandwidth_gb, price, currency, start_date, end_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        vps.vendor, vps.cpu_cores, vps.cpu_model, vps.memory_gb,
        vps.disk_gb, vps.bandwidth_gb, vps.price, vps.currency,
        datetime.now().isoformat(),
        (datetime.now() + timedelta(days=365)).isoformat()
    ))
    db.commit()
    return {"message": "VPS added successfully"}

@app.get("/api/vps")
async def get_vps_list(db = Depends(get_db)):
    await update_exchange_rates()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM vps")
    columns = [col[0] for col in cursor.description]
    vps_list = []
    
    for row in cursor.fetchall():
        vps_dict = dict(zip(columns, row))
        # 计算剩余时间（天数）
        end_date = datetime.fromisoformat(vps_dict['end_date'])
        remaining_days = (end_date - datetime.now()).days
        
        # 计算剩余价值
        if remaining_days > 0:
            remaining_value = vps_dict['price'] * remaining_days / 365
            remaining_value_cny = convert_to_cny(remaining_value, vps_dict['currency'])
        else:
            remaining_value = 0
            remaining_value_cny = 0
            
        vps_dict['remaining_value'] = remaining_value
        vps_dict['remaining_value_cny'] = remaining_value_cny
        vps_list.append(vps_dict)
    
    return {"vps_list": vps_list} 