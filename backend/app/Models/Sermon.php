<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Sermon extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'youtube_url',
        'youtube_video_id',
        'thumbnail_url',
        'category',
        'speaker',
        'sermon_date',
        'duration_seconds',
        'view_count',
        'is_featured',
        'is_active',
        'tags',
        'created_by',
    ];

    protected $casts = [
        'sermon_date' => 'date',
        'is_featured' => 'boolean',
        'is_active' => 'boolean',
        'tags' => 'array',
    ];

    // Scopes for easy querying
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeFeatured($query)
    {
        return $query->where('is_featured', true);
    }

    public function scopeByCategory($query, $category)
    {
        return $query->where('category', $category);
    }

    public function scopeSearch($query, $searchTerm)
    {
        return $query->where(function ($q) use ($searchTerm) {
            $q->where('title', 'like', "%{$searchTerm}%")
                ->orWhere('description', 'like', "%{$searchTerm}%")
                ->orWhere('speaker', 'like', "%{$searchTerm}%")
                ->orWhereJsonContains('tags', $searchTerm);
        });
    }

    // Accessor to extract video ID from YouTube URL
    public function setYoutubeUrlAttribute($value)
    {
        $this->attributes['youtube_url'] = $value;

        // Extract video ID from various YouTube URL formats
        if (preg_match('/(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/', $value, $matches)) {
            $this->attributes['youtube_video_id'] = $matches[1];
            $this->attributes['thumbnail_url'] = "https://img.youtube.com/vi/{$matches[1]}/maxresdefault.jpg";
        }
    }

    // Accessor for formatted duration
    public function getFormattedDurationAttribute()
    {
        if (!$this->duration_seconds) {
            return null;
        }

        $hours = floor($this->duration_seconds / 3600);
        $minutes = floor(($this->duration_seconds % 3600) / 60);
        $seconds = $this->duration_seconds % 60;

        if ($hours > 0) {
            return sprintf('%d:%02d:%02d', $hours, $minutes, $seconds);
        }

        return sprintf('%d:%02d', $minutes, $seconds);
    }
}
