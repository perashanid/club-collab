<?php
header('Content-Type: application/json');
require 'db_connect.php';

$sql = "
    SELECT rb.*, e.Name AS EquipName, ev.Title AS EventTitle
    FROM Resource_Booking rb
    LEFT JOIN Equipment e ON rb.Equip_ID = e.Equip_ID
    LEFT JOIN Event ev ON rb.Event_ID = ev.Event_ID
    ORDER BY rb.Borrow_Time DESC
";

$result = mysqli_query($conn, $sql);
if ($result) {
    $bookings = mysqli_fetch_all($result, MYSQLI_ASSOC);
    echo json_encode($bookings);
} else {
    echo json_encode(["error" => mysqli_error($conn)]);
}
?>