<?php
// PHP CLI Test Runner for 1.9 Sanitization & Security Functions

require_once __DIR__ . '/db.php';

echo "=== 1.9 Sanitization & Security Backend Test Suite ===\n\n";

$passCount = 0;
$failCount = 0;

function assert_test($description, $actual, $expected) {
    global $passCount, $failCount;
    if ($actual === $expected) {
        echo " [PASS] $description\n";
        $passCount++;
    } else {
        echo " [FAIL] $description\n";
        echo "        Expected: " . var_export($expected, true) . "\n";
        echo "        Actual:   " . var_export($actual, true) . "\n";
        $failCount++;
    }
}

// 1. sanitize_text tests
assert_test(
    "sanitize_text strips script tags",
    sanitize_text("<script>alert('XSS')</script>Merhaba"),
    "alert(&#039;XSS&#039;)Merhaba"
);

assert_test(
    "sanitize_text strips img tags with onerror",
    sanitize_text("<img src=x onerror=alert(1)>"),
    ""
);

assert_test(
    "sanitize_text removes null bytes",
    sanitize_text("Temiz\0Metin"),
    "TemizMetin"
);

assert_test(
    "sanitize_text encodes HTML special characters",
    sanitize_text("A & B ' C \" D"),
    "A &amp; B &#039; C &quot; D"
);

assert_test(
    "sanitize_text respects maxLength",
    sanitize_text("Uzun bir ilan metni", 8),
    "Uzun bir"
);

// 2. sanitize_int tests
assert_test("sanitize_int parses valid int", sanitize_int("42"), 42);
assert_test("sanitize_int rejects letters and returns default", sanitize_int("abc", 0), 0);
assert_test("sanitize_int blocks SQL injection in int field", sanitize_int("1; DROP TABLE users;", 0), 0);
assert_test("sanitize_int enforces min bounds", sanitize_int("-5", 0, 1, 10), 1);
assert_test("sanitize_int enforces max bounds", sanitize_int("20", 0, 1, 10), 10);

// 3. sanitize_float tests
assert_test("sanitize_float parses comma decimal separator", sanitize_float("150,50"), 150.50);
assert_test("sanitize_float parses dot decimal separator", sanitize_float("250.75"), 250.75);
assert_test("sanitize_float rejects SQL injection", sanitize_float("' OR 1=1 --", 0.0), 0.0);
assert_test("sanitize_float enforces min limit", sanitize_float("-50.0", 0.0, 0.0), 0.0);

// 4. sanitize_phone tests
assert_test("sanitize_phone extracts digits from formatted phone", sanitize_phone("0544 507 35 25"), "05445073525");
assert_test("sanitize_phone strips letters and symbols", sanitize_phone("+90 (544) 507-3525"), "905445073525");

// 5. sanitize_enum tests
assert_test("sanitize_enum accepts whitelisted value", sanitize_enum("Employer", ['Employer', 'Employee'], 'Employee'), "Employer");
assert_test("sanitize_enum rejects arbitrary injected values", sanitize_enum("Admin'--", ['Employer', 'Employee'], 'Employee'), "Employee");

// 6. PDO Security Setting Check
if ($conn instanceof PDO) {
    $emulatePrepares = $conn->getAttribute(PDO::ATTR_EMULATE_PREPARES);
    assert_test("PDO EMULATE_PREPARES is disabled (real prepared statements)", (bool)$emulatePrepares, false);
}

echo "\nSummary: $passCount passed, $failCount failed.\n";

if ($failCount > 0) {
    exit(1);
}
?>