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

-- 5. Check for exact duplicate rows
SELECT step, type, amount, nameOrig, oldbalanceOrg, newbalanceOrig,
       nameDest, oldbalanceDest, newbalanceDest, isFraud, isFlaggedFraud,
       COUNT(*) AS times_seen
FROM PS
GROUP BY step, type, amount, nameOrig, oldbalanceOrg, newbalanceOrig,
         nameDest, oldbalanceDest, newbalanceDest, isFraud, isFlaggedFraud
HAVING COUNT(*) > 1;

-- How many fraud vs non-fraud transactions
SELECT isFraud, COUNT(*) AS total
FROM PS
GROUP BY isFraud;

-- PaySim also has a second flag column - how many did the system itself catch?
SELECT isFlaggedFraud, COUNT(*) AS total
FROM PS
GROUP BY isFlaggedFraud;

-- How good is the built-in flag? (precision and recall)
SELECT isFlaggedFraud,
       COUNT(*) AS total_rows,
       SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS fraud_count
FROM PS
GROUP BY isFlaggedFraud;

-- Fraud count by transaction type
SELECT type,
       COUNT(*) AS total,
       SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS fraud_count
FROM PS
GROUP BY type;

-- Amount comparison: fraud vs legit
SELECT isFraud,
       AVG(amount) AS avg_amount,
       MIN(amount) AS min_amount,
       MAX(amount) AS max_amount
FROM PS
GROUP BY isFraud;
