<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Sermon;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class SermonController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * Display a listing of sermons with search and filtering.
     */
    public function index(Request $request)
    {
        try {
            $query = Sermon::active()->orderBy('sermon_date', 'desc');

            // Search functionality
            if ($request->has('search') && !empty($request->search)) {
                $query->search($request->search);
            }

            // Filter by category
            if ($request->has('category') && !empty($request->category)) {
                $query->byCategory($request->category);
            }

            // Filter by speaker
            if ($request->has('speaker') && !empty($request->speaker)) {
                $query->where('speaker', 'like', "%{$request->speaker}%");
            }

            // Filter by date range
            if ($request->has('from_date') && !empty($request->from_date)) {
                $query->whereDate('sermon_date', '>=', $request->from_date);
            }

            if ($request->has('to_date') && !empty($request->to_date)) {
                $query->whereDate('sermon_date', '<=', $request->to_date);
            }

            // Featured sermons first if requested
            if ($request->has('featured') && $request->featured) {
                $query->orderBy('is_featured', 'desc');
            }

            $perPage = $request->get('per_page', 15);
            $sermons = $query->paginate($perPage);

            return response()->json($sermons);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to fetch sermons',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Store a newly created sermon.
     */
    public function store(Request $request)
    {
        /** @var User $user */
        $user = Auth::user();

        // Only admins can create sermons
        if (!$user->isSuperAdmin() && !$user->isBranchAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        try {
            $validator = Validator::make($request->all(), [
                'title' => 'required|string|max:255',
                'description' => 'nullable|string',
                'youtube_url' => ['required', 'url', 'regex:/^https?:\/\/(www\.)?(youtube\.com|youtu\.be)\/.+/'],
                'category' => 'required|string|in:sunday_service,bible_study,prayer_meeting,youth_service,special_event',
                'speaker' => 'required|string|max:255',
                'duration' => 'nullable|integer|min:0',
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
            $data['sermon_date'] = now();
            $data['is_active'] = true;
            $data['created_by'] = $user->id;

            // Convert duration from minutes to seconds if provided
            if (isset($data['duration'])) {
                $data['duration_seconds'] = $data['duration'] * 60;
                unset($data['duration']);
            }

            // Extract YouTube video ID from URL
            if (isset($data['youtube_url'])) {
                $data['youtube_video_id'] = $this->extractYouTubeVideoId($data['youtube_url']);
            }

            $sermon = Sermon::create($data);

            return response()->json($sermon, Response::HTTP_CREATED);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to create sermon',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Display the specified sermon.
     */
    public function show($id)
    {
        try {
            $sermon = Sermon::active()->findOrFail($id);

            // Increment view count
            $sermon->increment('view_count');

            return response()->json($sermon);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Sermon not found',
                'message' => $e->getMessage()
            ], Response::HTTP_NOT_FOUND);
        }
    }

    /**
     * Update the specified sermon.
     */
    public function update(Request $request, $id)
    {
        try {
            /** @var User $user */
            $user = Auth::user();

            // Only admins can update sermons
            if (!$user->isSuperAdmin() && !$user->isBranchAdmin()) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $sermon = Sermon::findOrFail($id);

            $validator = Validator::make($request->all(), [
                'title' => 'string|max:255',
                'description' => 'nullable|string',
                'youtube_url' => ['url', 'regex:/^https?:\/\/(www\.)?(youtube\.com|youtu\.be)\/.+/'],
                'category' => 'string|in:general,sunday_service,special_event,bible_study,youth,children,worship',
                'speaker' => 'nullable|string|max:255',
                'sermon_date' => 'date',
                'duration_seconds' => 'nullable|integer|min:0',
                'is_featured' => 'boolean',
                'is_active' => 'boolean',
                'tags' => 'nullable|array',
                'tags.*' => 'string|max:50',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'error' => 'Validation failed',
                    'errors' => $validator->errors()
                ], Response::HTTP_UNPROCESSABLE_ENTITY);
            }

            $sermon->update($validator->validated());

            return response()->json($sermon);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to update sermon',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Remove the specified sermon (soft delete by setting is_active to false).
     */
    public function destroy($id)
    {
        try {
            /** @var User $user */
            $user = Auth::user();

            // Only super admin may delete sermons
            if (!$user->isSuperAdmin()) {
                return response()->json(['error' => 'Forbidden'], 403);
            }

            $sermon = Sermon::findOrFail($id);
            $sermon->update(['is_active' => false]);

            return response()->json([
                'message' => 'Sermon deactivated successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to deactivate sermon',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Get featured sermons.
     */
    public function featured(Request $request)
    {
        try {
            $limit = $request->get('limit', 5);
            $sermons = Sermon::active()->featured()
                ->orderBy('sermon_date', 'desc')
                ->limit($limit)
                ->get();

            return response()->json($sermons);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to fetch featured sermons',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Get available categories.
     */
    public function categories()
    {
        try {
            $categories = [
                'general' => 'General',
                'sunday_service' => 'Sunday Service',
                'special_event' => 'Special Event',
                'bible_study' => 'Bible Study',
                'youth' => 'Youth Ministry',
                'children' => 'Children\'s Ministry',
                'worship' => 'Worship & Music'
            ];

            return response()->json($categories);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to fetch categories',
                'message' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Extract YouTube video ID from URL
     */
    private function extractYouTubeVideoId($url)
    {
        $pattern = '/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/';
        preg_match($pattern, $url, $matches);
        return isset($matches[1]) ? $matches[1] : null;
    }
}
