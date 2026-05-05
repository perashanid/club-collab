<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this provides your MySQLi $conn variable

$sql = "SELECT c.Club_ID, c.Name AS ClubName, c.Department, c.Office_Room AS Office, c.Founded_Date AS Founded,
        COALESCE(COUNT(DISTINCT m.Member_ID), 0) AS MemberCount,
        GROUP_CONCAT(DISTINCT ce.Email SEPARATOR ', ') AS ContactEmails
        FROM Club c
        LEFT JOIN Membership m ON m.Club_ID = c.Club_ID
        LEFT JOIN Contact_Emails ce ON ce.Club_ID = c.Club_ID
        GROUP BY c.Club_ID
        ORDER BY c.Club_ID DESC";

$result = mysqli_query($conn, $sql);

if ($result) {
    // Fetch all rows as an associative array
    $clubs = mysqli_fetch_all($result, MYSQLI_ASSOC);
    echo json_encode($clubs);
} else {
    // Return MySQLi error if the query fails
    echo json_encode(["error" => mysqli_error($conn)]);
}
?>