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
        Schema::create('branch_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('branch_id')->constrained('branches')->onDelete('cascade');
            $table->foreignId('submitted_by')->constrained('users')->onDelete('cascade');
            $table->date('week_ending');

            // Aggregated statistics from MC reports
            $table->integer('total_mcs_reporting')->default(0);
            $table->integer('total_members_met')->default(0);
            $table->integer('total_new_members')->default(0);
            $table->integer('total_salvations')->default(0);
            $table->integer('total_baptisms')->default(0);
            $table->integer('total_testimonies')->default(0);
            $table->decimal('total_offerings', 12, 2)->default(0);

            // Branch-level activities and notes
            $table->text('branch_activities')->nullable();
            $table->text('training_conducted')->nullable();
            $table->text('challenges')->nullable();
            $table->text('prayer_requests')->nullable();
            $table->text('goals_next_week')->nullable();
            $table->text('comments')->nullable();

            // Status tracking
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamp('reviewed_at')->nullable();
            $table->text('review_comments')->nullable();

            $table->timestamps();

            // Ensure one report per branch per week
            $table->unique(['branch_id', 'week_ending']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('branch_reports');
    }
};
