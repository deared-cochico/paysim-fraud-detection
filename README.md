# PaySim Fraud Detection Analysis

I used SQL to explore and clean about 6.4 million synthetic mobile-money transactions, then built a Power BI dashboard on top. The goal was to find fraud patterns and test how well the dataset's built-in fraud flag performs.

## Key Findings

- **Fraud is rare:** 8,213 of 6,362,620 transactions (~0.13%).
- **Fraud appears only in two types:** `CASH_OUT` and `TRANSFER`. There is no fraud in `CASH_IN`, `DEBIT`, or `PAYMENT`.
- **TRANSFER is riskier per transaction:** about 0.77% of TRANSFER transactions are fraud, versus about 0.18% for CASH_OUT, roughly four times higher. Both types have nearly the same fraud count (4,097 and 4,116). The difference comes from TRANSFER having far fewer transactions.
- **The built-in flag is precise but narrow:** it caught 16 of 8,213 frauds. All 16 flags were real fraud, but it misses about 99.8% of fraud.
- **Fraud amounts are higher on average:** about 1,467,967 for fraud versus 178,197 for legitimate transactions, roughly 8 times higher.

**Caveat on amounts:** 287 of the 8,213 fraud rows (3.5%) sit at exactly 10,000,000, the largest fraud amount. The senders' starting balances are large enough to cover those amounts, so the balance data doesn't rule them out. The value is far above the wallet limits I checked (for example, a Fully Verified GCash account can hold up to ₱1,000,000), so it is probably a generator artifact. The fraud averages above may be understated. Excluding the 287 capped rows would lower the fraud average by about 20%, which shows the averages are sensitive to the cap.

## Dataset

[PaySim](https://www.kaggle.com/datasets/ealaxi/paysim1): a synthetic dataset simulating mobile-money transactions, built to resemble real financial fraud. It has 6,362,620 rows and 11 columns. Because the data is simulated, these results describe this dataset, not real-world fraud.

## Definitions

- **Mobile money:** sending, receiving, and storing money with a phone, usually through an app or SMS, instead of a bank account or card. GCash and Maya are examples.
- **CASH_IN:** depositing physical cash into a mobile-money wallet.
- **CASH_OUT:** converting a wallet balance into physical cash.
- **TRANSFER:** sending money from one wallet to another.
- **isFraud:** the dataset's answer column. 1 means fraud, 0 means legitimate.
- **isFlaggedFraud:** the dataset's built-in rule-based flag. It is not a model I trained.
- **Precision:** of the transactions the flag marked, the share that were real fraud.
  Precision = (isFlaggedFraud = 1 AND isFraud = 1) ÷ (isFlaggedFraud = 1)
- **Recall:** of all real fraud, the share the flag caught.
  Recall = (isFlaggedFraud = 1 AND isFraud = 1) ÷ (isFraud = 1)

## Questions I Asked

The queries in `queries.sql` are grouped by the question each one answers:

- **A. Is the data clean?** Queries 1-5, plus follow-up checks 4b and 4c
- **B. How common is fraud?** Query 6
- **C. How well does the built-in flag work?** Queries 7-8
- **D. What does fraud look like, by type and amount?** Queries 9-12

## Data Cleaning

Before analyzing, I checked (query numbers in brackets):

- Row count matches the known source size, 6,362,620 (Q1)
- 0 null values across all 11 columns (Q2)
- 5 valid transaction types, no unexpected categories (Q3)
- No negative amounts, and every amount is stored as a number, but 16 rows have an amount of exactly 0 (Q4)
- 0 exact duplicate rows (Q5)

**Zero-amount rows:** all 16 are `CASH_OUT`, all 16 are labeled fraud, and their balances don't change (Q4b, Q4c). I don't know why the simulation produces them. I kept them instead of deleting them, and I don't treat them as a real-world pattern.

## Limits

- **Simulated data.** Findings describe this dataset, not real-world fraud. For example, fraud appearing in only two transaction types is a property of how the data was generated, not something I can confirm about real systems.
- **The flag is a simple built-in rule,** not a model. I evaluated it, but I did not build a fraud detector.
- **Fraud is about 0.13% of rows,** so overall accuracy would be misleading. That's why I used precision and recall instead.
- **The 10,000,000 ceiling** affects amount-based results at the top end, so the amount averages are likely lower bounds. Fraud rates, catch rates, and fraud-by-type counts are not affected.
- **No time analysis.** I did not analyze fraud over time (the `step` column).

## Tools

- **SQLite:** local database
- **DBeaver:** SQL client for exploration and cleaning
- **Python (pandas, sqlite3):** connects Power BI to the database (see the tooling note below)
- **Power BI Desktop:** dashboard
- **LibreOffice Calc:** pivot table summary

## A Note on Tooling

Power BI has no official native connector for SQLite. The only SQLite ODBC driver I found was hosted on a site with an outdated, flagged SSL certificate, so instead of installing unverified third-party software, I connected through Power BI's built-in Python script connector (pandas + sqlite3).

Full details, plus the bugs I hit and how I fixed them, are in [`notes.md`](./notes.md).

## How to Reproduce

1. Download the PaySim CSV from the Kaggle link above.
2. Import it into SQLite as a table named `PS` (for example, with DBeaver's import tool).
3. Run `queries.sql` in DBeaver. Each query is numbered and grouped as above.

## Repo Contents

- `queries.sql`: 12 SQL queries plus 2 follow-up checks (4b, 4c)
- `notes.md`: technical decisions, issues, and resolutions
- `data/`: exported query results that power the dashboard (4 CSVs)
- `paysim_fraud_dashboard.pbix`: Power BI dashboard (4 visuals)
- `fraud_by_type_pivot.xlsx`: pivot table summary
- `dashboard_screenshot.png`: preview of the finished dashboard

## Dashboard

Four visuals on one page: fraud count by transaction type, two cards (total fraud cases and system-flagged cases), and average transaction amount, fraud versus legitimate.

![Dashboard Screenshot](dashboard_screenshot.png)

## Future Improvements

- Chart the fraud rate per type instead of raw counts, so the TRANSFER and CASH_OUT difference is visible on one simple scale.
- Add the 10,000,000 ceiling caveat to the dashboard itself
- Fraud over time, using the `step` column
- A balance consistency check: does each account's balance change match the transaction amount?
