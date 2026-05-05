<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

require_once 'db_connect.php';

$action = $_GET['action'] ?? $_POST['action'] ?? '';

try {
    switch ($action) {
        case 'get_all_volunteers':
            // Get all volunteer logs with filters
            $student_id = $_GET['student_id'] ?? null;
            $event_id = $_GET['event_id'] ?? null;
            $verified = $_GET['verified'] ?? null;
            
            $query = "
                SELECT vl.Log_ID, vl.Student_ID, vl.Event_ID, vl.Role, vl.Hours_Worked,
                       vl.Verified_By, vl.Verification_Date,
                       s.Name AS Student_Name, s.Email AS Student_Email,
                       ev.Title AS Event_Title, ev.Date AS Event_Date,
                       c.Name AS Event_Club,
                       ve.Name AS Verifier_Name
                FROM Volunteer_Log vl
                JOIN Student s ON vl.Student_ID = s.Student_ID
                JOIN Event ev ON vl.Event_ID = ev.Event_ID
                JOIN Club c ON ev.Primary_Club_ID = c.Club_ID
                LEFT JOIN Student ve ON vl.Verified_By = ve.Student_ID
                WHERE 1=1
            ";
            
            $params = [];
            $types = "";
            
            if ($student_id) {
                $query .= " AND vl.Student_ID = ?";
                $params[] = $student_id;
                $types .= "i";
            }
            if ($event_id) {
                $query .= " AND vl.Event_ID = ?";
                $params[] = $event_id;
                $types .= "i";
            }
            if ($verified !== null) {
                if ($verified == 'true' || $verified == '1') {
                    $query .= " AND vl.Verified_By IS NOT NULL";
                } else {
                    $query .= " AND vl.Verified_By IS NULL";
                }
            }
            
            $query .= " ORDER BY vl.Verification_Date DESC, ev.Date DESC";
            
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

        case 'get_volunteer_log':
            // Get single volunteer log
            $log_id = $_GET['log_id'] ?? null;
            if (!$log_id) {
                throw new Exception('Log ID is required');
            }
            
            $stmt = $conn->prepare("
                SELECT vl.*, s.Name AS Student_Name, s.Email AS Student_Email,
                       ev.Title AS Event_Title, ev.Date AS Event_Date, ev.Venue,
                       c.Name AS Event_Club,
                       ve.Name AS Verifier_Name
                FROM Volunteer_Log vl
                JOIN Student s ON vl.Student_ID = s.Student_ID
                JOIN Event ev ON vl.Event_ID = ev.Event_ID
                JOIN Club c ON ev.Primary_Club_ID = c.Club_ID
                LEFT JOIN Student ve ON vl.Verified_By = ve.Student_ID
                WHERE vl.Log_ID = ?
            ");
            $stmt->bind_param("i", $log_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $data = $result->fetch_assoc();
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'create_volunteer_log':
            // Create new volunteer log
            $data = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($data['student_id']) || !isset($data['event_id']) || 
                !isset($data['role']) || !isset($data['hours_worked'])) {
                throw new Exception('Missing required fields');
            }
            
            // Get next log ID
            $result = $conn->query("SELECT MAX(Log_ID) AS max_id FROM Volunteer_Log");
            $row = $result->fetch_assoc();
            $log_id = ($row['max_id'] ?? 4000) + 1;
            
            $stmt = $conn->prepare("
                INSERT INTO Volunteer_Log (Log_ID, Student_ID, Event_ID, Role, Hours_Worked, Verified_By, Verification_Date)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ");
            
            $verified_by = $data['verified_by'] ?? null;
            $verification_date = $data['verification_date'] ?? null;
            
            $stmt->bind_param("iiisdis", 
                $log_id,
                $data['student_id'],
                $data['event_id'],
                $data['role'],
                $data['hours_worked'],
                $verified_by,
                $verification_date
            );
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'Volunteer log created successfully', 'log_id' => $log_id]);
            break;

        case 'update_volunteer_log':
            // Update volunteer log
            $data = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($data['log_id'])) {
                throw new Exception('Log ID is required');
            }
            
            $stmt = $conn->prepare("
                UPDATE Volunteer_Log 
                SET Student_ID = ?, Event_ID = ?, Role = ?, Hours_Worked = ?, Verified_By = ?, Verification_Date = ?
                WHERE Log_ID = ?
            ");
            
            $verified_by = $data['verified_by'] ?? null;
            $verification_date = $data['verification_date'] ?? null;
            
            $stmt->bind_param("iisdisi",
                $data['student_id'],
                $data['event_id'],
                $data['role'],
                $data['hours_worked'],
                $verified_by,
                $verification_date,
                $data['log_id']
            );
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'Volunteer log updated successfully']);
            break;

        case 'verify_hours':
            // Verify volunteer hours
            $log_id = $_POST['log_id'] ?? null;
            $verified_by = $_POST['verified_by'] ?? null;
            
            if (!$log_id || !$verified_by) {
                throw new Exception('Log ID and Verifier ID are required');
            }
            
            $stmt = $conn->prepare("
                UPDATE Volunteer_Log 
                SET Verified_By = ?, Verification_Date = CURDATE()
                WHERE Log_ID = ?
            ");
            $stmt->bind_param("ii", $verified_by, $log_id);
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'Hours verified successfully']);
            break;

        case 'delete_volunteer_log':
            // Delete volunteer log
            $log_id = $_POST['log_id'] ?? null;
            if (!$log_id) {
                throw new Exception('Log ID is required');
            }
            
            $stmt = $conn->prepare("DELETE FROM Volunteer_Log WHERE Log_ID = ?");
            $stmt->bind_param("i", $log_id);
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'Volunteer log deleted successfully']);
            break;

        case 'get_student_volunteer_summary':
            // Get volunteer summary for a student
            $student_id = $_GET['student_id'] ?? null;
            if (!$student_id) {
                throw new Exception('Student ID is required');
            }
            
            $stmt = $conn->prepare("SELECT * FROM Student_Volunteer_Profile WHERE Student_ID = ?");
            $stmt->bind_param("i", $student_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $data = $result->fetch_assoc();
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_event_volunteers':
            // Get all volunteers for an event
            $event_id = $_GET['event_id'] ?? null;
            if (!$event_id) {
                throw new Exception('Event ID is required');
            }
            
            $stmt = $conn->prepare("
                SELECT vl.*, s.Name AS Student_Name, s.Email AS Student_Email,
                       ve.Name AS Verifier_Name
                FROM Volunteer_Log vl
                JOIN Student s ON vl.Student_ID = s.Student_ID
                LEFT JOIN Student ve ON vl.Verified_By = ve.Student_ID
                WHERE vl.Event_ID = ?
                ORDER BY vl.Hours_Worked DESC
            ");
            $stmt->bind_param("i", $event_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_available_volunteers':
            // Get volunteers available today
            $stmt = $conn->prepare("SELECT * FROM Available_Volunteers");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_cross_club_volunteers':
            // Get cross-club volunteers
            $stmt = $conn->prepare("SELECT * FROM Cross_Club_Volunteers");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_volunteer_roles':
            // Get distinct volunteer roles
            $stmt = $conn->prepare("SELECT DISTINCT Role FROM Volunteer_Log ORDER BY Role");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row['Role'];
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_unverified_hours':
            // Get unverified volunteer hours
            $stmt = $conn->prepare("
                SELECT vl.*, s.Name AS Student_Name, ev.Title AS Event_Title, ev.Date AS Event_Date
                FROM Volunteer_Log vl
                JOIN Student s ON vl.Student_ID = s.Student_ID
                JOIN Event ev ON vl.Event_ID = ev.Event_ID
                WHERE vl.Verified_By IS NULL
                ORDER BY ev.Date DESC
            ");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_volunteer_portfolio':
            // Get complete volunteer portfolio for a student
            $student_id = $_GET['student_id'] ?? null;
            if (!$student_id) {
                throw new Exception('Student ID is required');
            }
            
            // Get profile
            $stmt = $conn->prepare("SELECT * FROM Student_Volunteer_Profile WHERE Student_ID = ?");
            $stmt->bind_param("i", $student_id);
            $stmt->execute();
            $profile = $stmt->get_result()->fetch_assoc();
            
            // Get badges
            $stmt = $conn->prepare("
                SELECT b.*, vb.Earned_Date, vb.Total_Hours_At_Earning
                FROM Volunteer_Badge vb
                JOIN Badge b ON vb.Badge_ID = b.Badge_ID
                WHERE vb.Student_ID = ?
                ORDER BY vb.Earned_Date DESC
            ");
            $stmt->bind_param("i", $student_id);
            $stmt->execute();
            $badges = [];
            $result = $stmt->get_result();
            while ($row = $result->fetch_assoc()) {
                $badges[] = $row;
            }
            
            // Get volunteer logs
            $stmt = $conn->prepare("
                SELECT vl.*, ev.Title AS Event_Title, ev.Date AS Event_Date, c.Name AS Event_Club
                FROM Volunteer_Log vl
                JOIN Event ev ON vl.Event_ID = ev.Event_ID
                JOIN Club c ON ev.Primary_Club_ID = c.Club_ID
                WHERE vl.Student_ID = ?
                ORDER BY ev.Date DESC
            ");
            $stmt->bind_param("i", $student_id);
            $stmt->execute();
            $logs = [];
            $result = $stmt->get_result();
            while ($row = $result->fetch_assoc()) {
                $logs[] = $row;
            }
            
            echo json_encode([
                'success' => true, 
                'data' => [
                    'profile' => $profile,
                    'badges' => $badges,
                    'volunteer_logs' => $logs
                ]
            ]);
            break;

        default:
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
