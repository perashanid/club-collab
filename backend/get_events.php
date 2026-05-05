<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this provides your MySQLi $conn variable

$sql = "SELECT e.Event_ID, e.Title, e.Date, e.Venue, c.Name AS HostClub, e.Description,
        COALESCE(COUNT(DISTINCT col.Partner_Club_ID), 0) AS PartnerCount,
        COALESCE(COUNT(DISTINCT rb.Booking_ID), 0) AS BookingCount
        FROM Event e
        LEFT JOIN Club c ON c.Club_ID = e.Primary_Club_ID
        LEFT JOIN Collaboration col ON col.Event_ID = e.Event_ID
        LEFT JOIN Resource_Booking rb ON rb.Event_ID = e.Event_ID
        GROUP BY e.Event_ID
        ORDER BY e.Event_ID DESC";

$result = mysqli_query($conn, $sql);

if ($result) {
    // Fetch all rows as an associative array
    $events = mysqli_fetch_all($result, MYSQLI_ASSOC);
    echo json_encode($events);
} else {
    // Return MySQLi error if the query fails
    echo json_encode(["error" => mysqli_error($conn)]);
}
?>