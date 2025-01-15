from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from datetime import datetime, timedelta
import sqlite3
import httpx
from models import VPS, User
from database import get_db
import jwt
from pathlib import Path

app = FastAPI()

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

@app.post("/api/vps")
async def add_vps(vps: VPS, db = Depends(get_db)):
    vps.start_date = datetime.now()
    vps.end_date = vps.start_date + timedelta(days=365)
    # 数据库操作...
    return vps

@app.get("/api/vps")
async def get_vps_list(db = Depends(get_db)):
    # 返回VPS列表，包含剩余价值计算
    return {"vps_list": []} 