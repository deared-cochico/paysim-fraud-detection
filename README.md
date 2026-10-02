# PaySim Fraud Detection Analysis

I built this project to practice SQL and Power BI on a real fraud-detection problem: ~6.4 million synthetic mobile money transactions, with the goal of finding actual fraud patterns and testing how well the dataset's own fraud-detection flag performs. Power BI doesn't have a native SQLite connector, so I used a small Python script (pandas + sqlite3) to bridge the two - details in the tooling note below.

## Dataset

[PaySim](https://www.kaggle.com/datasets/ealaxi/paysim1) - a synthetic 
dataset simulating mobile money transactions, built to resemble real 
financial fraud. 6,362,620 rows.

## Tools I Used

- **SQLite** - local database
- **DBeaver** - SQL client for exploration and cleaning
- **Python** (pandas, sqlite3) - connected Power BI to the database (see 
  the tooling note below for why)
- **Power BI Desktop** - the dashboard
- **LibreOffice Calc** - a pivot table summary artifact

## Data Cleaning

Before analyzing anything, I checked:
- Row count matches the known source size (6,362,620)
- 0 null values across key columns
- 0 exact duplicate rows
- 5 valid transaction types, no unexpected categories
- No negative transaction amounts

## What I Found

1. **Fraud rate:** 8,213 fraudulent transactions out of 6,362,620 total (~0.13%)
2. **System catch rate:** the dataset's built-in `isFlaggedFraud` flag caught 
   only 16 of the 8,213 actual fraud cases (~0.19%) - a naive rule-based 
   flag that mostly doesn't work
3. **Fraud is type-restricted:** fraud only happens in `CASH_OUT` and 
   `TRANSFER` transactions - zero fraud in `CASH_IN`, `DEBIT`, or `PAYMENT`
4. **Amount skew:** fraudulent transactions average a higher amount than 
   legitimate ones

**One caveat worth flagging:** every fraud case in the dataset caps at 
exactly 10,000,000. I don't think this is a real pattern - it looks like 
an artifact of how the synthetic data was generated, so I'm not presenting 
it as a genuine finding.

## A Note on Tooling

Power BI doesn't have an official native connector for SQLite. The only 
SQLite ODBC driver I could find was hosted on a site with an outdated, 
flagged SSL certificate, so instead of installing unverified third-party 
software, I connected through Power BI's built-in Python script connector 
(pandas + sqlite3) instead.

Full writeup of that decision, plus the bugs I hit along the way and how I 
fixed them, is in [`notes.md`](./notes.md).

## Repo Contents

- `queries.sql` - All SQL queries used for cleaning and analysis
- `notes.md` - Technical decisions, issues encountered, and resolutions
- `data/` - Exported query results powering the dashboard (4 CSVs)
- `paysim_fraud_dashboard.pbix` - Power BI dashboard (4 visuals)
- `fraud_by_type_pivot.xlsx` - Pivot table summary
- `dashboard_screenshot.png` - Preview image of the finished dashboard

## Dashboard

4 visuals: fraud count by transaction type, total fraud cases vs. 
system-flagged cases, and average transaction amount (fraud vs. legitimate) -
laid out on one dashboard page with the findings and caveat noted 
directly on it.

![Dashboard Screenshot](dashboard_screenshot.png)

## Future Improvements

- Dual-axis scaling on the type chart, so the fraud_count bars aren't 
  visually dwarfed by the total-transaction bars