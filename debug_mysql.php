<?php
require 'c:/xampp/htdocs/backend/db.php';
try {
    $r1 = $conn->query("SHOW CREATE TABLE jobs")->fetchAll(PDO::FETCH_ASSOC);
    $r2 = $conn->query("SHOW CREATE TABLE job_applications")->fetchAll(PDO::FETCH_ASSOC);
    echo "JOBS:\n" . $r1[0]['Create Table'] . "\n\n";
    echo "APPLICATIONS:\n" . $r2[0]['Create Table'] . "\n\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
