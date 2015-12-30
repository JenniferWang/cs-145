PRAGMA foreign_keys = ON;

-- 8. The Current Price of an item must always match the Amount of the most 
-- recent bid for that item.
DROP TRIGGER IF EXISTS update_current_price;
CREATE TRIGGER update_current_price
AFTER INSERT ON Bids
FOR EACH ROW
BEGIN
    UPDATE Items
    SET Current_Price = New.Amount
    WHERE Item_ID = New.Item_ID;
END;

-- 9. A user may not bid on an item he or she is also selling.
DROP TRIGGER IF EXISTS no_sell_and_bid_on_same_item;
CREATE TRIGGER no_sell_and_bid_on_same_item
BEFORE INSERT ON Bids
FOR EACH ROW
    WHEN EXISTS (
        SELECT *
        FROM Items
        WHERE Items.Seller_ID = New.User_ID
    )
BEGIN
SELECT RAISE(ROLLBACK, 'A user may not bid on an item he or she is also selling.');
END;

-- 10. No auction may have two bids at the exact same time.
DROP TRIGGER IF EXISTS no_two_bids_at_the_same_time;
CREATE TRIGGER no_two_bids_at_the_same_time
BEFORE INSERT ON Bids
FOR EACH ROW
    WHEN EXISTS (
        SELECT *
        FROM Bids
        WHERE Bids.Item_ID = New.Item_ID
            AND Bids.Time = New.Time
    )
BEGIN
SELECT RAISE(ROLLBACK, 'No auction may have two bids at the exact same time.');
END;

-- 11. No auction may have a bid before its start time or after its end time.
DROP TRIGGER IF EXISTS no_bids_outside_time_interval;
CREATE TRIGGER no_bids_outside_time_interval
BEFORE INSERT ON Bids
FOR EACH ROW
    WHEN EXISTS (
        SELECT *
        FROM Items
        WHERE Items.Item_ID = New.Item_ID
            AND (Items.Starts > New.Time OR Items.Ends < New.Time)
    )
BEGIN
SELECT RAISE(ROLLBACK, 'No auction may have a bid before its start time or after its end time.');
END;

-- 12. No user can make a bid of the same amount to the same item more than once.
DROP TRIGGER IF EXISTS no_same_bids_for_same_user;
CREATE TRIGGER no_same_bids_for_same_user
BEFORE INSERT ON Bids
FOR EACH ROW
    WHEN EXISTS (
        SELECT *
        FROM Bids
        WHERE Bids.Item_ID = New.Item_ID
            AND Bids.User_ID = New.User_ID
            AND Bids.Amount = New.Amount
    )
BEGIN
SELECT RAISE(ROLLBACK, 'No user can make a bid of the same amount to the same item more than once.');
END;

-- 13. In every auction, the Number of Bids attribute corresponds to the actual number
-- of bids for that particular item.
DROP TRIGGER IF EXISTS update_number_of_bids;
CREATE TRIGGER update_number_of_bids
AFTER INSERT ON Bids
FOR EACH ROW
BEGIN
    UPDATE Items
    SET Number_of_Bids = Number_of_Bids + 1
    WHERE Item_ID = New.Item_ID;
END;

-- 14.
DROP TRIGGER IF EXISTS no_less_amount_for_same_item;
CREATE TRIGGER no_less_amount_for_same_item
BEFORE INSERT ON Bids
FOR EACH ROW
    WHEN EXISTS (
        SELECT *
        FROM Items
        WHERE Items.Item_ID = New.Item_ID
            AND New.Amount <= Items.Current_Price
    )
BEGIN
SELECT RAISE(ROLLBACK, 'You should bids for a higher price for this item');
END;

-- 15.
DROP TRIGGER IF EXISTS no_mismatch_time;
CREATE TRIGGER no_mismatch_time
BEFORE INSERT ON Bids
FOR EACH ROW
    WHEN EXISTS (
        SELECT *
        FROM CurrentTime
        WHERE NEW.Time <> CurrentTime.Time
    )
BEGIN
SELECT RAISE(ROLLBACK, 'All new bids must be placed at the time which matches the current time');
END;

-- 16.
DROP TRIGGER IF EXISTS no_backward_time;
CREATE TRIGGER no_backward_time
BEFORE UPDATE ON CurrentTime
FOR EACH ROW
    WHEN Old.Time >= New.Time
BEGIN
SELECT RAISE(ROLLBACK, 'You can only advance forward in time');
END;

