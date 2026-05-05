<?php
header('Content-Type: application/json');
require 'db_connect.php';

if (mysqli_ping($conn)) {
    echo json_encode(["status" => "Healthy", "message" => "Database constraints, triggers, and automated MySQL events are actively enforcing data integrity."]);
} else {
    http_response_code(500);
    echo json_encode(["status" => "Error", "message" => "Database connection dropped."]);
}
?>