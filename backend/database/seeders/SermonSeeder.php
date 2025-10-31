<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Sermon;
use App\Models\SocialMediaPost;
use Illuminate\Support\Carbon;

class SermonSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Sample Sermons
        $sermons = [
            [
                'title' => 'Walking in Faith: Trusting God\'s Plan',
                'description' => 'A powerful message about trusting in God\'s perfect plan for our lives, even when we cannot see the full picture.',
                'youtube_url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                'category' => 'sunday_service',
                'speaker' => 'Pastor John Smith',
                'sermon_date' => Carbon::now()->subDays(7),
                'duration_seconds' => 2700, // 45 minutes
                'view_count' => 1250,
                'is_featured' => true,
                'tags' => ['faith', 'trust', 'gods-plan', 'sunday-service'],
            ],
            [
                'title' => 'The Power of Prayer in Daily Life',
                'description' => 'Understanding how prayer transforms our relationship with God and impacts our daily decisions.',
                'youtube_url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                'category' => 'bible_study',
                'speaker' => 'Pastor Sarah Johnson',
                'sermon_date' => Carbon::now()->subDays(14),
                'duration_seconds' => 3600, // 1 hour
                'view_count' => 890,
                'is_featured' => false,
                'tags' => ['prayer', 'daily-life', 'bible-study'],
            ],
            [
                'title' => 'Youth Conference 2024: Living Bold',
                'description' => 'An inspiring message to young people about living boldly for Christ in today\'s world.',
                'youtube_url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                'category' => 'youth',
                'speaker' => 'Pastor Mike Davis',
                'sermon_date' => Carbon::now()->subDays(21),
                'duration_seconds' => 2100, // 35 minutes
                'view_count' => 2100,
                'is_featured' => true,
                'tags' => ['youth', 'bold-living', 'conference'],
            ],
            [
                'title' => 'Christmas Special: The Gift of Hope',
                'description' => 'Celebrating the birth of Jesus and the hope He brings to the world.',
                'youtube_url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                'category' => 'special_event',
                'speaker' => 'Pastor John Smith',
                'sermon_date' => Carbon::now()->subDays(30),
                'duration_seconds' => 3300, // 55 minutes
                'view_count' => 3500,
                'is_featured' => true,
                'tags' => ['christmas', 'hope', 'jesus', 'special-event'],
            ],
            [
                'title' => 'Worship Night: Experiencing God\'s Presence',
                'description' => 'A worship-focused service exploring how music and praise bring us into God\'s presence.',
                'youtube_url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                'category' => 'worship',
                'speaker' => 'Worship Team',
                'sermon_date' => Carbon::now()->subDays(10),
                'duration_seconds' => 4200, // 1 hour 10 minutes
                'view_count' => 760,
                'is_featured' => false,
                'tags' => ['worship', 'presence', 'music', 'praise'],
            ],
        ];

        foreach ($sermons as $sermonData) {
            Sermon::create($sermonData);
        }

        // Sample Social Media Posts
        $socialMediaPosts = [
            [
                'title' => 'Daily Devotional: God\'s Love Never Fails',
                'description' => 'A short inspirational video about God\'s unchanging love for us.',
                'post_url' => 'https://www.instagram.com/p/example1',
                'platform' => 'instagram',
                'thumbnail_url' => 'https://via.placeholder.com/400x400/4267B2/FFFFFF?text=Daily+Devotional',
                'media_type' => 'video',
                'category' => 'devotional',
                'post_date' => Carbon::now()->subDays(1),
                'like_count' => 245,
                'share_count' => 32,
                'comment_count' => 18,
                'is_featured' => true,
                'hashtags' => ['dailydevotional', 'godslove', 'faith', 'divinelife'],
            ],
            [
                'title' => 'Sunday Service Highlights',
                'description' => 'Key moments from yesterday\'s powerful Sunday service.',
                'post_url' => 'https://www.facebook.com/watch/example2',
                'platform' => 'facebook',
                'thumbnail_url' => 'https://via.placeholder.com/640x360/1877F2/FFFFFF?text=Sunday+Service',
                'media_type' => 'video',
                'category' => 'worship',
                'post_date' => Carbon::now()->subDays(2),
                'like_count' => 389,
                'share_count' => 67,
                'comment_count' => 45,
                'is_featured' => true,
                'hashtags' => ['sundayservice', 'worship', 'church', 'highlights'],
            ],
            [
                'title' => 'Prayer Request: Community Outreach',
                'description' => 'Join us in praying for our upcoming community outreach events.',
                'post_url' => 'https://www.tiktok.com/@church/video/example3',
                'platform' => 'tiktok',
                'thumbnail_url' => 'https://via.placeholder.com/400x600/000000/FFFFFF?text=Prayer+Request',
                'media_type' => 'video',
                'category' => 'prayer',
                'post_date' => Carbon::now()->subDays(3),
                'like_count' => 156,
                'share_count' => 23,
                'comment_count' => 12,
                'is_featured' => false,
                'hashtags' => ['prayer', 'outreach', 'community', 'church'],
            ],
            [
                'title' => 'Testimony Tuesday: God\'s Faithfulness',
                'description' => 'A member shares how God has been faithful in their life journey.',
                'post_url' => 'https://www.youtube.com/shorts/example4',
                'platform' => 'youtube_shorts',
                'thumbnail_url' => 'https://via.placeholder.com/400x600/FF0000/FFFFFF?text=Testimony',
                'media_type' => 'video',
                'category' => 'testimony',
                'post_date' => Carbon::now()->subDays(4),
                'like_count' => 298,
                'share_count' => 41,
                'comment_count' => 28,
                'is_featured' => true,
                'hashtags' => ['testimony', 'faithfulness', 'godstories', 'tuesday'],
            ],
            [
                'title' => 'Upcoming Events This Week',
                'description' => 'Don\'t miss these exciting events happening at Divine Life Church this week!',
                'post_url' => 'https://www.twitter.com/church/status/example5',
                'platform' => 'twitter',
                'thumbnail_url' => 'https://via.placeholder.com/400x400/1DA1F2/FFFFFF?text=Events',
                'media_type' => 'image',
                'category' => 'announcement',
                'post_date' => Carbon::now()->subDays(5),
                'like_count' => 89,
                'share_count' => 34,
                'comment_count' => 7,
                'is_featured' => false,
                'hashtags' => ['events', 'thisweek', 'church', 'announcement'],
            ],
        ];

        foreach ($socialMediaPosts as $postData) {
            SocialMediaPost::create($postData);
        }
    }
}
