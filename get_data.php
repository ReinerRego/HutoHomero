<?php
// Replace these values with your actual database credentials
$host = 'mysql.nethely.hu';
$user = 'hutohomeroadat';
$pass = 'asd123';
$dbName = 'hutohomeroadat'; // Database name
$tableName = 'ReinerRego'; // Table name

// Create a connection to the database
$conn = new mysqli($host, $user, $pass, $dbName);

// Check the connection
if ($conn->connect_error) {
  die('Connection failed: ' . $conn->connect_error);
}

// Get the page and size parameters for pagination
$page = isset($_GET['page']) ? intval($_GET['page']) : 1;
$pageSize = isset($_GET['size']) ? intval($_GET['size']) : 10;

// Calculate the offset based on the page number and page size
$offset = ($page - 1) * $pageSize;

// Query to get the sensor data with pagination
$sql = "SELECT * FROM $tableName ORDER BY id DESC LIMIT $pageSize OFFSET $offset";
$result = $conn->query($sql);

// Check if the query was successful
if ($result->num_rows > 0) {
  // Create an array to store the sensor data
  $sensorData = array();

  // Fetch the data from the result
  while ($row = $result->fetch_assoc()) {
    // Add the row to the array
    $sensorData[] = array(
      'timestamp' => $row['reading_time'],
      'temperature' => $row['Temperature'],
      'humidity' => $row['Humidity'],
      'pressure' => $row['Pressure']
    );
  }

  // Convert the array to JSON and send it to the client
  header('Content-Type: application/json');
  echo json_encode($sensorData);
} else {
  // No data found
  echo 'No sensor data found.';
}

// Close the database connection
$conn->close();
?>
