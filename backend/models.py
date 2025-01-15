from pydantic import BaseModel
from datetime import datetime
from enum import Enum

class Currency(str, Enum):
    CNY = "CNY"
    USD = "USD"
    EUR = "EUR"
    GBP = "GBP"
    CAD = "CAD"
    JPY = "JPY"

class VPS(BaseModel):
    vendor: str
    cpu_cores: int
    cpu_model: str
    memory_gb: int
    disk_gb: int
    bandwidth_gb: int
    price: float
    currency: Currency
    start_date: datetime
    end_date: datetime 