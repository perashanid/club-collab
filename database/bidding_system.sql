-- Bidding System with Club Currency
USE club_collab;

-- Add currency column to Club table
ALTER TABLE Club ADD COLUMN Currency_Balance DECIMAL(10, 2) NOT NULL DEFAULT 0.00;

-- Create Currency Transaction Log
CREATE TABLE Currency_Transaction (
    Transaction_ID INT PRIMARY KEY AUTO_INCREMENT,
    Club_ID INT NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    Transaction_Type ENUM('Earned', 'Spent', 'Bonus', 'Penalty') NOT NULL,
    Source VARCHAR(100) NOT NULL,
    Description TEXT,
    Created_At TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Club_ID) REFERENCES Club(Club_ID) ON DELETE CASCADE,
    CONSTRAINT chk_amount CHECK (Amount != 0)
);

-- Create Equipment Auction table
CREATE TABLE Equipment_Auction (
    Auction_ID INT PRIMARY KEY AUTO_INCREMENT,
    Equip_ID INT NOT NULL,
    Owner_Club_ID INT NOT NULL,
    Starting_Price DECIMAL(10, 2) NOT NULL,
    Current_Highest_Bid DECIMAL(10, 2) DEFAULT NULL,
    Highest_Bidder_Club_ID INT DEFAULT NULL,
    Auction_Start DATETIME NOT NULL,
    Auction_End DATETIME NOT NULL,
    Status ENUM('Active', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Active',
    Winner_Club_ID INT DEFAULT NULL,
    Created_At TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Equip_ID) REFERENCES Equipment(Equip_ID) ON DELETE CASCADE,
    FOREIGN KEY (Owner_Club_ID) REFERENCES Club(Club_ID) ON DELETE CASCADE,
    FOREIGN KEY (Highest_Bidder_Club_ID) REFERENCES Club(Club_ID) ON DELETE SET NULL,
    FOREIGN KEY (Winner_Club_ID) REFERENCES Club(Club_ID) ON DELETE SET NULL,
    CONSTRAINT chk_auction_time CHECK (Auction_End > Auction_Start),
    CONSTRAINT chk_starting_price CHECK (Starting_Price > 0)
);

-- Create Bid History table
CREATE TABLE Bid_History (
    Bid_ID INT PRIMARY KEY AUTO_INCREMENT,
    Auction_ID INT NOT NULL,
    Club_ID INT NOT NULL,
    Bid_Amount DECIMAL(10, 2) NOT NULL,
    Bid_Time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Status ENUM('Active', 'Outbid', 'Won', 'Lost') NOT NULL DEFAULT 'Active',
    FOREIGN KEY (Auction_ID) REFERENCES Equipment_Auction(Auction_ID) ON DELETE CASCADE,
    FOREIGN KEY (Club_ID) REFERENCES Club(Club_ID) ON DELETE CASCADE,
    CONSTRAINT chk_bid_amount CHECK (Bid_Amount > 0)
);

-- Trigger: Award currency when volunteer hours are verified
DELIMITER //
CREATE TRIGGER award_currency_on_volunteer_verification
AFTER UPDATE ON Volunteer_Log
FOR EACH ROW
BEGIN
    DECLARE club_id INT;
    DECLARE currency_earned DECIMAL(10, 2);
    
    -- Only process if verification status changed from NULL to verified
    IF OLD.Verified_By IS NULL AND NEW.Verified_By IS NOT NULL THEN
        -- Get the club ID from membership
        SELECT Club_ID INTO club_id
        FROM Membership
        WHERE Student_ID = NEW.Student_ID
        LIMIT 1;
        
        IF club_id IS NOT NULL THEN
            -- Calculate currency: 10 coins per hour
            SET currency_earned = NEW.Hours_Worked * 10;
            
            -- Update club balance
            UPDATE Club
            SET Currency_Balance = Currency_Balance + currency_earned
            WHERE Club_ID = club_id;
            
            -- Log transaction
            INSERT INTO Currency_Transaction (Club_ID, Amount, Transaction_Type, Source, Description)
            VALUES (club_id, currency_earned, 'Earned', 'Volunteer Hours', 
                    CONCAT('Earned from ', NEW.Hours_Worked, ' volunteer hours by student ID ', NEW.Student_ID));
        END IF;
    END IF;
END//
DELIMITER ;

-- Trigger: Award currency when badge is earned
DELIMITER //
CREATE TRIGGER award_currency_on_badge_earned
AFTER INSERT ON Volunteer_Badge
FOR EACH ROW
BEGIN
    DECLARE club_id INT;
    DECLARE currency_earned DECIMAL(10, 2);
    DECLARE badge_tier VARCHAR(20);
    
    -- Get the club ID from membership
    SELECT Club_ID INTO club_id
    FROM Membership
    WHERE Student_ID = NEW.Student_ID
    LIMIT 1;
    
    -- Get badge tier
    SELECT Tier INTO badge_tier
    FROM Badge
    WHERE Badge_ID = NEW.Badge_ID;
    
    IF club_id IS NOT NULL THEN
        -- Calculate currency based on badge tier
        SET currency_earned = CASE badge_tier
            WHEN 'Bronze' THEN 50
            WHEN 'Silver' THEN 100
            WHEN 'Gold' THEN 200
            WHEN 'Platinum' THEN 500
            WHEN 'Diamond' THEN 1000
            ELSE 25
        END;
        
        -- Update club balance
        UPDATE Club
        SET Currency_Balance = Currency_Balance + currency_earned
        WHERE Club_ID = club_id;
        
        -- Log transaction
        INSERT INTO Currency_Transaction (Club_ID, Amount, Transaction_Type, Source, Description)
        VALUES (club_id, currency_earned, 'Bonus', 'Badge Achievement', 
                CONCAT('Earned from ', badge_tier, ' badge achievement by student ID ', NEW.Student_ID));
    END IF;
END//
DELIMITER ;

-- Trigger: Update auction status when bid is placed
DELIMITER //
CREATE TRIGGER update_auction_on_bid
AFTER INSERT ON Bid_History
FOR EACH ROW
BEGIN
    DECLARE current_highest DECIMAL(10, 2);
    
    -- Get current highest bid
    SELECT Current_Highest_Bid INTO current_highest
    FROM Equipment_Auction
    WHERE Auction_ID = NEW.Auction_ID;
    
    -- Update auction if this bid is higher
    IF current_highest IS NULL OR NEW.Bid_Amount > current_highest THEN
        -- Mark previous highest bid as outbid
        UPDATE Bid_History
        SET Status = 'Outbid'
        WHERE Auction_ID = NEW.Auction_ID 
        AND Status = 'Active'
        AND Bid_ID != NEW.Bid_ID;
        
        -- Update auction with new highest bid
        UPDATE Equipment_Auction
        SET Current_Highest_Bid = NEW.Bid_Amount,
            Highest_Bidder_Club_ID = NEW.Club_ID
        WHERE Auction_ID = NEW.Auction_ID;
    END IF;
END//
DELIMITER ;

-- Stored Procedure: Complete auction and transfer equipment
DELIMITER //
CREATE PROCEDURE complete_auction(IN p_auction_id INT)
BEGIN
    DECLARE v_winner_club_id INT;
    DECLARE v_owner_club_id INT;
    DECLARE v_equip_id INT;
    DECLARE v_final_price DECIMAL(10, 2);
    DECLARE v_auction_status VARCHAR(20);
    
    -- Get auction details
    SELECT Highest_Bidder_Club_ID, Owner_Club_ID, Equip_ID, Current_Highest_Bid, Status
    INTO v_winner_club_id, v_owner_club_id, v_equip_id, v_final_price, v_auction_status
    FROM Equipment_Auction
    WHERE Auction_ID = p_auction_id;
    
    -- Only process if auction is active and has ended
    IF v_auction_status = 'Active' AND NOW() >= (SELECT Auction_End FROM Equipment_Auction WHERE Auction_ID = p_auction_id) THEN
        IF v_winner_club_id IS NOT NULL THEN
            -- Deduct currency from winner
            UPDATE Club
            SET Currency_Balance = Currency_Balance - v_final_price
            WHERE Club_ID = v_winner_club_id;
            
            -- Add currency to owner
            UPDATE Club
            SET Currency_Balance = Currency_Balance + v_final_price
            WHERE Club_ID = v_owner_club_id;
            
            -- Transfer equipment ownership
            UPDATE Equipment
            SET Owner_Club_ID = v_winner_club_id
            WHERE Equip_ID = v_equip_id;
            
            -- Update auction status
            UPDATE Equipment_Auction
            SET Status = 'Completed',
                Winner_Club_ID = v_winner_club_id
            WHERE Auction_ID = p_auction_id;
            
            -- Mark winning bid
            UPDATE Bid_History
            SET Status = 'Won'
            WHERE Auction_ID = p_auction_id AND Club_ID = v_winner_club_id AND Status = 'Active';
            
            -- Mark losing bids
            UPDATE Bid_History
            SET Status = 'Lost'
            WHERE Auction_ID = p_auction_id AND Club_ID != v_winner_club_id AND Status = 'Outbid';
            
            -- Log transactions
            INSERT INTO Currency_Transaction (Club_ID, Amount, Transaction_Type, Source, Description)
            VALUES (v_winner_club_id, -v_final_price, 'Spent', 'Equipment Auction', 
                    CONCAT('Won auction #', p_auction_id, ' for equipment #', v_equip_id));
            
            INSERT INTO Currency_Transaction (Club_ID, Amount, Transaction_Type, Source, Description)
            VALUES (v_owner_club_id, v_final_price, 'Earned', 'Equipment Auction', 
                    CONCAT('Sold equipment #', v_equip_id, ' in auction #', p_auction_id));
        ELSE
            -- No bids, cancel auction
            UPDATE Equipment_Auction
            SET Status = 'Cancelled'
            WHERE Auction_ID = p_auction_id;
        END IF;
    END IF;
END//
DELIMITER ;

-- View: Active Auctions with Equipment Details
CREATE OR REPLACE VIEW Active_Auctions_View AS
SELECT 
    ea.Auction_ID,
    ea.Equip_ID,
    e.Name AS Equipment_Name,
    e.Type AS Equipment_Type,
    c1.Name AS Owner_Club,
    ea.Starting_Price,
    ea.Current_Highest_Bid,
    c2.Name AS Highest_Bidder_Club,
    ea.Auction_Start,
    ea.Auction_End,
    TIMESTAMPDIFF(HOUR, NOW(), ea.Auction_End) AS Hours_Remaining,
    (SELECT COUNT(*) FROM Bid_History WHERE Auction_ID = ea.Auction_ID) AS Total_Bids
FROM Equipment_Auction ea
JOIN Equipment e ON ea.Equip_ID = e.Equip_ID
JOIN Club c1 ON ea.Owner_Club_ID = c1.Club_ID
LEFT JOIN Club c2 ON ea.Highest_Bidder_Club_ID = c2.Club_ID
WHERE ea.Status = 'Active' AND ea.Auction_End > NOW()
ORDER BY ea.Auction_End ASC;

-- View: Club Currency Leaderboard
CREATE OR REPLACE VIEW Club_Currency_Leaderboard AS
SELECT 
    c.Club_ID,
    c.Name AS Club_Name,
    c.Currency_Balance,
    COUNT(DISTINCT m.Student_ID) AS Total_Members,
    COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Volunteer_Hours,
    COUNT(DISTINCT vb.Badge_ID) AS Total_Badges_Earned,
    (SELECT COUNT(*) FROM Equipment WHERE Owner_Club_ID = c.Club_ID) AS Equipment_Owned
FROM Club c
LEFT JOIN Membership m ON c.Club_ID = m.Club_ID
LEFT JOIN Volunteer_Log vl ON m.Student_ID = vl.Student_ID AND vl.Verified_By IS NOT NULL
LEFT JOIN Volunteer_Badge vb ON m.Student_ID = vb.Student_ID
GROUP BY c.Club_ID, c.Name, c.Currency_Balance
ORDER BY c.Currency_Balance DESC;
