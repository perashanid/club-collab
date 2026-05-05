<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once 'db_connect.php';

$action = $_GET['action'] ?? $_GET['report'] ?? '';

try {
    switch ($action) {
        case 'top_cross_club_volunteer':
        case 'cross_club_volunteer':
            $stmt = $conn->prepare("CALL Get_Top_Cross_Club_Volunteer()");
            $stmt->execute();
            $result = $stmt->get_result();
            echo json_encode(['success' => true, 'data' => $result->fetch_assoc()]);
            break;

        case 'equipment_utilization':
            $stmt = $conn->prepare("CALL Get_Equipment_Utilization()");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'club_collaboration':
            $stmt = $conn->prepare("CALL Get_Club_Collaboration_Network()");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'event_success':
            $stmt = $conn->prepare("CALL Get_Event_Success_Metrics()");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'student_engagement':
            $stmt = $conn->prepare("CALL Get_Student_Engagement_Ranking()");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'booking_patterns':
            $stmt = $conn->prepare("CALL Get_Booking_Pattern_Analysis()");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'available_volunteers':
            $stmt = $conn->prepare("SELECT * FROM Available_Volunteers");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'equipment_dashboard':
            $stmt = $conn->prepare("SELECT * FROM Equipment_Dashboard");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'club_activity':
            $stmt = $conn->prepare("SELECT * FROM Club_Activity_Summary");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'volunteer_profile':
            $student_id = $_GET['student_id'] ?? null;
            if ($student_id) {
                $stmt = $conn->prepare("SELECT * FROM Student_Volunteer_Profile WHERE Student_ID = ?");
                $stmt->bind_param("i", $student_id);
            } else {
                $stmt = $conn->prepare("SELECT * FROM Student_Volunteer_Profile");
            }
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'volunteer_stats':
            $student_id = $_GET['student_id'] ?? null;
            if ($student_id) {
                $stmt = $conn->prepare("SELECT * FROM Volunteer_Stats WHERE Student_ID = ?");
                $stmt->bind_param("i", $student_id);
            } else {
                $stmt = $conn->prepare("SELECT * FROM Volunteer_Stats");
            }
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'leaderboard':
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

        case 'badge_statistics':
            $stmt = $conn->prepare("SELECT * FROM Badge_Statistics");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'upcoming_events':
            $stmt = $conn->prepare("SELECT * FROM Upcoming_Events_Resources");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'maintenance_history':
            $equip_id = $_GET['equip_id'] ?? null;
            if ($equip_id) {
                $stmt = $conn->prepare("SELECT * FROM Equipment_Maintenance_History WHERE Equip_ID = ?");
                $stmt->bind_param("i", $equip_id);
            } else {
                $stmt = $conn->prepare("SELECT * FROM Equipment_Maintenance_History");
            }
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'cross_club_volunteers':
            $stmt = $conn->prepare("SELECT * FROM Cross_Club_Volunteers");
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data]);
            break;

        case 'booking_conflicts':
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
