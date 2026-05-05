<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

require_once 'db_connect.php';

$action = $_GET['action'] ?? '';

try {
    switch ($action) {
        case 'search_equipment':
            // Search equipment with filters
            $search = $_GET['search'] ?? '';
            $status = $_GET['status'] ?? '';
            $type = $_GET['type'] ?? '';
            $owner_club = $_GET['owner_club'] ?? '';
            $page = $_GET['page'] ?? 1;
            $limit = $_GET['limit'] ?? 10;
            $offset = ($page - 1) * $limit;
            
            $query = "
                SELECT e.*, c.Name AS Owner_Club_Name,
                       COUNT(DISTINCT rb.Booking_ID) AS Total_Bookings,
                       COALESCE(SUM(ml.Cost), 0) AS Total_Maintenance_Cost
                FROM Equipment e
                JOIN Club c ON e.Owner_Club_ID = c.Club_ID
                LEFT JOIN Resource_Booking rb ON e.Equip_ID = rb.Equip_ID
                LEFT JOIN Maintenance_Log ml ON e.Equip_ID = ml.Equip_ID
                WHERE 1=1
            ";
            
            $params = [];
            $types = "";
            
            if ($search) {
                $query .= " AND (e.Name LIKE ? OR e.Type LIKE ?)";
                $search_param = "%$search%";
                $params[] = $search_param;
                $params[] = $search_param;
                $types .= "ss";
            }
            if ($status) {
                $query .= " AND e.Status = ?";
                $params[] = $status;
                $types .= "s";
            }
            if ($type) {
                $query .= " AND e.Type = ?";
                $params[] = $type;
                $types .= "s";
            }
            if ($owner_club) {
                $query .= " AND c.Name LIKE ?";
                $owner_param = "%$owner_club%";
                $params[] = $owner_param;
                $types .= "s";
            }
            
            $query .= " GROUP BY e.Equip_ID, e.Name, e.Type, e.Status, e.Owner_Club_ID, e.Purchase_Date, c.Name";
            $query .= " ORDER BY e.Name LIMIT ? OFFSET ?";
            
            $params[] = $limit;
            $params[] = $offset;
            $types .= "ii";
            
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
            echo json_encode(['success' => true, 'data' => $data, 'page' => $page, 'limit' => $limit]);
            break;

        case 'search_volunteers':
            // Search volunteer logs with filters
            $search = $_GET['search'] ?? '';
            $student_id = $_GET['student_id'] ?? '';
            $event_id = $_GET['event_id'] ?? '';
            $role = $_GET['role'] ?? '';
            $date_from = $_GET['date_from'] ?? '';
            $date_to = $_GET['date_to'] ?? '';
            $verified = $_GET['verified'] ?? '';
            $page = $_GET['page'] ?? 1;
            $limit = $_GET['limit'] ?? 10;
            $offset = ($page - 1) * $limit;
            
            $query = "
                SELECT vl.*, s.Name AS Student_Name, s.Email AS Student_Email,
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
            
            if ($search) {
                $query .= " AND (s.Name LIKE ? OR ev.Title LIKE ? OR vl.Role LIKE ?)";
                $search_param = "%$search%";
                $params[] = $search_param;
                $params[] = $search_param;
                $params[] = $search_param;
                $types .= "sss";
            }
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
            if ($role) {
                $query .= " AND vl.Role LIKE ?";
                $role_param = "%$role%";
                $params[] = $role_param;
                $types .= "s";
            }
            if ($date_from) {
                $query .= " AND ev.Date >= ?";
                $params[] = $date_from;
                $types .= "s";
            }
            if ($date_to) {
                $query .= " AND ev.Date <= ?";
                $params[] = $date_to;
                $types .= "s";
            }
            if ($verified !== '') {
                if ($verified == 'true' || $verified == '1') {
                    $query .= " AND vl.Verified_By IS NOT NULL";
                } else {
                    $query .= " AND vl.Verified_By IS NULL";
                }
            }
            
            $query .= " ORDER BY ev.Date DESC LIMIT ? OFFSET ?";
            
            $params[] = $limit;
            $params[] = $offset;
            $types .= "ii";
            
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
            echo json_encode(['success' => true, 'data' => $data, 'page' => $page, 'limit' => $limit]);
            break;

        case 'search_events':
            // Search events with filters
            $search = $_GET['search'] ?? '';
            $club_id = $_GET['club_id'] ?? '';
            $date_from = $_GET['date_from'] ?? '';
            $date_to = $_GET['date_to'] ?? '';
            $has_partners = $_GET['has_partners'] ?? '';
            $page = $_GET['page'] ?? 1;
            $limit = $_GET['limit'] ?? 10;
            $offset = ($page - 1) * $limit;
            
            $query = "
                SELECT e.*, c.Name AS Primary_Club_Name,
                       COUNT(DISTINCT col.Partner_Club_ID) AS Partner_Count,
                       COUNT(DISTINCT rb.Equip_ID) AS Equipment_Count,
                       COUNT(DISTINCT vl.Student_ID) AS Volunteer_Count
                FROM Event e
                JOIN Club c ON e.Primary_Club_ID = c.Club_ID
                LEFT JOIN Collaboration col ON e.Event_ID = col.Event_ID
                LEFT JOIN Resource_Booking rb ON e.Event_ID = rb.Event_ID
                LEFT JOIN Volunteer_Log vl ON e.Event_ID = vl.Event_ID
                WHERE 1=1
            ";
            
            $params = [];
            $types = "";
            
            if ($search) {
                $query .= " AND (e.Title LIKE ? OR e.Venue LIKE ? OR e.Description LIKE ?)";
                $search_param = "%$search%";
                $params[] = $search_param;
                $params[] = $search_param;
                $params[] = $search_param;
                $types .= "sss";
            }
            if ($club_id) {
                $query .= " AND (e.Primary_Club_ID = ? OR col.Partner_Club_ID = ?)";
                $params[] = $club_id;
                $params[] = $club_id;
                $types .= "ii";
            }
            if ($date_from) {
                $query .= " AND e.Date >= ?";
                $params[] = $date_from;
                $types .= "s";
            }
            if ($date_to) {
                $query .= " AND e.Date <= ?";
                $params[] = $date_to;
                $types .= "s";
            }
            
            $query .= " GROUP BY e.Event_ID, e.Title, e.Date, e.Venue, e.Primary_Club_ID, e.Description, c.Name";
            
            if ($has_partners !== '') {
                if ($has_partners == 'true' || $has_partners == '1') {
                    $query .= " HAVING Partner_Count > 0";
                } else {
                    $query .= " HAVING Partner_Count = 0";
                }
            }
            
            $query .= " ORDER BY e.Date DESC LIMIT ? OFFSET ?";
            
            $params[] = $limit;
            $params[] = $offset;
            $types .= "ii";
            
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
            echo json_encode(['success' => true, 'data' => $data, 'page' => $page, 'limit' => $limit]);
            break;

        case 'search_students':
            // Search students
            $search = $_GET['search'] ?? '';
            $club_id = $_GET['club_id'] ?? '';
            $is_executive = $_GET['is_executive'] ?? '';
            $page = $_GET['page'] ?? 1;
            $limit = $_GET['limit'] ?? 10;
            $offset = ($page - 1) * $limit;
            
            $query = "
                SELECT DISTINCT s.*, 
                       COUNT(DISTINCT m.Club_ID) AS Clubs_Count,
                       COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Hours
                FROM Student s
                LEFT JOIN Membership m ON s.Student_ID = m.Student_ID
                LEFT JOIN Volunteer_Log vl ON s.Student_ID = vl.Student_ID
                LEFT JOIN Club_Executive ce ON s.Student_ID = ce.Student_ID
                WHERE 1=1
            ";
            
            $params = [];
            $types = "";
            
            if ($search) {
                $query .= " AND (s.Name LIKE ? OR s.Email LIKE ?)";
                $search_param = "%$search%";
                $params[] = $search_param;
                $params[] = $search_param;
                $types .= "ss";
            }
            if ($club_id) {
                $query .= " AND m.Club_ID = ?";
                $params[] = $club_id;
                $types .= "i";
            }
            if ($is_executive !== '') {
                if ($is_executive == 'true' || $is_executive == '1') {
                    $query .= " AND ce.Student_ID IS NOT NULL";
                } else {
                    $query .= " AND ce.Student_ID IS NULL";
                }
            }
            
            $query .= " GROUP BY s.Student_ID, s.Name, s.Email, s.Password, s.Street, s.City, s.Zip, s.Contact_No";
            $query .= " ORDER BY s.Name LIMIT ? OFFSET ?";
            
            $params[] = $limit;
            $params[] = $offset;
            $types .= "ii";
            
            $stmt = $conn->prepare($query);
            if (!empty($params)) {
                $stmt->bind_param($types, ...$params);
            }
            $stmt->execute();
            $result = $stmt->get_result();
            $data = [];
            while ($row = $result->fetch_assoc()) {
                unset($row['Password']); // Don't send passwords
                $data[] = $row;
            }
            echo json_encode(['success' => true, 'data' => $data, 'page' => $page, 'limit' => $limit]);
            break;

        case 'search_badges':
            // Search badges
            $search = $_GET['search'] ?? '';
            $tier = $_GET['tier'] ?? '';
            $earned_by = $_GET['earned_by'] ?? '';
            
            $query = "
                SELECT b.*, 
                       COUNT(DISTINCT vb.Student_ID) AS Students_Earned
                FROM Badge b
                LEFT JOIN Volunteer_Badge vb ON b.Badge_ID = vb.Badge_ID
                WHERE 1=1
            ";
            
            $params = [];
            $types = "";
            
            if ($search) {
                $query .= " AND (b.Name LIKE ? OR b.Description LIKE ?)";
                $search_param = "%$search%";
                $params[] = $search_param;
                $params[] = $search_param;
                $types .= "ss";
            }
            if ($tier) {
                $query .= " AND b.Tier = ?";
                $params[] = $tier;
                $types .= "s";
            }
            if ($earned_by) {
                $query .= " AND vb.Student_ID = ?";
                $params[] = $earned_by;
                $types .= "i";
            }
            
            $query .= " GROUP BY b.Badge_ID, b.Name, b.Description, b.Icon, b.Color, b.Hours_Required, b.Tier";
            $query .= " ORDER BY FIELD(b.Tier, 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'), b.Hours_Required";
            
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

        case 'search_bookings':
            // Search bookings
            $search = $_GET['search'] ?? '';
            $status = $_GET['status'] ?? '';
            $date_from = $_GET['date_from'] ?? '';
            $date_to = $_GET['date_to'] ?? '';
            $page = $_GET['page'] ?? 1;
            $limit = $_GET['limit'] ?? 10;
            $offset = ($page - 1) * $limit;
            
            $query = "
                SELECT rb.*, e.Name AS Equipment_Name, e.Type AS Equipment_Type,
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
            
            if ($search) {
                $query .= " AND (e.Name LIKE ? OR ev.Title LIKE ?)";
                $search_param = "%$search%";
                $params[] = $search_param;
                $params[] = $search_param;
                $types .= "ss";
            }
            if ($status) {
                $query .= " AND rb.Status = ?";
                $params[] = $status;
                $types .= "s";
            }
            if ($date_from) {
                $query .= " AND rb.Borrow_Time >= ?";
                $params[] = $date_from;
                $types .= "s";
            }
            if ($date_to) {
                $query .= " AND rb.Return_Time <= ?";
                $params[] = $date_to;
                $types .= "s";
            }
            
            $query .= " ORDER BY rb.Borrow_Time DESC LIMIT ? OFFSET ?";
            
            $params[] = $limit;
            $params[] = $offset;
            $types .= "ii";
            
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
            echo json_encode(['success' => true, 'data' => $data, 'page' => $page, 'limit' => $limit]);
            break;

        default:
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
