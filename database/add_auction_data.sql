USE club_collab;

-- Create some sample auctions
-- Auction 1: Camera from Media Society
INSERT INTO Equipment_Auction (Equip_ID, Owner_Club_ID, Starting_Price, Current_Highest_Bid, Highest_Bidder_Club_ID, Auction_Start, Auction_End, Status)
VALUES (1, 1, 100, 150, 2, NOW(), DATE_ADD(NOW(), INTERVAL 24 HOUR), 'Active');

-- Auction 2: Projector from Tech Innovators
INSERT INTO Equipment_Auction (Equip_ID, Owner_Club_ID, Starting_Price, Current_Highest_Bid, Highest_Bidder_Club_ID, Auction_Start, Auction_End, Status)
VALUES (2, 2, 200, 250, 3, NOW(), DATE_ADD(NOW(), INTERVAL 48 HOUR), 'Active');

-- Auction 3: Microphone from Sports Alliance (no bids yet)
INSERT INTO Equipment_Auction (Equip_ID, Owner_Club_ID, Starting_Price, Auction_Start, Auction_End, Status)
VALUES (3, 3, 50, NOW(), DATE_ADD(NOW(), INTERVAL 12 HOUR), 'Active');

-- Add some bid history
INSERT INTO Bid_History (Auction_ID, Club_ID, Bid_Amount, Status)
VALUES 
(1, 2, 120, 'Outbid'),
(1, 3, 130, 'Outbid'),
(1, 2, 150, 'Active'),
(2, 3, 220, 'Outbid'),
(2, 1, 240, 'Outbid'),
(2, 3, 250, 'Active');

SELECT 'Sample auctions and bids created' AS Status;
SELECT * FROM Active_Auctions_View;
