-- PaySim fraud analysis (SQLite)
-- Table: PS (6,362,620 rows, 11 columns). Simulated data, so results describe
-- the simulation, not real-world fraud.
-- Four groups: A (1-5) data checks, B (6) how common is fraud,
-- C (7-8) how well the built-in flag works, D (9-12) what fraud looks like.

-- ============================================================
-- GROUP A: Is the data clean? (queries 1-5)
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

-- 4. Impossible or suspicious numeric values
--    (min/max, zero or negative amounts, negative balances, amounts not stored as numbers)
SELECT
  MIN(amount) AS min_amount,
  MAX(amount) AS max_amount,
  SUM(CASE WHEN amount <= 0 THEN 1 ELSE 0 END) AS zero_or_negative_amount,
  SUM(CASE WHEN oldbalanceOrg < 0 OR newbalanceOrig < 0
             OR oldbalanceDest < 0 OR newbalanceDest < 0
           THEN 1 ELSE 0 END) AS negative_balance_rows,
  SUM(CASE WHEN typeof(amount) NOT IN ('real', 'integer')
           THEN 1 ELSE 0 END) AS non_numeric_amount
FROM PS;

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
--    precision = flagged rows that really are fraud / all flagged rows
--    recall    = fraud the flag caught / all fraud
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
SELECT type,
       COUNT(*) AS total,
       SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS fraud_count,
       ROUND(100.0 * SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS fraud_rate_pct
FROM PS
GROUP BY type
ORDER BY fraud_count DESC;

-- 10. Amount comparison: fraud vs legit (the average can be pulled up by a few large amounts)
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
