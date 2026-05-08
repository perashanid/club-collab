<?php
session_start();
require_once 'db_connect.php';
header('Content-Type: application/json');

$action = $_POST['action'] ?? $_GET['action'] ?? '';

switch ($action) {
    case 'get_active_auctions':
        getActiveAuctions($conn);
        break;
    case 'get_auction_details':
        getAuctionDetails($conn);
        break;
    case 'create_auction':
        createAuction($conn);
        break;
    case 'place_bid':
        placeBid($conn);
        break;
    case 'get_bid_history':
        getBidHistory($conn);
        break;
    case 'get_club_currency':
        getClubCurrency($conn);
        break;
    case 'get_currency_leaderboard':
        getCurrencyLeaderboard($conn);
        break;
    case 'get_my_auctions':
        getMyAuctions($conn);
        break;
    case 'get_my_bids':
        getMyBids($conn);
        break;
    case 'cancel_auction':
        cancelAuction($conn);
        break;
    case 'complete_expired_auctions':
        completeExpiredAuctions($conn);
        break;
    default:
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
}

function getActiveAuctions($conn) {
    $sql = "SELECT * FROM Active_Auctions_View";
    $result = $conn->query($sql);
    
    $auctions = [];
    while ($row = $result->fetch_assoc()) {
        $auctions[] = $row;
    }
    
    echo json_encode(['success' => true, 'auctions' => $auctions]);
}

function getAuctionDetails($conn) {
    $auction_id = $_GET['auction_id'] ?? 0;
    
    $sql = "SELECT ea.*, e.Name AS Equipment_Name, e.Type, e.Status AS Equipment_Status,
                   c1.Name AS Owner_Club, c2.Name AS Highest_Bidder_Club
            FROM Equipment_Auction ea
            JOIN Equipment e ON ea.Equip_ID = e.Equip_ID
            JOIN Club c1 ON ea.Owner_Club_ID = c1.Club_ID
            LEFT JOIN Club c2 ON ea.Highest_Bidder_Club_ID = c2.Club_ID
            WHERE ea.Auction_ID = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $auction_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        echo json_encode(['success' => true, 'auction' => $row]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Auction not found']);
    }
}

function createAuction($conn) {
    $equip_id = $_POST['equip_id'] ?? 0;
    $starting_price = $_POST['starting_price'] ?? 0;
    $duration_hours = $_POST['duration_hours'] ?? 24;
    
    // Get equipment owner
    $sql = "SELECT Owner_Club_ID FROM Equipment WHERE Equip_ID = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $equip_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        $owner_club_id = $row['Owner_Club_ID'];
        
        $auction_start = date('Y-m-d H:i:s');
        $auction_end = date('Y-m-d H:i:s', strtotime("+$duration_hours hours"));
        
        $sql = "INSERT INTO Equipment_Auction (Equip_ID, Owner_Club_ID, Starting_Price, Auction_Start, Auction_End)
                VALUES (?, ?, ?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("iidss", $equip_id, $owner_club_id, $starting_price, $auction_start, $auction_end);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Auction created successfully', 'auction_id' => $conn->insert_id]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Failed to create auction']);
        }
    } else {
        echo json_encode(['success' => false, 'message' => 'Equipment not found']);
    }
}

function placeBid($conn) {
    $auction_id = $_POST['auction_id'] ?? 0;
    $club_id = $_POST['club_id'] ?? 0;
    $bid_amount = $_POST['bid_amount'] ?? 0;
    
    // Check if auction is active
    $sql = "SELECT Status, Auction_End, Current_Highest_Bid, Owner_Club_ID FROM Equipment_Auction WHERE Auction_ID = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $auction_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        if ($row['Status'] != 'Active') {
            echo json_encode(['success' => false, 'message' => 'Auction is not active']);
            return;
        }
        
        if (strtotime($row['Auction_End']) < time()) {
            echo json_encode(['success' => false, 'message' => 'Auction has ended']);
            return;
        }
        
        if ($row['Owner_Club_ID'] == $club_id) {
            echo json_encode(['success' => false, 'message' => 'Cannot bid on your own auction']);
            return;
        }
        
        $min_bid = $row['Current_Highest_Bid'] ? $row['Current_Highest_Bid'] + 10 : 0;
        if ($bid_amount <= $min_bid) {
            echo json_encode(['success' => false, 'message' => 'Bid must be higher than current highest bid']);
            return;
        }
        
        // Check club balance
        $sql = "SELECT Currency_Balance FROM Club WHERE Club_ID = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $club_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $club = $result->fetch_assoc();
        
        if ($club['Currency_Balance'] < $bid_amount) {
            echo json_encode(['success' => false, 'message' => 'Insufficient currency balance']);
            return;
        }
        
        // Mark previous active bids as outbid
        $sql = "UPDATE Bid_History SET Status = 'Outbid' WHERE Auction_ID = ? AND Status = 'Active'";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $auction_id);
        $stmt->execute();
        
        // Place bid
        $sql = "INSERT INTO Bid_History (Auction_ID, Club_ID, Bid_Amount) VALUES (?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("iid", $auction_id, $club_id, $bid_amount);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Bid placed successfully']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Failed to place bid']);
        }
    } else {
        echo json_encode(['success' => false, 'message' => 'Auction not found']);
    }
}

function getBidHistory($conn) {
    $auction_id = $_GET['auction_id'] ?? 0;
    
    $sql = "SELECT bh.*, c.Name AS Club_Name
            FROM Bid_History bh
            JOIN Club c ON bh.Club_ID = c.Club_ID
            WHERE bh.Auction_ID = ?
            ORDER BY bh.Bid_Amount DESC, bh.Bid_Time DESC";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $auction_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $bids = [];
    while ($row = $result->fetch_assoc()) {
        $bids[] = $row;
    }
    
    echo json_encode(['success' => true, 'bids' => $bids]);
}

function getClubCurrency($conn) {
    $club_id = $_GET['club_id'] ?? 0;
    
    $sql = "SELECT Currency_Balance FROM Club WHERE Club_ID = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $club_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        echo json_encode(['success' => true, 'balance' => $row['Currency_Balance']]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Club not found']);
    }
}

function getCurrencyLeaderboard($conn) {
    $sql = "SELECT * FROM Club_Currency_Leaderboard";
    $result = $conn->query($sql);
    
    $leaderboard = [];
    while ($row = $result->fetch_assoc()) {
        $leaderboard[] = $row;
    }
    
    echo json_encode(['success' => true, 'leaderboard' => $leaderboard]);
}

function getMyAuctions($conn) {
    $club_id = $_GET['club_id'] ?? 0;
    
    $sql = "SELECT ea.*, e.Name AS Equipment_Name, e.Type,
                   c.Name AS Highest_Bidder_Club, ea.Current_Highest_Bid
            FROM Equipment_Auction ea
            JOIN Equipment e ON ea.Equip_ID = e.Equip_ID
            LEFT JOIN Club c ON ea.Highest_Bidder_Club_ID = c.Club_ID
            WHERE ea.Owner_Club_ID = ?
            ORDER BY ea.Created_At DESC";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $club_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $auctions = [];
    while ($row = $result->fetch_assoc()) {
        $auctions[] = $row;
    }
    
    echo json_encode(['success' => true, 'auctions' => $auctions]);
}

function getMyBids($conn) {
    $club_id = $_GET['club_id'] ?? 0;
    
    $sql = "SELECT bh.*, ea.Equip_ID, e.Name AS Equipment_Name, 
                   ea.Status AS Auction_Status, ea.Auction_End,
                   c.Name AS Owner_Club
            FROM Bid_History bh
            JOIN Equipment_Auction ea ON bh.Auction_ID = ea.Auction_ID
            JOIN Equipment e ON ea.Equip_ID = e.Equip_ID
            JOIN Club c ON ea.Owner_Club_ID = c.Club_ID
            WHERE bh.Club_ID = ?
            ORDER BY bh.Bid_Time DESC";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $club_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $bids = [];
    while ($row = $result->fetch_assoc()) {
        $bids[] = $row;
    }
    
    echo json_encode(['success' => true, 'bids' => $bids]);
}

function cancelAuction($conn) {
    $auction_id = $_POST['auction_id'] ?? 0;
    $club_id = $_POST['club_id'] ?? 0;
    
    // Verify ownership
    $sql = "SELECT Owner_Club_ID, Status FROM Equipment_Auction WHERE Auction_ID = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $auction_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        if ($row['Owner_Club_ID'] != $club_id) {
            echo json_encode(['success' => false, 'message' => 'Not authorized']);
            return;
        }
        
        if ($row['Status'] != 'Active') {
            echo json_encode(['success' => false, 'message' => 'Auction cannot be cancelled']);
            return;
        }
        
        $sql = "UPDATE Equipment_Auction SET Status = 'Cancelled' WHERE Auction_ID = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $auction_id);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Auction cancelled']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Failed to cancel auction']);
        }
    } else {
        echo json_encode(['success' => false, 'message' => 'Auction not found']);
    }
}

function completeExpiredAuctions($conn) {
    $sql = "SELECT Auction_ID FROM Equipment_Auction 
            WHERE Status = 'Active' AND Auction_End < NOW()";
    $result = $conn->query($sql);
    
    $completed = 0;
    while ($row = $result->fetch_assoc()) {
        $stmt = $conn->prepare("CALL complete_auction(?)");
        $stmt->bind_param("i", $row['Auction_ID']);
        $stmt->execute();
        $completed++;
    }
    
    echo json_encode(['success' => true, 'message' => "$completed auctions completed"]);
}
?>
