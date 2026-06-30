from __future__ import annotations

import os
from pathlib import Path

import pandas as pd
import psycopg2


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = PROJECT_ROOT / "ml" / "sql"
OUTPUT_DIR = PROJECT_ROOT / "ml" / "outputs"
MODEL_DIR = PROJECT_ROOT / "ml" / "models"


def get_connection():
    return psycopg2.connect(
        host=os.getenv("OLIST_DB_HOST", "localhost"),
        port=int(os.getenv("OLIST_DB_PORT", "5433")),
        user=os.getenv("OLIST_DB_USER", "olist_user"),
        password=os.getenv("OLIST_DB_PASSWORD", "olist_pass"),
        dbname=os.getenv("OLIST_DB_NAME", "olist_db"),
    )


def read_sql(name: str) -> str:
    return (SQL_DIR / name).read_text(encoding="utf-8")


def load_dataframe(sql_file: str) -> pd.DataFrame:
    with get_connection() as conn:
        return pd.read_sql_query(read_sql(sql_file), conn)


def ensure_ml_dirs() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
