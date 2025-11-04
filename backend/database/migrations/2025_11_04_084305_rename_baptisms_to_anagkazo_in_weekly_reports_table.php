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
            // Check if baptisms column exists before renaming
            if (Schema::hasColumn('weekly_reports', 'baptisms')) {
                $table->renameColumn('baptisms', 'anagkazo');
            }

            // Remove columns that are no longer needed
            if (Schema::hasColumn('weekly_reports', 'testimonies')) {
                $table->dropColumn('testimonies');
            }

            if (Schema::hasColumn('weekly_reports', 'discipleship_activities')) {
                $table->dropColumn('discipleship_activities');
            }

            if (Schema::hasColumn('weekly_reports', 'community_outreach')) {
                $table->dropColumn('community_outreach');
            }

            if (Schema::hasColumn('weekly_reports', 'praise')) {
                $table->dropColumn('praise');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('weekly_reports', function (Blueprint $table) {
            // Reverse the column rename
            if (Schema::hasColumn('weekly_reports', 'anagkazo')) {
                $table->renameColumn('anagkazo', 'baptisms');
            }

            // Add back the dropped columns
            $table->integer('testimonies')->default(0)->nullable();
            $table->text('discipleship_activities')->nullable();
            $table->text('community_outreach')->nullable();
            $table->text('praise')->nullable();
        });
    }
};
