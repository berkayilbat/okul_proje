<?php
require 'c:/xampp/htdocs/backend/db.php';

echo "--- job_applications ---\n";
$stmt = $conn->query("SELECT * FROM job_applications");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

echo "--- users ---\n";
$stmt = $conn->query("SELECT phone, first_name FROM users");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

echo "--- employer apps exactly like API ---\n";
$employer_phone = "05433072268"; // Hardcode just in case, or from the screen we see 05433072268? From previous image, the register screen had 05433072268. Let's just run for all employers.
$stmt = $conn->query("
    SELECT ja.id as application_id, ja.job_id, ja.employee_phone, u.phone as u_phone
    FROM job_applications ja
    LEFT JOIN users u ON ja.employee_phone = u.phone
");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

?>
<?php require 'c:/xampp/htdocs/backend/db.php'; $conn->query("DELETE FROM job_applications WHERE employee_phone = ''"); ?>
