<?php
header('Content-Type: application/json');
require 'db_connect.php'; // Ensure this provides a MySQLi connection variable, e.g., $conn

$input = json_decode(file_get_contents('php://input'), true);

if (!$input || !isset($input['email']) || !isset($input['password'])) {
    echo json_encode(["success" => false, "message" => "Email and password required"]);
    exit;
}

$email = $input['email'];
$password = $input['password'];

// Prepare the SQL statement
$sql = "SELECT s.*, ce.Position FROM Student s LEFT JOIN Club_Executive ce ON s.Student_ID = ce.Student_ID WHERE s.Email = ?";
$stmt = mysqli_prepare($conn, $sql);

if (!$stmt) {
    // MySQLi procedural error handling for preparation failure
    echo json_encode(["success" => false, "message" => "Database error: " . mysqli_error($conn)]);
    exit;
}

// Bind the email parameter ("s" means string) and execute
mysqli_stmt_bind_param($stmt, "s", $email);

if (!mysqli_stmt_execute($stmt)) {
    // MySQLi procedural error handling for execution failure
    echo json_encode(["success" => false, "message" => "Database error: " . mysqli_error($conn)]);
    mysqli_stmt_close($stmt);
    exit;
}

// Fetch the result
$result = mysqli_stmt_get_result($stmt);
$user = mysqli_fetch_assoc($result);

// Close the statement
mysqli_stmt_close($stmt);

if (!$user) {
    echo json_encode(["success" => false, "message" => "Invalid email or password"]);
    exit;
}

// For demo purposes, we'll use simple password comparison
// In production, use password_verify() with hashed passwords
if ($password !== $user['Password']) {
    echo json_encode(["success" => false, "message" => "Invalid email or password"]);
    exit;
}

// Determine user role
$role = 'student';
if (!empty($user['Position'])) {
    $role = 'admin'; // Executives have admin access
}

// Get user's primary club (first club they're a member of)
$clubSql = "SELECT Club_ID FROM Membership WHERE Student_ID = ? ORDER BY Join_Date ASC LIMIT 1";
$clubStmt = mysqli_prepare($conn, $clubSql);
mysqli_stmt_bind_param($clubStmt, "i", $user['Student_ID']);
mysqli_stmt_execute($clubStmt);
$clubResult = mysqli_stmt_get_result($clubStmt);
$clubData = mysqli_fetch_assoc($clubResult);
mysqli_stmt_close($clubStmt);

// Return user data (exclude password)
unset($user['Password']);
$user['role'] = $role;
$user['Club_ID'] = $clubData ? $clubData['Club_ID'] : null;

echo json_encode([
    "success" => true,
    "user" => $user,
    "message" => "Login successful"
]);
?>