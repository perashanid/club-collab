<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once 'db_connect.php';

$action = $_GET['action'] ?? $_POST['action'] ?? '';

try {
    switch ($action) {
        case 'get_all_badges':
            // Get all available badges
            $stmt = $conn->prepare("
                SELECT Badge_ID, Name, Description, Icon, Color, Hours_Required, Tier
                FROM Badge
                ORDER BY FIELD(Tier, 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'), Hours_Required
            ");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_student_badges':
            // Get badges earned by a specific student
            $student_id = $_GET['student_id'] ?? null;
            if (!$student_id) {
                throw new Exception('Student ID is required');
            }
            
            $stmt = $conn->prepare("
                SELECT b.Badge_ID, b.Name, b.Description, b.Icon, b.Color, 
                       b.Hours_Required, b.Tier, vb.Earned_Date, vb.Total_Hours_At_Earning
                FROM Volunteer_Badge vb
                JOIN Badge b ON vb.Badge_ID = b.Badge_ID
                WHERE vb.Student_ID = ?
                ORDER BY vb.Earned_Date DESC
            ");
            $stmt->bind_param("i", $student_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_badge_progress':
            // Get badge progress for a student
            $student_id = $_GET['student_id'] ?? null;
            if (!$student_id) {
                throw new Exception('Student ID is required');
            }
            
            $stmt = $conn->prepare("
                SELECT * FROM Volunteer_Stats WHERE Student_ID = ?
            ");
            $stmt->bind_param("i", $student_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $data = $result->fetch_assoc();
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_leaderboard':
            // Get volunteer leaderboard
            $limit = $_GET['limit'] ?? 10;
            $stmt = $conn->prepare("SELECT * FROM Volunteer_Leaderboard LIMIT ?");
            $stmt->bind_param("i", $limit);
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_badge_statistics':
            // Get badge distribution statistics
            $stmt = $conn->prepare("SELECT * FROM Badge_Statistics");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_next_badges':
            // Get next badges a student can earn
            $student_id = $_GET['student_id'] ?? null;
            if (!$student_id) {
                throw new Exception('Student ID is required');
            }
            
            $stmt = $conn->prepare("
                SELECT b.Badge_ID, b.Name, b.Description, b.Icon, b.Color, 
                       b.Hours_Required, b.Tier,
                       (SELECT COALESCE(SUM(Hours_Worked), 0) FROM Volunteer_Log WHERE Student_ID = ?) AS Current_Hours,
                       (b.Hours_Required - (SELECT COALESCE(SUM(Hours_Worked), 0) FROM Volunteer_Log WHERE Student_ID = ?)) AS Hours_Needed,
                       ROUND(((SELECT COALESCE(SUM(Hours_Worked), 0) FROM Volunteer_Log WHERE Student_ID = ?) / b.Hours_Required) * 100, 2) AS Progress_Percentage
                FROM Badge b
                WHERE b.Hours_Required > (SELECT COALESCE(SUM(Hours_Worked), 0) FROM Volunteer_Log WHERE Student_ID = ?)
                  AND b.Badge_ID NOT IN (SELECT Badge_ID FROM Volunteer_Badge WHERE Student_ID = ?)
                ORDER BY b.Hours_Required ASC
                LIMIT 5
            ");
            $stmt->bind_param("iiiii", $student_id, $student_id, $student_id, $student_id, $student_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'get_tier_summary':
            // Get summary of badges by tier for a student
            $student_id = $_GET['student_id'] ?? null;
            if (!$student_id) {
                throw new Exception('Student ID is required');
            }
            
            $stmt = $conn->prepare("
                SELECT b.Tier, COUNT(*) AS Badges_Earned
                FROM Volunteer_Badge vb
                JOIN Badge b ON vb.Badge_ID = b.Badge_ID
                WHERE vb.Student_ID = ?
                GROUP BY b.Tier
                ORDER BY FIELD(b.Tier, 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond')
            ");
            $stmt->bind_param("i", $student_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'create_badge':
            // Create a new badge (admin only)
            $data = json_decode(file_get_contents('php://input'), true);
            
            $stmt = $conn->prepare("
                INSERT INTO Badge (Badge_ID, Name, Description, Icon, Color, Hours_Required, Tier)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->bind_param("issssds", 
                $data['badge_id'],
                $data['name'],
                $data['description'],
                $data['icon'],
                $data['color'],
                $data['hours_required'],
                $data['tier']
            );
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'Badge created successfully']);
            break;

        case 'update_badge':
            // Update badge details (admin only)
            $data = json_decode(file_get_contents('php://input'), true);
            
            $stmt = $conn->prepare("
                UPDATE Badge 
                SET Name = ?, Description = ?, Icon = ?, Color = ?, Hours_Required = ?, Tier = ?
                WHERE Badge_ID = ?
            ");
            $stmt->bind_param("ssssdsi",
                $data['name'],
                $data['description'],
                $data['icon'],
                $data['color'],
                $data['hours_required'],
                $data['tier'],
                $data['badge_id']
            );
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'Badge updated successfully']);
            break;

        case 'delete_badge':
            // Delete a badge (admin only)
            $badge_id = $_POST['badge_id'] ?? null;
            if (!$badge_id) {
                throw new Exception('Badge ID is required');
            }
            
            $stmt = $conn->prepare("DELETE FROM Badge WHERE Badge_ID = ?");
            $stmt->bind_param("i", $badge_id);
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'Badge deleted successfully']);
            break;

        default:
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
