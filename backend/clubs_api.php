<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this uses your $conn MySQLi variable

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        // Get all clubs or specific club
        if (isset($_GET['id'])) {
            $stmt = mysqli_prepare($conn, "SELECT * FROM Club WHERE Club_ID = ?");
            if ($stmt) {
                mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
                mysqli_stmt_execute($stmt);
                $result = mysqli_stmt_get_result($stmt);
                $club = mysqli_fetch_assoc($result);
                
                echo json_encode($club ?: ["error" => "Club not found"]);
                mysqli_stmt_close($stmt);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        } else {
            $result = mysqli_query($conn, "SELECT * FROM Club ORDER BY Club_ID DESC");
            if ($result) {
                $clubs = mysqli_fetch_all($result, MYSQLI_ASSOC);
                echo json_encode($clubs);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        }
        break;

    case 'POST':
        // Create new club
        $stmt = mysqli_prepare($conn, "INSERT INTO Club (Name, Department, Office_Room, Founded_Date) VALUES (?, ?, ?, ?)");
        if ($stmt) {
            // 'ssss' denotes: string, string, string, string
            mysqli_stmt_bind_param($stmt, "ssss", $input['name'], $input['department'], $input['office'], $input['founded']);
            
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
        // Update club
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Club ID required"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "UPDATE Club SET Name=?, Department=?, Office_Room=?, Founded_Date=? WHERE Club_ID=?");
        if ($stmt) {
            // 'ssssi' denotes: string, string, string, string, integer
            mysqli_stmt_bind_param($stmt, "ssssi", $input['name'], $input['department'], $input['office'], $input['founded'], $_GET['id']);
            
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
        // Delete club
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Club ID required"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "DELETE FROM Club WHERE Club_ID=?");
        if ($stmt) {
            // 'i' denotes: integer
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