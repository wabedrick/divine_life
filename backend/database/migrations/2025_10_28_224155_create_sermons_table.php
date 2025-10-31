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
        Schema::create('sermons', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('youtube_url');
            $table->string('youtube_video_id');
            $table->string('thumbnail_url')->nullable();
            $table->string('category')->default('general'); // general, sunday_service, special_event, bible_study, etc.
            $table->string('speaker')->nullable();
            $table->date('sermon_date');
            $table->integer('duration_seconds')->nullable(); // video duration in seconds
            $table->integer('view_count')->default(0);
            $table->boolean('is_featured')->default(false);
            $table->boolean('is_active')->default(true);
            $table->json('tags')->nullable(); // array of tags for searching
            $table->timestamps();

            // Indexes for better search performance
            $table->index(['category', 'is_active']);
            $table->index(['sermon_date', 'is_active']);
            $table->index('is_featured');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sermons');
    }
};
