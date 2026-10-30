# Notes: PaySim Fraud Detection Analysis

## Technical Decisions

**Python connector instead of ODBC.** I looked into connecting Power BI to SQLite the standard way, but the only SQLite ODBC driver I could find was hosted on a site with an outdated, flagged SSL certificate. I didn't want to install unverified third-party software, so I used Power BI's built-in Python script connector instead (pandas + sqlite3). It gives the same result without an untrusted driver. The script is in `scripts/sqlite_connector.py`.

**Database path set at the top of the script.** The path is one variable, `DB_PATH`, which each user changes to match their setup. The script checks that the file exists before connecting, because `sqlite3.connect()` creates a new, empty database when the file is missing.

**Conversion helper.** The numeric columns are converted by a small function, so only the four tables Power BI should load are defined at the top level of the script.

## Issues I Ran Into

1. **Wrong database path created an empty database.** `sqlite3.connect()` creates a new, empty database when the path doesn't point to an existing file. My queries then failed with "no such table," which looked like a query error but was a path error. I fixed it by copying the exact path from DBeaver's connection settings and checking the table name in `sqlite_master`. The script now checks that the file exists before connecting.

2. **Numeric columns came in as text.** The COUNT() and SUM() results from the Python connector loaded into Power BI as text, so I couldn't sum them. I fixed the column types in Power Query (Transform data), setting Whole Number and Decimal Number. The connector script now converts these columns with `pd.to_numeric`, so the repo matches the dashboard.

3. **Fraud bars looked almost invisible next to the totals.** Fraud is about 0.13% of transactions, so fraud bars are tiny beside the total counts. I added a separate fraud-only chart so the pattern across transaction types is visible. Counts still hide the rate difference: TRANSFER and CASH_OUT have nearly equal fraud counts, but TRANSFER is about four times riskier per transaction. The next step is a fraud-rate chart.

4. **Duplicate table in Power BI's Navigator.** A loop variable named `df` was left at the top level of the script, so Navigator listed a duplicate of `amount_comparison`. I fixed it by moving the conversion into a function, so only the four intended tables are defined at the top level.
