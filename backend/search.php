<?php
header('Content-Type: application/json');
require 'db_connect.php';

$type = $_GET['type'] ?? '';
$query = $_GET['q'] ?? '';
$filter = $_GET['filter'] ?? '';

try {
    if ($type === 'equipment') {
        // Filter equipment by name, status, or type
        $sql = "SELECT * FROM Equipment WHERE Name LIKE ? OR Type = ? OR Status = ?";
        $stmt = mysqli_prepare($conn, $sql);
        $search = "%{$query}%";
        mysqli_stmt_bind_param($stmt, "sss", $search, $filter, $filter);
        mysqli_stmt_execute($stmt);
        echo json_encode(mysqli_fetch_all(mysqli_stmt_get_result($stmt), MYSQLI_ASSOC));
        
    } elseif ($type === 'events') {
        // Filter events by partial title match
        $sql = "SELECT * FROM Event WHERE Title LIKE ?";
        $stmt = mysqli_prepare($conn, $sql);
        $search = "%{$query}%";
        mysqli_stmt_bind_param($stmt, "s", $search);
        mysqli_stmt_execute($stmt);
        echo json_encode(mysqli_fetch_all(mysqli_stmt_get_result($stmt), MYSQLI_ASSOC));
    }
} catch(Exception $e) { echo json_encode(["error" => $e->getMessage()]); }
?>