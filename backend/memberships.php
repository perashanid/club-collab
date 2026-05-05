<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this provides your MySQLi $conn variable

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        // Get all memberships or specific membership
        if (isset($_GET['id'])) {
            $sql = "
                SELECT m.*, s.Name as StudentName, c.Name as ClubName
                FROM Membership m
                LEFT JOIN Student s ON m.Student_ID = s.Student_ID
                LEFT JOIN Club c ON m.Club_ID = c.Club_ID
                WHERE m.Member_ID = ?
            ";
            $stmt = mysqli_prepare($conn, $sql);
            if ($stmt) {
                mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
                mysqli_stmt_execute($stmt);
                $result = mysqli_stmt_get_result($stmt);
                $membership = mysqli_fetch_assoc($result);
                
                echo json_encode($membership ?: ["error" => "Membership not found"]);
                mysqli_stmt_close($stmt);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        } else {
            $sql = "
                SELECT m.*, s.Name as StudentName, c.Name as ClubName
                FROM Membership m
                LEFT JOIN Student s ON m.Student_ID = s.Student_ID
                LEFT JOIN Club c ON m.Club_ID = c.Club_ID
                ORDER BY m.Member_ID DESC
            ";
            $result = mysqli_query($conn, $sql);
            if ($result) {
                $memberships = mysqli_fetch_all($result, MYSQLI_ASSOC);
                echo json_encode($memberships);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        }
        break;

    case 'POST':
        // Create new membership
        $stmt = mysqli_prepare($conn, "INSERT INTO Membership (Student_ID, Club_ID, Role, Join_Date) VALUES (?, ?, ?, ?)");
        if ($stmt) {
            // 'iiss' denotes: int, int, string, string
            mysqli_stmt_bind_param($stmt, "iiss", $input['student_id'], $input['club_id'], $input['role'], $input['join_date']);
            
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
        // Update membership
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Membership ID required"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "UPDATE Membership SET Student_ID=?, Club_ID=?, Role=?, Join_Date=? WHERE Member_ID=?");
        if ($stmt) {
            // 'iissi' denotes: int, int, string, string, int
            mysqli_stmt_bind_param($stmt, "iissi", $input['student_id'], $input['club_id'], $input['role'], $input['join_date'], $_GET['id']);
            
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
        // Delete membership
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Membership ID required"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "DELETE FROM Membership WHERE Member_ID=?");
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