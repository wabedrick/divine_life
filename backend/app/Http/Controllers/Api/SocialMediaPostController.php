<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SocialMediaPost;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class SocialMediaPostController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * Display a listing of social media posts with search and filtering.
     */
    public function index(Request $request)
    {
        try {
            $query = SocialMediaPost::active()->orderBy('post_date', 'desc');

            // Search functionality
            if ($request->has('search') && !empty($request->search)) {
                $query->search($request->search);
            }

            // Filter by platform
            if ($request->has('platform') && !empty($request->platform)) {
                $query->byPlatform($request->platform);
            }

            // Filter by category
            if ($request->has('category') && !empty($request->category)) {
                $query->byCategory($request->category);
            }

            // Filter by media type
            if ($request->has('media_type') && !empty($request->media_type)) {
                $query->where('media_type', $request->media_type);
            }

            // Filter by date range
            if ($request->has('from_date') && !empty($request->from_date)) {
                $query->whereDate('post_date', '>=', $request->from_date);
            }

            if ($request->has('to_date') && !empty($request->to_date)) {
                $query->whereDate('post_date', '<=', $request->to_date);
            }

            // Featured posts first if requested
            if ($request->has('featured') && $request->featured) {
                $query->orderBy('is_featured', 'desc');
            }

            $perPage = $request->get('per_page', 15);
            $posts = $query->paginate($perPage);

            return response()->json($posts);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to fetch social media posts',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Store a newly created social media post.
     */
    public function store(Request $request)
    {
        /** @var User $user */
        $user = Auth::user();

        // Only admins can create social media posts
        if (!$user->isSuperAdmin() && !$user->isBranchAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        try {
            $validator = Validator::make($request->all(), [
                'title' => 'required|string|max:255',
                'description' => 'nullable|string',
                'post_url' => 'required|url',
                'platform' => 'required|string|in:instagram,facebook,tiktok,twitter,youtube_shorts',
                'media_type' => 'required|string|in:video,image,carousel,story',
                'hashtags' => 'nullable|string',
                'is_featured' => 'boolean',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'error' => 'Validation failed',
                    'errors' => $validator->errors()
                ], Response::HTTP_UNPROCESSABLE_ENTITY);
            }

            $data = $validator->validated();

            // Set default values
            $data['post_date'] = now();
            $data['is_active'] = true;
            $data['created_by'] = $user->id;
            $data['category'] = 'general'; // Default category

            $post = SocialMediaPost::create($data);

            return response()->json($post, Response::HTTP_CREATED);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to create social media post',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Display the specified social media post.
     */
    public function show($id)
    {
        try {
            $post = SocialMediaPost::active()->findOrFail($id);

            return response()->json($post);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Social media post not found',
                'message' => $e->getMessage()
            ], Response::HTTP_NOT_FOUND);
        }
    }

    /**
     * Update the specified social media post.
     */
    public function update(Request $request, $id)
    {
        try {
            $post = SocialMediaPost::findOrFail($id);

            $validator = Validator::make($request->all(), [
                'title' => 'string|max:255',
                'description' => 'nullable|string',
                'post_url' => 'url',
                'platform' => 'string|in:instagram,facebook,tiktok,twitter,youtube_shorts',
                'thumbnail_url' => 'nullable|url',
                'media_type' => 'string|in:video,image,carousel',
                'category' => 'string|in:general,devotional,worship,testimony,announcement,prayer,outreach',
                'post_date' => 'date',
                'like_count' => 'nullable|integer|min:0',
                'share_count' => 'nullable|integer|min:0',
                'comment_count' => 'nullable|integer|min:0',
                'is_featured' => 'boolean',
                'is_active' => 'boolean',
                'hashtags' => 'nullable|array',
                'hashtags.*' => 'string|max:50',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'error' => 'Validation failed',
                    'errors' => $validator->errors()
                ], Response::HTTP_UNPROCESSABLE_ENTITY);
            }

            $post->update($validator->validated());

            return response()->json($post);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to update social media post',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Remove the specified social media post (soft delete by setting is_active to false).
     */
    public function destroy($id)
    {
        try {
            $post = SocialMediaPost::findOrFail($id);
            $post->update(['is_active' => false]);

            return response()->json([
                'message' => 'Social media post deactivated successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to deactivate social media post',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Get featured social media posts.
     */
    public function featured(Request $request)
    {
        try {
            $limit = $request->get('limit', 10);
            $posts = SocialMediaPost::active()->featured()
                ->orderBy('post_date', 'desc')
                ->limit($limit)
                ->get();

            return response()->json($posts);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to fetch featured posts',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Get available platforms.
     */
    public function platforms()
    {
        try {
            $platforms = [
                'instagram' => 'Instagram',
                'facebook' => 'Facebook',
                'tiktok' => 'TikTok',
                'twitter' => 'Twitter',
                'youtube_shorts' => 'YouTube Shorts'
            ];

            return response()->json($platforms);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to fetch platforms',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Get posts by platform.
     */
    public function byPlatform($platform, Request $request)
    {
        try {
            $query = SocialMediaPost::active()->byPlatform($platform);

            if ($request->has('search') && !empty($request->search)) {
                $query->search($request->search);
            }

            $perPage = $request->get('per_page', 15);
            $posts = $query->orderBy('post_date', 'desc')->paginate($perPage);

            return response()->json($posts);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to fetch posts for platform',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }
}
