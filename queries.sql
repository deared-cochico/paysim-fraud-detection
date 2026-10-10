-- PaySim fraud analysis (SQLite). Table: PS (6,362,620 rows, 11 columns).
-- Queries 1-5: data cleaning checks. 6-12: analysis.

-- 1. Verify import matches known dataset size (6,362,620 rows)
SELECT COUNT(*) FROM PS;

-- 2. Check nulls across all 11 columns in one pass
SELECT
  SUM(CASE WHEN step IS NULL THEN 1 ELSE 0 END) AS null_step,
  SUM(CASE WHEN type IS NULL THEN 1 ELSE 0 END) AS null_type,
  SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS null_amount,
  SUM(CASE WHEN nameOrig IS NULL THEN 1 ELSE 0 END) AS null_nameOrig,
  SUM(CASE WHEN oldbalanceOrg IS NULL THEN 1 ELSE 0 END) AS null_oldbalanceOrg,
  SUM(CASE WHEN newbalanceOrig IS NULL THEN 1 ELSE 0 END) AS null_newbalanceOrig,
  SUM(CASE WHEN nameDest IS NULL THEN 1 ELSE 0 END) AS null_nameDest,
  SUM(CASE WHEN oldbalanceDest IS NULL THEN 1 ELSE 0 END) AS null_oldbalanceDest,
  SUM(CASE WHEN newbalanceDest IS NULL THEN 1 ELSE 0 END) AS null_newbalanceDest,
  SUM(CASE WHEN isFraud IS NULL THEN 1 ELSE 0 END) AS null_isFraud,
  SUM(CASE WHEN isFlaggedFraud IS NULL THEN 1 ELSE 0 END) AS null_isFlaggedFraud
FROM PS;

-- 3. Check for unexpected category values
SELECT DISTINCT type FROM PS;

-- 4. Check for impossible numeric values
SELECT MIN(amount) AS min_amount, MAX(amount) AS max_amount FROM PS;

-- 5. Check for exact duplicate rows - may take a while
SELECT step, type, amount, nameOrig, oldbalanceOrg, newbalanceOrig,
       nameDest, oldbalanceDest, newbalanceDest, isFraud, isFlaggedFraud,
       COUNT(*) AS times_seen
FROM PS
GROUP BY step, type, amount, nameOrig, oldbalanceOrg, newbalanceOrig,
         nameDest, oldbalanceDest, newbalanceDest, isFraud, isFlaggedFraud
HAVING COUNT(*) > 1;

-- 6. How many fraud vs non-fraud transactions
SELECT isFraud, COUNT(*) AS total
FROM PS
GROUP BY isFraud;

-- 7. How many rows did the built-in flag (isFlaggedFraud, a rule-based flag) mark?
SELECT isFlaggedFraud, COUNT(*) AS total
FROM PS
GROUP BY isFlaggedFraud;

-- 8. Built-in flag: precision and recall
SELECT
  SUM(CASE WHEN isFlaggedFraud = 1 THEN 1 ELSE 0 END) AS flagged,
  SUM(CASE WHEN isFlaggedFraud = 1 AND isFraud = 1 THEN 1 ELSE 0 END) AS flagged_and_fraud,
  SUM(isFraud) AS all_fraud,
  1.0 * SUM(CASE WHEN isFlaggedFraud = 1 AND isFraud = 1 THEN 1 ELSE 0 END)
      / SUM(CASE WHEN isFlaggedFraud = 1 THEN 1 ELSE 0 END) AS precision,
  1.0 * SUM(CASE WHEN isFlaggedFraud = 1 AND isFraud = 1 THEN 1 ELSE 0 END)
      / SUM(isFraud) AS recall
FROM PS;

-- 9. Fraud count by transaction type
SELECT type,
       COUNT(*) AS total,
       SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS fraud_count
FROM PS
GROUP BY type;

-- 10. Amount comparison: fraud vs legit
SELECT isFraud,
       AVG(amount) AS avg_amount,
       MIN(amount) AS min_amount,
       MAX(amount) AS max_amount
FROM PS
GROUP BY isFraud;

-- 11. Maximum fraud amount
SELECT MAX(amount) FROM PS WHERE isFraud = 1;

-- 12. How many fraud rows sit at the maximum fraud amount?
SELECT SUM(CASE WHEN amount = (SELECT MAX(amount) FROM PS WHERE isFraud = 1) THEN 1 ELSE 0 END) AS at_max,
       COUNT(*) AS all_fraud
FROM PS WHERE isFraud = 1;
