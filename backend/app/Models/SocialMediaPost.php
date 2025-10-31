<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class SocialMediaPost extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'post_url',
        'platform',
        'thumbnail_url',
        'media_type',
        'category',
        'post_date',
        'like_count',
        'share_count',
        'comment_count',
        'is_featured',
        'is_active',
        'hashtags',
        'created_by',
    ];

    protected $casts = [
        'post_date' => 'date',
        'is_featured' => 'boolean',
        'is_active' => 'boolean',
        'hashtags' => 'array',
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

    public function scopeByPlatform($query, $platform)
    {
        return $query->where('platform', $platform);
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
                ->orWhereJsonContains('hashtags', $searchTerm);
        });
    }

    // Get platform icon
    public function getPlatformIconAttribute()
    {
        $icons = [
            'instagram' => 'fab fa-instagram',
            'facebook' => 'fab fa-facebook',
            'tiktok' => 'fab fa-tiktok',
            'twitter' => 'fab fa-twitter',
            'youtube_shorts' => 'fab fa-youtube',
        ];

        return $icons[$this->platform] ?? 'fas fa-share-alt';
    }

    // Get platform color
    public function getPlatformColorAttribute()
    {
        $colors = [
            'instagram' => '#E4405F',
            'facebook' => '#1877F2',
            'tiktok' => '#000000',
            'twitter' => '#1DA1F2',
            'youtube_shorts' => '#FF0000',
        ];

        return $colors[$this->platform] ?? '#6B7280';
    }

    // Get engagement total
    public function getTotalEngagementAttribute()
    {
        return $this->like_count + $this->share_count + $this->comment_count;
    }
}
