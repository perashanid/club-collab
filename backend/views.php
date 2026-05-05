<?php
header('Content-Type: application/json');
require 'db_connect.php';

// Which pre-built report/view to fetch
$view = $_GET['name'] ?? '';

// Whitelist permitted views to prevent SQL injection
$allowed_views = [
    'Available_Volunteers', 
    'Equipment_Dashboard', 
    'Club_Activity_Summary', 
    'Student_Volunteer_Profile',
    'Volunteer_Stats',
    'Volunteer_Leaderboard',
    'Badge_Statistics',
    'Upcoming_Events_Resources',
    'Equipment_Maintenance_History',
    'Cross_Club_Volunteers',
    'Booking_Conflicts_Report'
];

if (in_array($view, $allowed_views)) {
    // Query the pre-built view directly
    $sql = "SELECT * FROM `View_" . $view . "` LIMIT 100";
    $result = mysqli_query($conn, $sql);
    
    if ($result) {
        echo json_encode(mysqli_fetch_all($result, MYSQLI_ASSOC));
    } else {
        echo json_encode(["error" => "View not found or query failed: " . mysqli_error($conn)]);
    }
} else {
    echo json_encode(["error" => "Invalid view name specified."]);
}
?>