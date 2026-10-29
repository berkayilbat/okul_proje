<?php

use Illuminate\Support\Facades\Route;

// Eski backend/ping.php ile aynı yanıt.
Route::get('/ping', function () {
    return response()->json([
        'status' => 'success',
        'message' => 'my_app backend active',
        'app' => 'my_app',
    ]);
});
