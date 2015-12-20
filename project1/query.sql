/* 1. Find the number of users in the database. */
SELECT COUNT(*)
FROM Users;

/* 2.Find the number of users from New York (i.e., users whose location is the */
/*   string “New York”). */
SELECT COUNT(*)
FROM Users
WHERE Location = "New York";

/* 3. Find the number of auctions belonging to exactly four categories. */
SELECT COUNT(*)
FROM (
  SELECT Item_ID
  FROM Category
  GROUP BY Item_ID
  HAVING COUNT(Category) = 4
);

/* 4. Find the ID(s) of auction(s) with the highest current price. */
SELECT Item_ID
FROM Items
WHERE Currently = (SELECT MAX(Currently) FROM Items);

/* 5.Find the number of sellers whose rating is higher than 1000. */
SELECT COUNT(DISTINCT u.User_ID)
FROM Items i, Users u
WHERE i.Seller_ID = u.User_ID AND u.Rating > 1000;

/* 6. Find the number of users who are both sellers and bidders. */
SELECT COUNT(DISTINCT Seller_ID)
FROM Items, Bids
WHERE Items.Seller_ID = Bids.User_ID;

/* 7. Find the number of categories that include at least one item with a bid of more than $100. */
SELECT COUNT(DISTINCT Category)
FROM Category c, (
  SELECT Item_ID
  FROM Bids
  WHERE Amount > 100) As i
WHERE c.Item_ID = i.Item_ID;



