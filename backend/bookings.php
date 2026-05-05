<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this provides your MySQLi $conn variable

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        // Get all bookings or specific booking
        if (isset($_GET['id'])) {
            $sql = "
                SELECT rb.*, e.Name as EquipName, ev.Title as EventTitle, c.Name as ClubName
                FROM Resource_Booking rb
                LEFT JOIN Equipment e ON rb.Equip_ID = e.Equip_ID
                LEFT JOIN Event ev ON rb.Event_ID = ev.Event_ID
                LEFT JOIN Club c ON ev.Primary_Club_ID = c.Club_ID
                WHERE rb.Booking_ID = ?
            ";
            $stmt = mysqli_prepare($conn, $sql);
            if ($stmt) {
                mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
                mysqli_stmt_execute($stmt);
                $result = mysqli_stmt_get_result($stmt);
                $booking = mysqli_fetch_assoc($result);
                
                echo json_encode($booking ?: ["error" => "Booking not found"]);
                mysqli_stmt_close($stmt);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        } else {
            $sql = "
                SELECT rb.*, e.Name as EquipName, ev.Title as EventTitle, c.Name as ClubName
                FROM Resource_Booking rb
                LEFT JOIN Equipment e ON rb.Equip_ID = e.Equip_ID
                LEFT JOIN Event ev ON rb.Event_ID = ev.Event_ID
                LEFT JOIN Club c ON ev.Primary_Club_ID = c.Club_ID
                ORDER BY rb.Booking_ID DESC
            ";
            $result = mysqli_query($conn, $sql);
            if ($result) {
                $bookings = mysqli_fetch_all($result, MYSQLI_ASSOC);
                echo json_encode($bookings);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        }
        break;

    case 'POST':
        // Create new booking
        $stmt = mysqli_prepare($conn, "INSERT INTO Resource_Booking (Equip_ID, Event_ID, Borrow_Time, Return_Time, Status) VALUES (?, ?, ?, ?, ?)");
        if ($stmt) {
            // 'iisss' denotes: int, int, string, string, string
            mysqli_stmt_bind_param($stmt, "iisss", $input['equip_id'], $input['event_id'], $input['borrow_time'], $input['return_time'], $input['status']);
            
            if (mysqli_stmt_execute($stmt)) {
                echo json_encode(["success" => true, "id" => mysqli_insert_id($conn)]);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
            mysqli_stmt_close($stmt);
        } else {
            echo json_encode(["error" => mysqli_error($conn)]);
        }
        break;

    case 'PUT':
        // Update booking
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Booking ID required"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "UPDATE Resource_Booking SET Equip_ID=?, Event_ID=?, Borrow_Time=?, Return_Time=?, Status=? WHERE Booking_ID=?");
        if ($stmt) {
            // 'iisssi' denotes: int, int, string, string, string, int
            mysqli_stmt_bind_param($stmt, "iisssi", $input['equip_id'], $input['event_id'], $input['borrow_time'], $input['return_time'], $input['status'], $_GET['id']);
            
            if (mysqli_stmt_execute($stmt)) {
                echo json_encode(["success" => true]);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
            mysqli_stmt_close($stmt);
        } else {
            echo json_encode(["error" => mysqli_error($conn)]);
        }
        break;

    case 'DELETE':
        // Delete booking
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Booking ID required"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "DELETE FROM Resource_Booking WHERE Booking_ID=?");
        if ($stmt) {
            // 'i' denotes: int
            mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
            
            if (mysqli_stmt_execute($stmt)) {
                echo json_encode(["success" => true]);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
            mysqli_stmt_close($stmt);
        } else {
            echo json_encode(["error" => mysqli_error($conn)]);
        }
        break;
}
?>