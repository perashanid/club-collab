<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this provides your MySQLi $conn variable

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        // Get all equipment or specific equipment
        if (isset($_GET['id'])) {
            $sql = "
                SELECT e.*, c.Name as ClubName
                FROM Equipment e
                LEFT JOIN Club c ON e.Owner_Club_ID = c.Club_ID
                WHERE e.Equip_ID = ?
            ";
            $stmt = mysqli_prepare($conn, $sql);
            if ($stmt) {
                mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
                mysqli_stmt_execute($stmt);
                $result = mysqli_stmt_get_result($stmt);
                $equipment = mysqli_fetch_assoc($result);
                
                echo json_encode($equipment ?: ["error" => "Equipment not found"]);
                mysqli_stmt_close($stmt);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        } else {
            $sql = "
                SELECT e.*, c.Name as ClubName
                FROM Equipment e
                LEFT JOIN Club c ON e.Owner_Club_ID = c.Club_ID
                ORDER BY e.Equip_ID DESC
            ";
            $result = mysqli_query($conn, $sql);
            if ($result) {
                $equipments = mysqli_fetch_all($result, MYSQLI_ASSOC);
                echo json_encode($equipments);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        }
        break;

    case 'POST':
        // Create new equipment
        $stmt = mysqli_prepare($conn, "INSERT INTO Equipment (Name, Type, Status, Owner_Club_ID, Purchase_Date) VALUES (?, ?, ?, ?, ?)");
        if ($stmt) {
            // 'sssis' denotes: string, string, string, integer, string
            mysqli_stmt_bind_param($stmt, "sssis", $input['name'], $input['type'], $input['status'], $input['owner_club_id'], $input['purchase_date']);
            
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
        // Update equipment
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Equipment ID required"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "UPDATE Equipment SET Name=?, Type=?, Status=?, Owner_Club_ID=?, Purchase_Date=? WHERE Equip_ID=?");
        if ($stmt) {
            // 'sssisi' denotes: string, string, string, integer, string, integer
            mysqli_stmt_bind_param($stmt, "sssisi", $input['name'], $input['type'], $input['status'], $input['owner_club_id'], $input['purchase_date'], $_GET['id']);
            
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
        // Delete equipment
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Equipment ID required"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "DELETE FROM Equipment WHERE Equip_ID=?");
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