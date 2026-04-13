<?php
require 'db.php';
print_r($conn->query('SHOW TABLES')->fetchAll(PDO::FETCH_ASSOC));
print_r($conn->query('DESCRIBE users')->fetchAll(PDO::FETCH_ASSOC));
?>
