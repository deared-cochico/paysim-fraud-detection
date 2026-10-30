"""
SQLite connector for Power BI (Python script data source).

Power BI runs this script and loads every pandas DataFrame defined here
as a table. Set the PAYSIM_DB environment variable to the full path of
your database file. If it isn't set, the script looks for paysim.db in
the current folder.

The script stops with an error if the file is missing, so it never
creates an empty database by accident.
"""
import os
import sqlite3
from pathlib import Path

import pandas as pd

DB_PATH = Path(os.environ.get("PAYSIM_DB", "paysim.db"))

if not DB_PATH.is_file():
    raise FileNotFoundError(
        f"Database not found at {DB_PATH.resolve()}. "
        "Set the PAYSIM_DB environment variable to the full path of paysim.db."
    )

conn = sqlite3.connect(DB_PATH)

fraud_overall = pd.read_sql_query(
    "SELECT isFraud, COUNT(*) AS total FROM PS GROUP BY isFraud", conn
)
flagged_fraud = pd.read_sql_query(
    "SELECT isFlaggedFraud, COUNT(*) AS total FROM PS GROUP BY isFlaggedFraud", conn
)
fraud_by_type = pd.read_sql_query(
    """
    SELECT type,
           COUNT(*) AS total,
           SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS fraud_count
    FROM PS
    GROUP BY type
    """,
    conn,
)
amount_comparison = pd.read_sql_query(
    """
    SELECT isFraud,
           AVG(amount) AS avg_amount,
           MIN(amount) AS min_amount,
           MAX(amount) AS max_amount
    FROM PS
    GROUP BY isFraud
    """,
    conn,
)

conn.close()

# SQLite returns counts and sums as integers and averages as floats, but
# Power BI can load them as text in some setups. Convert the numeric
# columns explicitly so they load as numbers.
fraud_overall["total"] = pd.to_numeric(fraud_overall["total"])
flagged_fraud["total"] = pd.to_numeric(flagged_fraud["total"])
fraud_by_type["total"] = pd.to_numeric(fraud_by_type["total"])
fraud_by_type["fraud_count"] = pd.to_numeric(fraud_by_type["fraud_count"])
amount_comparison["avg_amount"] = pd.to_numeric(amount_comparison["avg_amount"])
amount_comparison["min_amount"] = pd.to_numeric(amount_comparison["min_amount"])
amount_comparison["max_amount"] = pd.to_numeric(amount_comparison["max_amount"])
