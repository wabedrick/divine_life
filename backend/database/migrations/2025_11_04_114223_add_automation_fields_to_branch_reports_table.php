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
        Schema::table('branch_reports', function (Blueprint $table) {
            $table->boolean('is_auto_generated')->default(false)->after('status');
            $table->boolean('sent_to_super_admin')->default(false)->after('is_auto_generated');
            $table->timestamp('sent_at')->nullable()->after('sent_to_super_admin');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('branch_reports', function (Blueprint $table) {
            $table->dropColumn(['is_auto_generated', 'sent_to_super_admin', 'sent_at']);
        });
    }
};
