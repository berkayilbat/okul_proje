<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Eski backend/seed.php şemasının aynısı; telefon alanları Sprint 2'ye kadar kalır.
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('role', 50)->comment('Employee veya Employer');
            $table->string('first_name', 100);
            $table->string('last_name', 100);
            $table->string('phone', 20)->unique();
            $table->string('password');
            $table->string('tc_kimlik_no', 11)->nullable();
            $table->string('company_name')->nullable();
            $table->string('tax_no', 20)->nullable();
            $table->string('profile_image')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->decimal('wallet_balance', 10, 2)->default(0);
            $table->decimal('average_rating', 3, 2)->default(5);
            $table->date('birth_date')->nullable();
            $table->text('address')->nullable();
            $table->text('professions')->nullable();
            $table->text('certificates_json')->nullable();
            $table->text('past_workplaces_json')->nullable();
            $table->boolean('is_profile_complete')->default(false);
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('users');
    }
};
