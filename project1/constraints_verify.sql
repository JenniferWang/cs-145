PRAGMA foreign_keys = ON;

-- Constraints for Users
-- 1.No two users can share the same User ID.
SELECT *
FROM Users
GROUP BY User_ID
Having Count(*) > 1;

-- 2.All sellers and bidders must already exist as users.
SELECT Seller_ID
FROM Items
WHERE Seller_ID NOT IN (
  SELECT User_ID
  FROM Users
);

SELECT User_ID
FROM Bids
WHERE User_ID NOT IN (
  SELECT User_ID
  FROM Users
);

-- Constraints for Items
-- 3. No two items can share the same Item ID.
SELECT *
FROM Items
GROUP BY Item_ID
Having Count(*) > 1;

-- 4. Every bid must correspond to an actual item.
SELECT *
FROM Bids
WHERE Item_ID NOT IN (
  SELECT Item_ID
  FROM Items
);

-- 5. The items for a given category must all exist.
SELECT *
FROM Category
WHERE Item_ID  NOT IN (
  SELECT Item_ID
  FROM Items
);

-- 6. An item cannot belong to a particular category more than once.
SELECT *
FROM Category
GROUP BY Item_ID, Category
Having Count(*) > 1;

-- 7. The end time for an auction must always be after its start time.
SELECT *
FROM Items
WHERE Ends <= Starts;

-- 8. The Current Price of an item must always match the Amount of the most
-- recent bid for that item.
SELECT *
FROM Items it, (
  SELECT Item_ID, MAX(Time) AS Time, Amount
  FROM Bids
  GROUP BY Item_ID) As bd
WHERE bd.Item_ID = it.Item_ID
  AND bd.Amount <> it.Current_Price;

-- Constraints for Bidding
-- 9. A user may not bid on an item he or she is also selling.
SELECT *
FROM Bids, Items
WHERE Bids.Item_ID = Items.Item_ID
  AND Bids.User_ID = Items.Seller_ID;

-- 10. No auction may have two bids at the exact same time.
SELECT *
FROM Bids
GROUP BY Item_ID, Time
Having Count(*) > 1;

-- 11. No auction may have a bid before its start time or after its end time.
SELECT *
FROM Bids bd, Items it
WHERE bd.Item_ID = it.Item_ID
  AND (bd.Time < it.Starts OR bd.Time > it.Ends);

-- 12. No user can make a bid of the same amount to the same item more than once.
SELECT *
FROM Bids
GROUP BY Item_ID, User_ID, Amount
Having Count(*) > 1;

-- 13. In every auction, the Number of Bids attribute corresponds to the actual
-- number of bids for that particular item.
SELECT *
FROM Items it, (
    SELECT Item_ID, COUNT(*) AS Number_of_Bids
    FROM Bids
    GROUP BY Item_ID
) AS bd
WHERE it.Item_ID = bd.Item_ID AND it.Number_of_Bids <> bd.Number_of_Bids;

-- 14.Any new bid for a particular item must have a higher amount than any of
-- the previous bids for that particular item.
SELECT *
FROM Bids bd1
WHERE EXISTS (
    SELECT *
    FROM Bids bd2
    WHERE bd2.Item_ID = bd1.Item_ID AND bd2.Time < bd1.Time AND bd2.Amount >= bd1.Amount
);

-- Constraints for Time
-- 15. All new bids must be placed at the time which matches the current time of
-- your AuctionBase system.

-- 16. The current time of your AuctionBase system can only advance forward in time, not backward in time.
