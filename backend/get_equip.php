<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this provides your MySQLi $conn variable

// Join Equipment with Club to get the Owner Club Name
$sql = "
    SELECT e.Equip_ID, e.Name as EquipName, e.Type, e.Status, e.Owner_Club_ID, e.Purchase_Date, c.Name as ClubName 
    FROM Equipment e 
    LEFT JOIN Club c ON e.Owner_Club_ID = c.Club_ID
    ORDER BY e.Equip_ID DESC
";

$result = mysqli_query($conn, $sql);

if ($result) {
    // Fetch all rows as an associative array
    $equipment = mysqli_fetch_all($result, MYSQLI_ASSOC);
    echo json_encode($equipment);
} else {
    // Return MySQLi error if the query fails
    echo json_encode(["error" => mysqli_error($conn)]);
}
?>