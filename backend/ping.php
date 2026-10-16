<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

echo json_encode([
    "status" => "success",
    "message" => "my_app backend active",
    "app" => "my_app"
]);
?>
