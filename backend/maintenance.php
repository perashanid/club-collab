<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this provides your MySQLi $conn variable

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        // Get all maintenance logs or specific log
        if (isset($_GET['id'])) {
            $sql = "
                SELECT ml.*, e.Name as EquipName
                FROM Maintenance_Log ml
                LEFT JOIN Equipment e ON ml.Equip_ID = e.Equip_ID
                WHERE ml.Log_ID = ?
            ";
            $stmt = mysqli_prepare($conn, $sql);
            if ($stmt) {
                mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
                mysqli_stmt_execute($stmt);
                $result = mysqli_stmt_get_result($stmt);
                $log = mysqli_fetch_assoc($result);
                
                echo json_encode($log ?: ["error" => "Maintenance log not found"]);
                mysqli_stmt_close($stmt);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        } else {
            $sql = "
                SELECT ml.*, e.Name as EquipName
                FROM Maintenance_Log ml
                LEFT JOIN Equipment e ON ml.Equip_ID = e.Equip_ID
                ORDER BY ml.Log_ID DESC
            ";
            $result = mysqli_query($conn, $sql);
            if ($result) {
                $logs = mysqli_fetch_all($result, MYSQLI_ASSOC);
                echo json_encode($logs);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        }
        break;

    case 'POST':
        // Create new maintenance log
        $stmt = mysqli_prepare($conn, "INSERT INTO Maintenance_Log (Equip_ID, Date, Description, Cost) VALUES (?, ?, ?, ?)");
        if ($stmt) {
            // 'isss' denotes: int, string, string, string (using string for decimal/cost is generally safe)
            mysqli_stmt_bind_param($stmt, "isss", $input['equip_id'], $input['date'], $input['description'], $input['cost']);
            
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
        // Update maintenance log
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Log ID required"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "UPDATE Maintenance_Log SET Equip_ID=?, Date=?, Description=?, Cost=? WHERE Log_ID=?");
        if ($stmt) {
            // 'isssi' denotes: int, string, string, string, int
            mysqli_stmt_bind_param($stmt, "isssi", $input['equip_id'], $input['date'], $input['description'], $input['cost'], $_GET['id']);
            
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
        // Delete maintenance log
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Log ID required"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "DELETE FROM Maintenance_Log WHERE Log_ID=?");
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