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
        Schema::table('weekly_reports', function (Blueprint $table) {
            $table->unsignedBigInteger('branch_report_id')->nullable()->after('review_comments');
            $table->foreign('branch_report_id')->references('id')->on('branch_reports')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('weekly_reports', function (Blueprint $table) {
            $table->dropForeign(['branch_report_id']);
            $table->dropColumn('branch_report_id');
        });
    }
};
