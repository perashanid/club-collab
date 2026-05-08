<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this provides your MySQLi $conn variable

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        // Get all students or specific student
        if (isset($_GET['id'])) {
            $sql = "
                SELECT s.*, gs.Major, gs.Year_of_Study, ce.Position, ce.Term_Start, ce.Term_End
                FROM Student s
                LEFT JOIN General_Student gs ON gs.Student_ID = s.Student_ID
                LEFT JOIN Club_Executive ce ON ce.Student_ID = s.Student_ID
                WHERE s.Student_ID = ?
            ";
            $stmt = mysqli_prepare($conn, $sql);
            if ($stmt) {
                mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
                mysqli_stmt_execute($stmt);
                $result = mysqli_stmt_get_result($stmt);
                $student = mysqli_fetch_assoc($result);
                
                echo json_encode($student ?: ["error" => "Student not found"]);
                mysqli_stmt_close($stmt);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        } else {
            $sql = "
                SELECT s.*, gs.Major, gs.Year_of_Study, ce.Position, ce.Term_Start, ce.Term_End
                FROM Student s
                LEFT JOIN General_Student gs ON gs.Student_ID = s.Student_ID
                LEFT JOIN Club_Executive ce ON ce.Student_ID = s.Student_ID
                ORDER BY s.Student_ID DESC
            ";
            $result = mysqli_query($conn, $sql);
            if ($result) {
                $students = mysqli_fetch_all($result, MYSQLI_ASSOC);
                echo json_encode($students);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        }
        break;

    case 'POST':
        // Create new student using Transactions
        mysqli_begin_transaction($conn);
        try {
            $stmt = mysqli_prepare($conn, "INSERT INTO Student (Name, Email, Password, Street, City, Zip, Contact_No) VALUES (?, ?, ?, ?, ?, ?, ?)");
            if (!$stmt) throw new Exception(mysqli_error($conn));
            
            // 'sssssss' denotes: 7 strings
            mysqli_stmt_bind_param($stmt, "sssssss", $input['name'], $input['email'], $input['password'], $input['street'], $input['city'], $input['zip'], $input['contact_no']);
            if (!mysqli_stmt_execute($stmt)) throw new Exception(mysqli_error($conn));
            
            $studentId = mysqli_insert_id($conn);
            mysqli_stmt_close($stmt);

            // Add phone numbers
            if (isset($input['phones']) && is_array($input['phones'])) {
                $stmt2 = mysqli_prepare($conn, "INSERT INTO Phone_Numbers (Student_ID, Phone_Number) VALUES (?, ?)");
                if (!$stmt2) throw new Exception(mysqli_error($conn));
                
                foreach ($input['phones'] as $phone) {
                    // 'is' denotes: int, string
                    mysqli_stmt_bind_param($stmt2, "is", $studentId, $phone);
                    if (!mysqli_stmt_execute($stmt2)) throw new Exception(mysqli_error($conn));
                }
                mysqli_stmt_close($stmt2);
            }

            // Add to appropriate student type
            if ($input['student_type'] === 'general') {
                $stmt3 = mysqli_prepare($conn, "INSERT INTO General_Student (Student_ID, Year_of_Study, Major) VALUES (?, ?, ?)");
                if (!$stmt3) throw new Exception(mysqli_error($conn));
                
                // 'iis' denotes: int, int, string
                mysqli_stmt_bind_param($stmt3, "iis", $studentId, $input['year_of_study'], $input['major']);
                if (!mysqli_stmt_execute($stmt3)) throw new Exception(mysqli_error($conn));
                mysqli_stmt_close($stmt3);
                
            } elseif ($input['student_type'] === 'executive') {
                $stmt4 = mysqli_prepare($conn, "INSERT INTO Club_Executive (Student_ID, Position, Term_Start, Term_End) VALUES (?, ?, ?, ?)");
                if (!$stmt4) throw new Exception(mysqli_error($conn));
                
                // 'isss' denotes: int, string, string, string
                mysqli_stmt_bind_param($stmt4, "isss", $studentId, $input['position'], $input['term_start'], $input['term_end']);
                if (!mysqli_stmt_execute($stmt4)) throw new Exception(mysqli_error($conn));
                mysqli_stmt_close($stmt4);
            }
            
            // Add club membership if club_id is provided
            if (isset($input['club_id']) && !empty($input['club_id'])) {
                $stmt5 = mysqli_prepare($conn, "INSERT INTO Membership (Student_ID, Club_ID, Role, Join_Date) VALUES (?, ?, 'Volunteer', CURDATE())");
                if (!$stmt5) throw new Exception(mysqli_error($conn));
                
                mysqli_stmt_bind_param($stmt5, "ii", $studentId, $input['club_id']);
                if (!mysqli_stmt_execute($stmt5)) throw new Exception(mysqli_error($conn));
                mysqli_stmt_close($stmt5);
            }

            mysqli_commit($conn);
            echo json_encode(["success" => true, "id" => $studentId]);
        } catch(Exception $e) {
            mysqli_rollback($conn);
            echo json_encode(["error" => "Transaction failed: " . $e->getMessage()]);
        }
        break;

    case 'PUT':
        // Update student using Transactions
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Student ID required"]);
            break;
        }
        
        mysqli_begin_transaction($conn);
        try {
            $stmt = mysqli_prepare($conn, "UPDATE Student SET Name=?, Email=?, Password=?, Street=?, City=?, Zip=?, Contact_No=? WHERE Student_ID=?");
            if (!$stmt) throw new Exception(mysqli_error($conn));
            
            // 'sssssssi' denotes: 7 strings, 1 int
            mysqli_stmt_bind_param($stmt, "sssssssi", $input['name'], $input['email'], $input['password'], $input['street'], $input['city'], $input['zip'], $input['contact_no'], $_GET['id']);
            if (!mysqli_stmt_execute($stmt)) throw new Exception(mysqli_error($conn));
            mysqli_stmt_close($stmt);

            // Update phone numbers (delete and re-insert)
            $stmt2 = mysqli_prepare($conn, "DELETE FROM Phone_Numbers WHERE Student_ID=?");
            if (!$stmt2) throw new Exception(mysqli_error($conn));
            
            mysqli_stmt_bind_param($stmt2, "i", $_GET['id']);
            if (!mysqli_stmt_execute($stmt2)) throw new Exception(mysqli_error($conn));
            mysqli_stmt_close($stmt2);

            if (isset($input['phones']) && is_array($input['phones'])) {
                $stmt3 = mysqli_prepare($conn, "INSERT INTO Phone_Numbers (Student_ID, Phone_Number) VALUES (?, ?)");
                if (!$stmt3) throw new Exception(mysqli_error($conn));
                
                foreach ($input['phones'] as $phone) {
                    mysqli_stmt_bind_param($stmt3, "is", $_GET['id'], $phone);
                    if (!mysqli_stmt_execute($stmt3)) throw new Exception(mysqli_error($conn));
                }
                mysqli_stmt_close($stmt3);
            }

            // Update student type specific data
            if ($input['student_type'] === 'general') {
                $stmt4 = mysqli_prepare($conn, "UPDATE General_Student SET Year_of_Study=?, Major=? WHERE Student_ID=?");
                if (!$stmt4) throw new Exception(mysqli_error($conn));
                
                // 'isi' denotes: int, string, int
                mysqli_stmt_bind_param($stmt4, "isi", $input['year_of_study'], $input['major'], $_GET['id']);
                if (!mysqli_stmt_execute($stmt4)) throw new Exception(mysqli_error($conn));
                mysqli_stmt_close($stmt4);
                
            } elseif ($input['student_type'] === 'executive') {
                $stmt5 = mysqli_prepare($conn, "UPDATE Club_Executive SET Position=?, Term_Start=?, Term_End=? WHERE Student_ID=?");
                if (!$stmt5) throw new Exception(mysqli_error($conn));
                
                // 'sssi' denotes: string, string, string, int
                mysqli_stmt_bind_param($stmt5, "sssi", $input['position'], $input['term_start'], $input['term_end'], $_GET['id']);
                if (!mysqli_stmt_execute($stmt5)) throw new Exception(mysqli_error($conn));
                mysqli_stmt_close($stmt5);
            }

            mysqli_commit($conn);
            echo json_encode(["success" => true]);
        } catch(Exception $e) {
            mysqli_rollback($conn);
            echo json_encode(["error" => "Transaction failed: " . $e->getMessage()]);
        }
        break;

    case 'DELETE':
        // Delete student using Transactions
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Student ID required"]);
            break;
        }
        
        mysqli_begin_transaction($conn);
        try {
            // Must delete child records first to satisfy foreign key constraints (if CASCADE isn't used)
            $tablesToDeleteFrom = ['Phone_Numbers', 'General_Student', 'Club_Executive', 'Student'];
            
            foreach ($tablesToDeleteFrom as $tableName) {
                // Ensure table name is safe to use in query (prevent SQL injection)
                $stmt = mysqli_prepare($conn, "DELETE FROM `$tableName` WHERE Student_ID=?");
                if (!$stmt) throw new Exception(mysqli_error($conn));
                
                mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
                if (!mysqli_stmt_execute($stmt)) throw new Exception(mysqli_error($conn));
                mysqli_stmt_close($stmt);
            }

            mysqli_commit($conn);
            echo json_encode(["success" => true]);
        } catch(Exception $e) {
            mysqli_rollback($conn);
            echo json_encode(["error" => "Transaction failed: " . $e->getMessage()]);
        }
        break;
}
?>