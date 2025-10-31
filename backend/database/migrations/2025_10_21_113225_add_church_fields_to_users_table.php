<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone_number')->nullable();
            $table->foreignId('branch_id')->nullable()->constrained('branches')->onDelete('set null');
            $table->foreignId('mc_id')->nullable()->constrained('missional_communities')->onDelete('set null');
            $table->date('birth_date')->nullable();
            $table->enum('gender', ['male', 'female'])->nullable();
            $table->enum('role', ['super_admin', 'branch_admin', 'mc_leader', 'member'])->default('member');
            $table->boolean('is_approved')->default(false);
            $table->timestamp('approved_at')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->onDelete('set null');
            $table->text('rejection_reason')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['branch_id']);
            $table->dropForeign(['mc_id']);
            $table->dropForeign(['approved_by']);
            $table->dropColumn([
                'phone_number',
                'branch_id',
                'mc_id',
                'birth_date',
                'gender',
                'role',
                'is_approved',
                'approved_at',
                'approved_by',
                'rejection_reason'
            ]);
        });
    }
};
