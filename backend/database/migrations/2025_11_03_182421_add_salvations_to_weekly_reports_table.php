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
            $table->integer('salvations')->default(0)->after('new_members');
            $table->integer('baptisms')->default(0)->after('salvations');
            $table->integer('testimonies')->default(0)->after('baptisms');
            $table->text('discipleship_activities')->nullable()->after('evangelism_activities');
            $table->text('community_outreach')->nullable()->after('discipleship_activities');
            $table->text('challenges')->nullable()->after('comments');
            $table->text('prayer_requests')->nullable()->after('challenges');
            $table->text('praise')->nullable()->after('prayer_requests');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('weekly_reports', function (Blueprint $table) {
            $table->dropColumn([
                'salvations',
                'baptisms',
                'testimonies',
                'discipleship_activities',
                'community_outreach',
                'challenges',
                'prayer_requests',
                'praise'
            ]);
        });
    }
};
