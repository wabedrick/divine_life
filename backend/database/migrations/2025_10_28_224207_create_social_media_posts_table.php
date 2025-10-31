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
        Schema::create('social_media_posts', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('post_url'); // Link to the social media post
            $table->string('platform'); // instagram, facebook, tiktok, twitter, youtube_shorts
            $table->string('thumbnail_url')->nullable();
            $table->string('media_type')->default('video'); // video, image, carousel
            $table->string('category')->default('general'); // devotional, worship, testimony, announcement, etc.
            $table->date('post_date');
            $table->integer('like_count')->default(0);
            $table->integer('share_count')->default(0);
            $table->integer('comment_count')->default(0);
            $table->boolean('is_featured')->default(false);
            $table->boolean('is_active')->default(true);
            $table->json('hashtags')->nullable(); // array of hashtags for searching
            $table->timestamps();

            // Indexes for better search and filtering
            $table->index(['platform', 'is_active']);
            $table->index(['category', 'is_active']);
            $table->index(['post_date', 'is_active']);
            $table->index('is_featured');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('social_media_posts');
    }
};
