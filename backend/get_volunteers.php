<?php
header('Content-Type: application/json');
require 'db_connect.php';

$sql = "
    SELECT vl.*, s.Name AS StudentName, e.Title AS EventTitle, ce.Name AS VerifiedByName
    FROM Volunteer_Log vl
    LEFT JOIN Student s ON vl.Student_ID = s.Student_ID
    LEFT JOIN Event e ON vl.Event_ID = e.Event_ID
    LEFT JOIN Student ce ON vl.Verified_By = ce.Student_ID
    ORDER BY vl.Log_ID DESC
";

$result = mysqli_query($conn, $sql);
if ($result) {
    echo json_encode(mysqli_fetch_all($result, MYSQLI_ASSOC));
} else {
    echo json_encode(["error" => mysqli_error($conn)]);
}
?>