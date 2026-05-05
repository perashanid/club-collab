<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "club_collab";

// Create connection
$conn = mysqli_connect($servername, $username, $password, $dbname);

// Check connection
if (!$conn) {
  // Return a JSON error instead of plain text
  die(json_encode(["error" => "Connection failed: " . mysqli_connect_error()]));
}

// Do NOT echo anything else down here!
?>