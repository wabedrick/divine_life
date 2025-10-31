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
        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained('conversations')->onDelete('cascade');
            $table->foreignId('sender_id')->constrained('users')->onDelete('cascade');
            $table->string('sender_name'); // Cache sender name for performance
            $table->longText('content');
            $table->enum('type', ['text', 'image', 'file', 'audio', 'video', 'location', 'system'])->default('text');
            $table->enum('status', ['sending', 'sent', 'delivered', 'read', 'failed'])->default('sent');
            $table->string('file_url')->nullable();
            $table->string('file_name')->nullable();
            $table->bigInteger('file_size')->nullable();
            $table->foreignId('reply_to_id')->nullable()->constrained('messages')->onDelete('set null');
            $table->json('metadata')->nullable();
            $table->boolean('is_encrypted')->default(false);
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            // Indexes for better performance
            $table->index('conversation_id');
            $table->index('sender_id');
            $table->index(['conversation_id', 'created_at']);
            $table->index('type');
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('messages');
    }
};
