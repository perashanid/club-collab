<?php
header('Content-Type: application/json');
require 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'POST':
        try {
            $stmt = mysqli_prepare($conn, "INSERT INTO Volunteer_Log (Log_ID, Student_ID, Event_ID, Role, Hours_Worked, Verified_By, Verification_Date) VALUES (?, ?, ?, ?, ?, ?, ?)");
            
            // Generate next Log_ID
            $res = mysqli_query($conn, "SELECT COALESCE(MAX(Log_ID), 4000) + 1 AS NextID FROM Volunteer_Log");
            $row = mysqli_fetch_assoc($res);
            $logId = $row['NextID'];
            
            mysqli_stmt_bind_param($stmt, "iiisdis", $logId, $input['student_id'], $input['event_id'], $input['role'], $input['hours_worked'], $input['verified_by'], $input['verification_date']);
            
            if (!mysqli_stmt_execute($stmt)) throw new Exception(mysqli_error($conn));
            echo json_encode(["success" => true, "id" => $logId]);
        } catch (Exception $e) {
            echo json_encode(["error" => $e->getMessage()]);
        }
        break;

    case 'PUT':
        if (!isset($_GET['id'])) { echo json_encode(["error" => "ID required"]); break; }
        try {
            $stmt = mysqli_prepare($conn, "UPDATE Volunteer_Log SET Student_ID=?, Event_ID=?, Role=?, Hours_Worked=?, Verified_By=?, Verification_Date=? WHERE Log_ID=?");
            
            mysqli_stmt_bind_param($stmt, "iisdisi", $input['student_id'], $input['event_id'], $input['role'], $input['hours_worked'], $input['verified_by'], $input['verification_date'], $_GET['id']);
            
            if (!mysqli_stmt_execute($stmt)) throw new Exception(mysqli_error($conn));
            echo json_encode(["success" => true]);
        } catch (Exception $e) {
            echo json_encode(["error" => $e->getMessage()]);
        }
        break;

    case 'DELETE':
        if (!isset($_GET['id'])) { echo json_encode(["error" => "ID required"]); break; }
        try {
            $stmt = mysqli_prepare($conn, "DELETE FROM Volunteer_Log WHERE Log_ID=?");
            
            mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
            
            if (!mysqli_stmt_execute($stmt)) throw new Exception(mysqli_error($conn));
            echo json_encode(["success" => true]);
        } catch (Exception $e) {
            echo json_encode(["error" => $e->getMessage()]);
        }
        break;
        
    default:
        echo json_encode(["error" => "Invalid request method"]);
        break;
}
?>