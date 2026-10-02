## Technical Decisions

**Why I used a Python script instead of ODBC for the Power BI connection**
I looked into connecting Power BI to SQLite the standard way, but the only 
SQLite ODBC driver I could find was hosted on a site with an outdated, 
flagged SSL certificate. I didn't want to install unverified third-party 
software just to get a connection working, so I used Power BI's built-in 
Python script connector instead (pandas + sqlite3) - same result, no 
untrusted driver needed.

## Issues I Ran Into

1. **Wrong DB path silently created an empty database.** I didn't realize 
   `sqlite3.connect()` doesn't throw an error if the file doesn't exist - 
   it just creates a new, empty one at that path. My first few queries 
   kept failing with "no such table," which looked like a bad query, but 
   it was actually a path problem. Fixed it by copying the exact file path 
   from DBeaver's connection settings and double-checking the real table 
   name against `sqlite_master`.

2. **Numeric columns came in as text.** The COUNT()/SUM() results from the 
   Python connector loaded into Power BI typed as text, so I couldn't use 
   Sum on them. Fixed in Power Query by manually setting the column types 
   to Whole Number / Decimal Number.

3. **Fraud bars looked almost invisible next to the totals.** Not actually 
   a bug - fraud is only about 0.13% of all transactions, so it's always 
   going to look tiny next to the total count at that scale. I added a 
   separate fraud-only chart so the pattern across transaction types is 
   actually visible.