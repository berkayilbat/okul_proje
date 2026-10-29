<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('jobs', function (Blueprint $table) {
            $table->id();
            $table->string('employer_phone', 20);
            $table->string('title');
            $table->string('location');
            $table->string('working_hours', 100);
            $table->decimal('wage', 10, 2);
            $table->text('description');
            $table->string('dates', 100);
            $table->integer('worker_count')->default(1);
            $table->string('status', 50)->default('open');
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jobs');
    }
};
