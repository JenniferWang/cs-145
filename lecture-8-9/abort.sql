.open bank.db

DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
  account_id INT PRIMARY KEY,
  owner VARCHAR(30),
  balance FLOAT
);

INSERT INTO accounts VALUES (1, 'Joe', 100.0);
INSERT INTO accounts VALUES (2, 'Bob', 100.0);

-- Note: ';' for each statement
BEGIN;
  UPDATE accounts SET balance = balance - 50 WHERE owner = 'Joe';
  UPDATE accounts SET balance = balance + 50 WHERE owner = 'Bob';
COMMIT;
