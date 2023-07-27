<?php
// Database credentials
$hostname = "mysql.nethely.hu";
$username = "hutohomeroadat";
$password = "asd123";
$database = "hutohomeroadat"; // Update with the correct database name

// Table name as a variable
$tableName = "ReinerRego"; // Replace with the desired table name

// Connect to MySQL database
$mysqli = new mysqli($hostname, $username, $password, $database);
if ($mysqli->connect_errno) {
    die("Failed to connect to MySQL: " . $mysqli->connect_error);
}

// Check if the API key is correct
$api_key = "2023ESPCHARTER";
if ($_POST['api_key'] !== $api_key) {
    die("Invalid API key.");
}

// Get sensor data from the POST request
$sensorName = $_POST['sensor_name'];
$location = $_POST['location'];
$temperature = $_POST['temperature'];
$humidity = $_POST['humidity'];
$pressure = $_POST['pressure'];
$reading_time = date('Y-m-d H:i:s');

// Prepare the table name for the query (to prevent SQL injection)
$tableName = $mysqli->real_escape_string($tableName);

// Insert data into the database
$sql = "INSERT INTO $tableName (SensorName, location, Temperature, Humidity, Pressure, reading_time) VALUES ('$sensorName', '$location', '$temperature', '$humidity', '$pressure', '$reading_time')";

if ($mysqli->query($sql) === true) {
    echo "Data inserted successfully.";
} else {
    echo "Error: " . $sql . "<br>" . $mysqli->error;
}

// Close the database connection
$mysqli->close();
?>
