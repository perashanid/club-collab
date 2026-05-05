<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this provides your MySQLi $conn variable

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        // Get all volunteer logs or specific log
        if (isset($_GET['id'])) {
            $sql = "
                SELECT vl.*, s.Name as StudentName, e.Title as EventTitle, verifier.Name as VerifiedBy
                FROM Volunteer_Log vl
                LEFT JOIN Student s ON vl.Student_ID = s.Student_ID
                LEFT JOIN Event e ON vl.Event_ID = e.Event_ID
                LEFT JOIN Student verifier ON vl.Verified_By = verifier.Student_ID
                WHERE vl.Log_ID = ?
            ";
            $stmt = mysqli_prepare($conn, $sql);
            if ($stmt) {
                mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
                mysqli_stmt_execute($stmt);
                $result = mysqli_stmt_get_result($stmt);
                $log = mysqli_fetch_assoc($result);
                
                echo json_encode($log ?: ["error" => "Volunteer log not found"]);
                mysqli_stmt_close($stmt);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        } else {
            $sql = "
                SELECT vl.*, s.Name as StudentName, e.Title as EventTitle, verifier.Name as VerifiedBy
                FROM Volunteer_Log vl
                LEFT JOIN Student s ON vl.Student_ID = s.Student_ID
                LEFT JOIN Event e ON vl.Event_ID = e.Event_ID
                LEFT JOIN Student verifier ON vl.Verified_By = verifier.Student_ID
                ORDER BY vl.Log_ID DESC
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
        // Create new volunteer log
        $stmt = mysqli_prepare($conn, "INSERT INTO Volunteer_Log (Student_ID, Event_ID, Role, Hours_Worked, Verified_By, Verification_Date) VALUES (?, ?, ?, ?, ?, ?)");
        if ($stmt) {
            // 'iisiis' denotes: int, int, string, int, int, string
            mysqli_stmt_bind_param($stmt, "iisiis", $input['student_id'], $input['event_id'], $input['role'], $input['hours_worked'], $input['verified_by'], $input['verification_date']);
            
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
        // Update volunteer log
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Log ID required"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "UPDATE Volunteer_Log SET Student_ID=?, Event_ID=?, Role=?, Hours_Worked=?, Verified_By=?, Verification_Date=? WHERE Log_ID=?");
        if ($stmt) {
            // 'iisiisi' denotes: int, int, string, int, int, string, int
            mysqli_stmt_bind_param($stmt, "iisiisi", $input['student_id'], $input['event_id'], $input['role'], $input['hours_worked'], $input['verified_by'], $input['verification_date'], $_GET['id']);
            
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
        // Delete volunteer log
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Log ID required"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "DELETE FROM Volunteer_Log WHERE Log_ID=?");
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