<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

require_once 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? $_POST['action'] ?? '';

try {
    switch ($action) {
        case 'get_all_bookings':
            // Get all bookings with filters
            $status = $_GET['status'] ?? null;
            $equip_id = $_GET['equip_id'] ?? null;
            $event_id = $_GET['event_id'] ?? null;
            
            $query = "
                SELECT rb.Booking_ID, rb.Equip_ID, rb.Event_ID, rb.Borrow_Time, rb.Return_Time, rb.Status,
                       e.Name AS Equipment_Name, e.Type AS Equipment_Type,
                       ev.Title AS Event_Title, ev.Date AS Event_Date,
                       c.Name AS Event_Club
                FROM Resource_Booking rb
                JOIN Equipment e ON rb.Equip_ID = e.Equip_ID
                JOIN Event ev ON rb.Event_ID = ev.Event_ID
                JOIN Club c ON ev.Primary_Club_ID = c.Club_ID
                WHERE 1=1
            ";
            
            $params = [];
            $types = "";
            
            if ($status) {
                $query .= " AND rb.Status = ?";
                $params[] = $status;
                $types .= "s";
            }
            if ($equip_id) {
                $query .= " AND rb.Equip_ID = ?";
                $params[] = $equip_id;
                $types .= "i";
            }
            if ($event_id) {
                $query .= " AND rb.Event_ID = ?";
                $params[] = $event_id;
                $types .= "i";
            }
            
            $query .= " ORDER BY rb.Borrow_Time DESC";
            
            $stmt = $conn->prepare($query);
            if (!empty($params)) {
                $stmt->bind_param($types, ...$params);
            }
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_booking':
            // Get single booking details
            $booking_id = $_GET['booking_id'] ?? null;
            if (!$booking_id) {
                throw new Exception('Booking ID is required');
            }
            
            $stmt = $conn->prepare("
                SELECT rb.*, e.Name AS Equipment_Name, e.Type AS Equipment_Type, e.Status AS Equipment_Status,
                       ev.Title AS Event_Title, ev.Date AS Event_Date, ev.Venue,
                       c.Name AS Event_Club
                FROM Resource_Booking rb
                JOIN Equipment e ON rb.Equip_ID = e.Equip_ID
                JOIN Event ev ON rb.Event_ID = ev.Event_ID
                JOIN Club c ON ev.Primary_Club_ID = c.Club_ID
                WHERE rb.Booking_ID = ?
            ");
            $stmt->bind_param("i", $booking_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $data = $result->fetch_assoc();
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'create_booking':
            // Create new booking
            $data = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($data['equip_id']) || !isset($data['event_id']) || 
                !isset($data['borrow_time']) || !isset($data['return_time'])) {
                throw new Exception('Missing required fields');
            }
            
            // Get next booking ID
            $result = $conn->query("SELECT MAX(Booking_ID) AS max_id FROM Resource_Booking");
            $row = $result->fetch_assoc();
            $booking_id = ($row['max_id'] ?? 3000) + 1;
            
            $stmt = $conn->prepare("
                INSERT INTO Resource_Booking (Booking_ID, Equip_ID, Event_ID, Borrow_Time, Return_Time, Status)
                VALUES (?, ?, ?, ?, ?, 'Confirmed')
            ");
            $stmt->bind_param("iiiss", 
                $booking_id,
                $data['equip_id'],
                $data['event_id'],
                $data['borrow_time'],
                $data['return_time']
            );
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'Booking created successfully', 'booking_id' => $booking_id]);
            break;

        case 'update_booking':
            // Update booking
            $data = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($data['booking_id'])) {
                throw new Exception('Booking ID is required');
            }
            
            $stmt = $conn->prepare("
                UPDATE Resource_Booking 
                SET Equip_ID = ?, Event_ID = ?, Borrow_Time = ?, Return_Time = ?, Status = ?
                WHERE Booking_ID = ?
            ");
            $stmt->bind_param("iisssi",
                $data['equip_id'],
                $data['event_id'],
                $data['borrow_time'],
                $data['return_time'],
                $data['status'],
                $data['booking_id']
            );
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'Booking updated successfully']);
            break;

        case 'cancel_booking':
            // Cancel booking
            $booking_id = $_POST['booking_id'] ?? null;
            if (!$booking_id) {
                throw new Exception('Booking ID is required');
            }
            
            $stmt = $conn->prepare("UPDATE Resource_Booking SET Status = 'Cancelled' WHERE Booking_ID = ?");
            $stmt->bind_param("i", $booking_id);
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'Booking cancelled successfully']);
            break;

        case 'complete_booking':
            // Mark booking as completed
            $booking_id = $_POST['booking_id'] ?? null;
            if (!$booking_id) {
                throw new Exception('Booking ID is required');
            }
            
            $stmt = $conn->prepare("UPDATE Resource_Booking SET Status = 'Completed' WHERE Booking_ID = ?");
            $stmt->bind_param("i", $booking_id);
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'Booking marked as completed']);
            break;

        case 'check_availability':
            // Check if equipment is available for a time slot
            $equip_id = $_GET['equip_id'] ?? null;
            $borrow_time = $_GET['borrow_time'] ?? null;
            $return_time = $_GET['return_time'] ?? null;
            
            if (!$equip_id || !$borrow_time || !$return_time) {
                throw new Exception('Equipment ID, borrow time, and return time are required');
            }
            
            // Check equipment status
            $stmt = $conn->prepare("SELECT Status FROM Equipment WHERE Equip_ID = ?");
            $stmt->bind_param("i", $equip_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $equip = $result->fetch_assoc();
            
            if ($equip['Status'] == 'Damaged' || $equip['Status'] == 'Maintenance') {
                echo json_encode([
                    'success' => true, 
                    'available' => false, 
                    'reason' => 'Equipment is ' . $equip['Status']
                ]);
                break;
            }
            
            // Check for conflicts
            $stmt = $conn->prepare("
                SELECT COUNT(*) AS conflict_count
                FROM Resource_Booking
                WHERE Equip_ID = ?
                  AND Status = 'Confirmed'
                  AND (? < Return_Time AND ? > Borrow_Time)
            ");
            $stmt->bind_param("iss", $equip_id, $borrow_time, $return_time);
            $stmt->execute();
            $result = $stmt->get_result();
            $row = $result->fetch_assoc();
            
            if ($row['conflict_count'] > 0) {
                echo json_encode([
                    'success' => true, 
                    'available' => false, 
                    'reason' => 'Equipment is already booked for this time slot'
                ]);
            } else {
                echo json_encode(['success' => true, 'available' => true]);
            }
            break;

        case 'get_next_available':
            // Get next available time for equipment
            $equip_id = $_GET['equip_id'] ?? null;
            if (!$equip_id) {
                throw new Exception('Equipment ID is required');
            }
            
            $stmt = $conn->prepare("
                SELECT MIN(Return_Time) AS Next_Available
                FROM Resource_Booking
                WHERE Equip_ID = ?
                  AND Status = 'Confirmed'
                  AND Return_Time > NOW()
            ");
            $stmt->bind_param("i", $equip_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $data = $result->fetch_assoc();
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_upcoming_bookings':
            // Get upcoming bookings
            $limit = $_GET['limit'] ?? 10;
            $stmt = $conn->prepare("
                SELECT rb.*, e.Name AS Equipment_Name, ev.Title AS Event_Title, ev.Date AS Event_Date
                FROM Resource_Booking rb
                JOIN Equipment e ON rb.Equip_ID = e.Equip_ID
                JOIN Event ev ON rb.Event_ID = ev.Event_ID
                WHERE rb.Status = 'Confirmed' AND rb.Borrow_Time > NOW()
                ORDER BY rb.Borrow_Time ASC
                LIMIT ?
            ");
            $stmt->bind_param("i", $limit);
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_booking_history':
            // Get booking history for equipment or event
            $equip_id = $_GET['equip_id'] ?? null;
            $event_id = $_GET['event_id'] ?? null;
            
            if (!$equip_id && !$event_id) {
                throw new Exception('Equipment ID or Event ID is required');
            }
            
            $query = "
                SELECT rb.*, e.Name AS Equipment_Name, ev.Title AS Event_Title, ev.Date AS Event_Date,
                       c.Name AS Event_Club
                FROM Resource_Booking rb
                JOIN Equipment e ON rb.Equip_ID = e.Equip_ID
                JOIN Event ev ON rb.Event_ID = ev.Event_ID
                JOIN Club c ON ev.Primary_Club_ID = c.Club_ID
                WHERE 1=1
            ";
            
            if ($equip_id) {
                $query .= " AND rb.Equip_ID = ?";
                $stmt = $conn->prepare($query . " ORDER BY rb.Borrow_Time DESC");
                $stmt->bind_param("i", $equip_id);
            } else {
                $query .= " AND rb.Event_ID = ?";
                $stmt = $conn->prepare($query . " ORDER BY rb.Borrow_Time DESC");
                $stmt->bind_param("i", $event_id);
            }
            
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_conflicts':
            // Get booking conflicts
            $stmt = $conn->prepare("SELECT * FROM Booking_Conflicts_Report");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        default:
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
