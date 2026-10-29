<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('job_applications', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('job_id')->index();
            $table->string('employee_phone', 20)->index();
            $table->string('status', 50)->default('applied');
            $table->integer('rating')->nullable();
            $table->text('review_comment')->nullable();
            $table->integer('employer_rating')->nullable();
            $table->text('employer_review_comment')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('job_applications');
    }
};
