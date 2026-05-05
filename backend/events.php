<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this provides your MySQLi $conn variable

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        // Get all events or specific event
        if (isset($_GET['id'])) {
            $sql = "
                SELECT e.*, c.Name as HostClub
                FROM Event e
                LEFT JOIN Club c ON e.Primary_Club_ID = c.Club_ID
                WHERE e.Event_ID = ?
            ";
            $stmt = mysqli_prepare($conn, $sql);
            if ($stmt) {
                mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
                mysqli_stmt_execute($stmt);
                $result = mysqli_stmt_get_result($stmt);
                $event = mysqli_fetch_assoc($result);
                mysqli_stmt_close($stmt);

                if ($event) {
                    // Get collaborations
                    $collab_sql = "
                        SELECT c.Name as PartnerClub, col.Contribution_Type
                        FROM Collaboration col
                        JOIN Club c ON col.Partner_Club_ID = c.Club_ID
                        WHERE col.Event_ID = ?
                    ";
                    $stmt2 = mysqli_prepare($conn, $collab_sql);
                    if ($stmt2) {
                        mysqli_stmt_bind_param($stmt2, "i", $_GET['id']);
                        mysqli_stmt_execute($stmt2);
                        $collab_result = mysqli_stmt_get_result($stmt2);
                        $event['collaborations'] = mysqli_fetch_all($collab_result, MYSQLI_ASSOC);
                        mysqli_stmt_close($stmt2);
                    }
                }

                echo json_encode($event ?: ["error" => "Event not found"]);
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        } else {
            $sql = "
                SELECT e.*, c.Name as HostClub
                FROM Event e
                LEFT JOIN Club c ON e.Primary_Club_ID = c.Club_ID
                ORDER BY e.Event_ID DESC
            ";
            $result = mysqli_query($conn, $sql);
            if ($result) {
                echo json_encode(mysqli_fetch_all($result, MYSQLI_ASSOC));
            } else {
                echo json_encode(["error" => mysqli_error($conn)]);
            }
        }
        break;

    case 'POST':
        // Create new event using Transactions
        mysqli_begin_transaction($conn);
        try {
            $stmt = mysqli_prepare($conn, "INSERT INTO Event (Title, Date, Venue, Primary_Club_ID, Description) VALUES (?, ?, ?, ?, ?)");
            if (!$stmt) throw new Exception(mysqli_error($conn));
            
            // 'sssis' denotes: string, string, string, int, string
            mysqli_stmt_bind_param($stmt, "sssis", $input['title'], $input['date'], $input['venue'], $input['primary_club_id'], $input['description']);
            if (!mysqli_stmt_execute($stmt)) throw new Exception(mysqli_error($conn));
            
            $eventId = mysqli_insert_id($conn);
            mysqli_stmt_close($stmt);

            // Add collaborations
            if (isset($input['collaborations']) && is_array($input['collaborations'])) {
                $stmt2 = mysqli_prepare($conn, "INSERT INTO Collaboration (Event_ID, Partner_Club_ID, Contribution_Type) VALUES (?, ?, ?)");
                if (!$stmt2) throw new Exception(mysqli_error($conn));
                
                foreach ($input['collaborations'] as $collab) {
                    // 'iis' denotes: int, int, string
                    mysqli_stmt_bind_param($stmt2, "iis", $eventId, $collab['partner_club_id'], $collab['contribution_type']);
                    if (!mysqli_stmt_execute($stmt2)) throw new Exception(mysqli_error($conn));
                }
                mysqli_stmt_close($stmt2);
            }

            mysqli_commit($conn);
            echo json_encode(["success" => true, "id" => $eventId]);
        } catch(Exception $e) {
            mysqli_rollback($conn);
            echo json_encode(["error" => "Transaction failed: " . $e->getMessage()]);
        }
        break;

    case 'PUT':
        // Update event using Transactions
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Event ID required"]);
            break;
        }
        
        mysqli_begin_transaction($conn);
        try {
            $stmt = mysqli_prepare($conn, "UPDATE Event SET Title=?, Date=?, Venue=?, Primary_Club_ID=?, Description=? WHERE Event_ID=?");
            if (!$stmt) throw new Exception(mysqli_error($conn));
            
            // 'sssisi' denotes: string, string, string, int, string, int
            mysqli_stmt_bind_param($stmt, "sssisi", $input['title'], $input['date'], $input['venue'], $input['primary_club_id'], $input['description'], $_GET['id']);
            if (!mysqli_stmt_execute($stmt)) throw new Exception(mysqli_error($conn));
            mysqli_stmt_close($stmt);

            // Update collaborations (delete old ones first)
            $stmt2 = mysqli_prepare($conn, "DELETE FROM Collaboration WHERE Event_ID=?");
            if (!$stmt2) throw new Exception(mysqli_error($conn));
            
            mysqli_stmt_bind_param($stmt2, "i", $_GET['id']);
            if (!mysqli_stmt_execute($stmt2)) throw new Exception(mysqli_error($conn));
            mysqli_stmt_close($stmt2);

            // Insert new collaborations
            if (isset($input['collaborations']) && is_array($input['collaborations'])) {
                $stmt3 = mysqli_prepare($conn, "INSERT INTO Collaboration (Event_ID, Partner_Club_ID, Contribution_Type) VALUES (?, ?, ?)");
                if (!$stmt3) throw new Exception(mysqli_error($conn));
                
                foreach ($input['collaborations'] as $collab) {
                    mysqli_stmt_bind_param($stmt3, "iis", $_GET['id'], $collab['partner_club_id'], $collab['contribution_type']);
                    if (!mysqli_stmt_execute($stmt3)) throw new Exception(mysqli_error($conn));
                }
                mysqli_stmt_close($stmt3);
            }

            mysqli_commit($conn);
            echo json_encode(["success" => true]);
        } catch(Exception $e) {
            mysqli_rollback($conn);
            echo json_encode(["error" => "Transaction failed: " . $e->getMessage()]);
        }
        break;

    case 'DELETE':
        // Delete event using Transactions
        if (!isset($_GET['id'])) {
            echo json_encode(["error" => "Event ID required"]);
            break;
        }
        
        mysqli_begin_transaction($conn);
        try {
            // Must delete child collaborations first due to foreign key constraints (if CASCADE isn't set)
            $stmt = mysqli_prepare($conn, "DELETE FROM Collaboration WHERE Event_ID=?");
            if (!$stmt) throw new Exception(mysqli_error($conn));
            
            mysqli_stmt_bind_param($stmt, "i", $_GET['id']);
            if (!mysqli_stmt_execute($stmt)) throw new Exception(mysqli_error($conn));
            mysqli_stmt_close($stmt);

            // Then delete the parent event
            $stmt2 = mysqli_prepare($conn, "DELETE FROM Event WHERE Event_ID=?");
            if (!$stmt2) throw new Exception(mysqli_error($conn));
            
            mysqli_stmt_bind_param($stmt2, "i", $_GET['id']);
            if (!mysqli_stmt_execute($stmt2)) throw new Exception(mysqli_error($conn));
            mysqli_stmt_close($stmt2);

            mysqli_commit($conn);
            echo json_encode(["success" => true]);
        } catch(Exception $e) {
            mysqli_rollback($conn);
            echo json_encode(["error" => "Transaction failed: " . $e->getMessage()]);
        }
        break;
}
?>