import sqlite3
from pathlib import Path

DATABASE_PATH = Path("data/vps.db")

def init_db():
    DATABASE_PATH.parent.mkdir(exist_ok=True)
    conn = sqlite3.connect(str(DATABASE_PATH))
    conn.execute("""
        CREATE TABLE IF NOT EXISTS vps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vendor TEXT NOT NULL,
            cpu_cores INTEGER NOT NULL,
            cpu_model TEXT NOT NULL,
            memory_gb INTEGER NOT NULL,
            disk_gb INTEGER NOT NULL,
            bandwidth_gb INTEGER NOT NULL,
            price REAL NOT NULL,
            currency TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL
        )
    """)
    conn.close()

def get_db():
    conn = sqlite3.connect(str(DATABASE_PATH))
    try:
        yield conn
    finally:
        conn.close() 