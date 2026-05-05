<?php
header('Content-Type: application/json');
require 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'POST':
        try {
            $stmt = mysqli_prepare($conn, "INSERT INTO Resource_Booking (Booking_ID, Equip_ID, Event_ID, Borrow_Time, Return_Time, Status) VALUES (?, ?, ?, ?, ?, ?)");
            
            // Generate an ID for Booking_ID 
            $res = mysqli_query($conn, "SELECT COALESCE(MAX(Booking_ID), 3000) + 1 AS NextID FROM Resource_Booking");
            $row = mysqli_fetch_assoc($res);
            $bookingId = $row['NextID'];
            
            $status = isset($input['status']) ? $input['status'] : 'Confirmed';
            mysqli_stmt_bind_param($stmt, "iiisss", $bookingId, $input['equip_id'], $input['event_id'], $input['borrow_time'], $input['return_time'], $status);
            
            if (!mysqli_stmt_execute($stmt)) {
                throw new Exception(mysqli_error($conn));
            }
            echo json_encode(["success" => true, "id" => $bookingId]);
        } catch (Exception $e) {
            echo json_encode(["error" => $e->getMessage()]);
        }
        break;

    case 'PUT':
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Booking ID required"]);
            break;
        }
        try {
            $stmt = mysqli_prepare($conn, "UPDATE Resource_Booking SET Equip_ID=?, Event_ID=?, Borrow_Time=?, Return_Time=?, Status=? WHERE Booking_ID=?");
            mysqli_stmt_bind_param($stmt, "iisssi", $input['equip_id'], $input['event_id'], $input['borrow_time'], $input['return_time'], $input['status'], $_GET['id']);
            
            if (!mysqli_stmt_execute($stmt)) {
                throw new Exception(mysqli_error($conn));
            }
            echo json_encode(["success" => true]);
        } catch (Exception $e) {
            echo json_encode(["error" => $e->getMessage()]);
        }
        break;

    case 'DELETE':
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Booking ID required"]);
            break;
        }
        try {
            $stmt = mysqli_prepare($conn, "DELETE FROM Resource_Booking WHERE Booking_ID=?");
            mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
            
            if (!mysqli_stmt_execute($stmt)) {
                throw new Exception(mysqli_error($conn));
            }
            echo json_encode(["success" => true]);
        } catch (Exception $e) {
            echo json_encode(["error" => $e->getMessage()]);
        }
        break;
}
?>