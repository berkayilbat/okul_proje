<?php
require 'c:/xampp/htdocs/backend/db.php';
$stmt = $conn->query('SELECT ja.*, j.title FROM job_applications ja JOIN jobs j on ja.job_id = j.id');
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
?>
