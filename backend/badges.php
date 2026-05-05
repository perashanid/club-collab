<?php
header('Content-Type: application/json');
require 'db_connect.php';

$action = $_GET['action'] ?? 'all';

try {
    if ($action === 'all') {
        // View all available badges
        $result = mysqli_query($conn, "SELECT * FROM Badge ORDER BY Hours_Required ASC");
        echo json_encode(mysqli_fetch_all($result, MYSQLI_ASSOC));
        
    } elseif ($action === 'student' && isset($_GET['student_id'])) {
        // View badges earned by a specific student
        $stmt = mysqli_prepare($conn, "
            SELECT b.*, vb.Earned_Date, vb.Total_Hours_At_Earning 
            FROM Volunteer_Badge vb 
            JOIN Badge b ON vb.Badge_ID = b.Badge_ID 
            WHERE vb.Student_ID = ? 
            ORDER BY b.Hours_Required DESC
        ");
        mysqli_stmt_bind_param($stmt, "i", $_GET['student_id']);
        mysqli_stmt_execute($stmt);
        echo json_encode(mysqli_fetch_all(mysqli_stmt_get_result($stmt), MYSQLI_ASSOC));
        
    } elseif ($action === 'leaderboard') {
        // View leaderboard ranking volunteers by total hours
        $sql = "SELECT Student_ID, SUM(Hours_Worked) as TotalHours FROM Volunteer_Log GROUP BY Student_ID ORDER BY TotalHours DESC LIMIT 10";
        $result = mysqli_query($conn, $sql);
        echo json_encode(mysqli_fetch_all($result, MYSQLI_ASSOC));
    }
} catch (Exception $e) {
    echo json_encode(["error" => $e->getMessage()]);
}
?>