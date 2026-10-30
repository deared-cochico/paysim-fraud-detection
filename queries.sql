-- PaySim fraud analysis (SQLite)
-- Table: PS (6,362,620 rows, 11 columns). Simulated data, so results describe
-- the simulation, not real-world fraud.
-- Four groups: A (1-5, plus follow-ups 4b-4c) data checks, B (6) how common is fraud,
-- C (7-8) how well the built-in flag works, D (9-12) what fraud looks like.

-- ============================================================
-- GROUP A: Is the data clean? (queries 1-5, plus follow-ups 4b and 4c)
-- ============================================================

-- 1. Row count: does the import match the known dataset size?
SELECT COUNT(*) AS total_rows
FROM PS;

-- 2. Nulls in every column, in one pass
SELECT
  SUM(CASE WHEN step IS NULL THEN 1 ELSE 0 END)            AS null_step,
  SUM(CASE WHEN type IS NULL THEN 1 ELSE 0 END)            AS null_type,
  SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END)          AS null_amount,
  SUM(CASE WHEN nameOrig IS NULL THEN 1 ELSE 0 END)        AS null_nameOrig,
  SUM(CASE WHEN oldbalanceOrg IS NULL THEN 1 ELSE 0 END)   AS null_oldbalanceOrg,
  SUM(CASE WHEN newbalanceOrig IS NULL THEN 1 ELSE 0 END)  AS null_newbalanceOrig,
  SUM(CASE WHEN nameDest IS NULL THEN 1 ELSE 0 END)        AS null_nameDest,
  SUM(CASE WHEN oldbalanceDest IS NULL THEN 1 ELSE 0 END)  AS null_oldbalanceDest,
  SUM(CASE WHEN newbalanceDest IS NULL THEN 1 ELSE 0 END)  AS null_newbalanceDest,
  SUM(CASE WHEN isFraud IS NULL THEN 1 ELSE 0 END)         AS null_isFraud,
  SUM(CASE WHEN isFlaggedFraud IS NULL THEN 1 ELSE 0 END)  AS null_isFlaggedFraud
FROM PS;

-- 3. Unexpected category values: which transaction types exist, and how many of each?
SELECT type, COUNT(*) AS total
FROM PS
GROUP BY type
ORDER BY total DESC;

-- 4. Impossible or suspicious numeric values (zero and negative amounts counted separately)
SELECT
  MIN(amount) AS min_amount,
  MAX(amount) AS max_amount,
  SUM(CASE WHEN amount = 0 THEN 1 ELSE 0 END) AS zero_amount,
  SUM(CASE WHEN amount < 0 THEN 1 ELSE 0 END) AS negative_amount,
  SUM(CASE WHEN typeof(amount) NOT IN ('real', 'integer') THEN 1 ELSE 0 END) AS non_numeric_amount
FROM PS;

-- 4b. Follow-up to 4: which transaction types and fraud labels do the zero-amount rows have?
SELECT type, isFraud, COUNT(*) AS total
FROM PS
WHERE amount = 0
GROUP BY type, isFraud;

-- 4c. Follow-up to 4: do the balances change on the zero-amount rows?
SELECT type, amount, oldbalanceOrg, newbalanceOrig, oldbalanceDest, newbalanceDest
FROM PS
WHERE amount = 0;

-- 5. Exact duplicate rows (all 11 columns). May take a while on 6.3M rows.
--    An empty result means no duplicates.
SELECT step, type, amount, nameOrig, oldbalanceOrg, newbalanceOrig,
       nameDest, oldbalanceDest, newbalanceDest, isFraud, isFlaggedFraud,
       COUNT(*) AS times_seen
FROM PS
GROUP BY step, type, amount, nameOrig, oldbalanceOrg, newbalanceOrig,
         nameDest, oldbalanceDest, newbalanceDest, isFraud, isFlaggedFraud
HAVING COUNT(*) > 1
ORDER BY times_seen DESC
LIMIT 20;

-- ============================================================
-- GROUP B: How common is fraud? (query 6)
-- ============================================================

-- 6. Fraud vs non-fraud: counts and share of all transactions
SELECT isFraud,
       COUNT(*) AS total,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM PS), 4) AS pct_of_all
FROM PS
GROUP BY isFraud;

-- ============================================================
-- GROUP C: How well does the built-in flag work? (queries 7-8)
-- ============================================================

-- 7. How many rows did the built-in flag (isFlaggedFraud, a rule-based flag) mark?
SELECT isFlaggedFraud,
       COUNT(*) AS total,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM PS), 6) AS pct_of_all
FROM PS
GROUP BY isFlaggedFraud;

-- 8. Built-in flag: precision and recall
--    precision: of all the rows the flag flagged, how many were real fraud?
--    recall:    of all the real fraud rows, how many did the flag flag?
SELECT flagged,
       flagged_and_fraud,
       all_fraud,
       ROUND(100.0 * flagged_and_fraud / NULLIF(flagged, 0), 2)   AS precision_pct,
       ROUND(100.0 * flagged_and_fraud / NULLIF(all_fraud, 0), 4) AS recall_pct
FROM (
  SELECT
    SUM(CASE WHEN isFlaggedFraud = 1 THEN 1 ELSE 0 END)                  AS flagged,
    SUM(CASE WHEN isFlaggedFraud = 1 AND isFraud = 1 THEN 1 ELSE 0 END)  AS flagged_and_fraud,
    SUM(isFraud)                                                         AS all_fraud
  FROM PS
);

-- ============================================================
-- GROUP D: What does fraud look like? Type and amount (queries 9-12)
-- ============================================================

-- 9. Fraud by transaction type: counts and fraud rate within each type
--    Which transaction types does fraud occur in, and how common is it per transaction of each type?
SELECT type,
       COUNT(*)                                  AS total_rows,
       SUM(isFraud)                              AS fraud_count,
       ROUND(100.0 * SUM(isFraud) / COUNT(*), 4) AS fraud_rate_pct
FROM PS
GROUP BY type
ORDER BY fraud_count DESC, type;

-- 10. Average amount, fraud vs legit (fraud averages are pulled up by rows at the 10M cap; see Q11-12)
SELECT isFraud,
       COUNT(*) AS total,
       ROUND(AVG(amount), 2) AS avg_amount,
       MIN(amount) AS min_amount,
       MAX(amount) AS max_amount
FROM PS
GROUP BY isFraud;

-- 11. Largest fraud amount
SELECT MAX(amount) AS max_fraud_amount
FROM PS
WHERE isFraud = 1;

-- 12. How many fraud rows sit at that maximum amount?
SELECT SUM(CASE WHEN amount = (SELECT MAX(amount) FROM PS WHERE isFraud = 1) THEN 1 ELSE 0 END) AS at_max,
       COUNT(*) AS all_fraud
FROM PS
WHERE isFraud = 1;

-- 13. Fraud amount checks: average by label, capped rows, and fraud average without the cap

-- 13a. Average amount by label (expected: 0 = 178,197.04; 1 = 1,467,967.30)
SELECT isFraud,
       ROUND(AVG(amount), 2) AS avg_amount
FROM PS
GROUP BY isFraud;

-- 13b. Fraud rows at the 10,000,000 maximum (expected: 287)
SELECT COUNT(*) AS capped_fraud_rows
FROM PS
WHERE isFraud = 1
  AND amount = 10000000;

-- 13c. Fraud average without the capped rows, and percent change from the full fraud average
--      (expected: 1,159,022.89 and about -21%)
SELECT ROUND(AVG(amount), 2) AS avg_fraud_excl_cap,
       ROUND(100.0 * (AVG(amount) - (SELECT AVG(amount) FROM PS WHERE isFraud = 1))
             / (SELECT AVG(amount) FROM PS WHERE isFraud = 1), 2) AS pct_change
FROM PS
WHERE isFraud = 1
  AND amount < 10000000;
