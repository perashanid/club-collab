<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this provides your MySQLi $conn variable

$sql = "SELECT s.Student_ID, s.Name AS StudentName, s.Email, gs.Major, gs.Year_of_Study AS YearOfStudy,
        GROUP_CONCAT(DISTINCT CONCAT(c.Name, ' (', m.Role, ')') SEPARATOR ', ') AS ClubsAndRoles
        FROM Student s
        LEFT JOIN General_Student gs ON gs.Student_ID = s.Student_ID
        LEFT JOIN Membership m ON m.Student_ID = s.Student_ID
        LEFT JOIN Club c ON c.Club_ID = m.Club_ID
        GROUP BY s.Student_ID
        ORDER BY s.Student_ID DESC";

$result = mysqli_query($conn, $sql);

if ($result) {
    // Fetch all rows as an associative array
    $students = mysqli_fetch_all($result, MYSQLI_ASSOC);
    echo json_encode($students);
} else {
    // Return MySQLi error if the query fails
    echo json_encode(["error" => mysqli_error($conn)]);
}
?>