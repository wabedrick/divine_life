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
        Schema::create('missional_communities', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('vision')->nullable();
            $table->text('goals')->nullable();
            $table->text('purpose')->nullable();
            $table->string('location');
            $table->foreignId('leader_id')->constrained('users')->onDelete('cascade');
            $table->string('leader_phone')->nullable();
            $table->foreignId('branch_id')->constrained('branches')->onDelete('cascade');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('missional_communities');
    }
};
