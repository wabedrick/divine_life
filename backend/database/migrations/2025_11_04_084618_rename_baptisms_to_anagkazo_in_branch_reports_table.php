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
            // Check if total_baptisms column exists before renaming
            if (Schema::hasColumn('branch_reports', 'total_baptisms')) {
                $table->renameColumn('total_baptisms', 'total_anagkazo');
            }

            // Remove unused columns if they exist
            if (Schema::hasColumn('branch_reports', 'total_testimonies')) {
                $table->dropColumn('total_testimonies');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('branch_reports', function (Blueprint $table) {
            // Rename back to total_baptisms
            if (Schema::hasColumn('branch_reports', 'total_anagkazo')) {
                $table->renameColumn('total_anagkazo', 'total_baptisms');
            }

            // Add back removed columns
            if (!Schema::hasColumn('branch_reports', 'total_testimonies')) {
                $table->integer('total_testimonies')->default(0)->after('total_anagkazo');
            }
        });
    }
};
