<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\User;
use App\Models\Branch;
use App\Models\MC;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class EventController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * Display a listing of events with filters and pagination
     */
    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $query = Event::with(['createdBy', 'branch', 'mc'])
            ->visibleToUser($user)
            ->active();

        // Apply filters
        if ($request->filled('search')) {
            $search = $request->get('search');
            $query->where(function($q) use ($search) {
                $q->where('title', 'LIKE', "%{$search}%")
                  ->orWhere('description', 'LIKE', "%{$search}%")
                  ->orWhere('location', 'LIKE', "%{$search}%");
            });
        }

        if ($request->filled('visibility')) {
            $query->where('visibility', $request->get('visibility'));
        }

        if ($request->filled('branch_id')) {
            $query->where('branch_id', $request->get('branch_id'));
        }

        if ($request->filled('mc_id')) {
            $query->where('mc_id', $request->get('mc_id'));
        }

        if ($request->filled('date_from')) {
            $query->where('event_date', '>=', $request->get('date_from'));
        }

        if ($request->filled('date_to')) {
            $query->where('event_date', '<=', $request->get('date_to'));
        }

        if ($request->filled('upcoming')) {
            if ($request->boolean('upcoming')) {
                $query->upcoming();
            }
        }

        // Sort options
        $sortBy = $request->get('sort_by', 'event_date');
        $sortOrder = $request->get('sort_order', 'asc');
        $query->orderBy($sortBy, $sortOrder);

        $events = $query->paginate($request->get('per_page', 15));

        return response()->json([
            'events' => $events->items(),
            'pagination' => [
                'current_page' => $events->currentPage(),
                'last_page' => $events->lastPage(),
                'per_page' => $events->perPage(),
                'total' => $events->total()
            ]
        ]);
    }

    /**
     * Store a newly created event
     */
    public function store(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        // Only MC leaders and higher can create events
        if (!$user->isMCLeader() && !$user->isBranchAdmin() && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:2000',
            'event_date' => 'required|date|after:now',
            'end_date' => 'nullable|date|after_or_equal:event_date',
            'location' => 'required|string|max:255',
            'visibility' => 'required|in:all,branch,mc',
            'branch_id' => 'nullable|exists:branches,id',
            'mc_id' => 'nullable|exists:missional_communities,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Set visibility constraints based on user role
        if ($user->isMCLeader() && !$user->isBranchAdmin() && !$user->isSuperAdmin()) {
            // MC leaders can only create events for their MC or branch
            if ($data['visibility'] === 'all') {
                return response()->json(['error' => 'MC leaders cannot create events visible to all'], 403);
            }

            if ($data['visibility'] === 'mc' && (!isset($data['mc_id']) || $data['mc_id'] !== $user->mc_id)) {
                return response()->json(['error' => 'Can only create MC events for your own MC'], 403);
            }

            if ($data['visibility'] === 'branch') {
                $data['branch_id'] = $user->branch_id;
            }
        } elseif ($user->isBranchAdmin() && !$user->isSuperAdmin()) {
            // Branch admins can create events for their branch or MCs in their branch
            if ($data['visibility'] === 'branch') {
                $data['branch_id'] = $user->branch_id;
            }

            if ($data['visibility'] === 'mc' && isset($data['mc_id'])) {
                $mc = MC::find($data['mc_id']);
                if (!$mc || $mc->branch_id !== $user->branch_id) {
                    return response()->json(['error' => 'Can only create events for MCs in your branch'], 403);
                }
            }
        }

        // Validate branch/MC constraints
        if ($data['visibility'] === 'branch' && !isset($data['branch_id'])) {
            return response()->json(['error' => 'Branch ID is required for branch visibility'], 422);
        }

        if ($data['visibility'] === 'mc' && !isset($data['mc_id'])) {
            return response()->json(['error' => 'MC ID is required for MC visibility'], 422);
        }

        $data['created_by'] = $user->id;
        $data['is_active'] = $data['is_active'] ?? true;

        $event = Event::create($data);
        $event->load(['createdBy', 'branch', 'mc']);

        return response()->json([
            'message' => 'Event created successfully',
            'event' => $event
        ], 201);
    }

    /**
     * Display the specified event
     */
    public function show(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $event = Event::with(['createdBy', 'branch', 'mc'])->find($id);

        if (!$event) {
            return response()->json(['error' => 'Event not found'], 404);
        }

        // Check visibility
        $canView = Event::where('id', $id)->visibleToUser($user)->exists();

        if (!$canView) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        return response()->json(['event' => $event]);
    }

    /**
     * Update the specified event
     */
    public function update(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $event = Event::find($id);

        if (!$event) {
            return response()->json(['error' => 'Event not found'], 404);
        }

        // Role-based access control
        $canUpdate = false;

        if ($user->isSuperAdmin()) {
            $canUpdate = true;
        } elseif ($user->isBranchAdmin()) {
            // Branch admins can update events in their branch or created by them
            $canUpdate = $event->created_by === $user->id ||
                        ($event->branch_id === $user->branch_id) ||
                        ($event->mc && $event->mc->branch_id === $user->branch_id);
        } elseif ($user->isMCLeader()) {
            // MC leaders can update events they created
            $canUpdate = $event->created_by === $user->id;
        }

        if (!$canUpdate) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string|max:2000',
            'event_date' => 'sometimes|date',
            'end_date' => 'nullable|date|after_or_equal:event_date',
            'location' => 'sometimes|string|max:255',
            'visibility' => 'sometimes|in:all,branch,mc',
            'branch_id' => 'nullable|exists:branches,id',
            'mc_id' => 'nullable|exists:missional_communities,id',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Apply same visibility constraints as create
        if (isset($data['visibility'])) {
            if ($user->isMCLeader() && !$user->isBranchAdmin() && !$user->isSuperAdmin()) {
                if ($data['visibility'] === 'all') {
                    return response()->json(['error' => 'MC leaders cannot set visibility to all'], 403);
                }
            }
        }

        $event->update($data);
        $event->load(['createdBy', 'branch', 'mc']);

        return response()->json([
            'message' => 'Event updated successfully',
            'event' => $event
        ]);
    }

    /**
     * Remove the specified event from storage
     */
    public function destroy(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $event = Event::find($id);

        if (!$event) {
            return response()->json(['error' => 'Event not found'], 404);
        }

        // Role-based access control
        $canDelete = false;

        if ($user->isSuperAdmin()) {
            $canDelete = true;
        } elseif ($user->isBranchAdmin()) {
            $canDelete = $event->created_by === $user->id ||
                        ($event->branch_id === $user->branch_id) ||
                        ($event->mc && $event->mc->branch_id === $user->branch_id);
        } elseif ($user->isMCLeader()) {
            $canDelete = $event->created_by === $user->id;
        }

        if (!$canDelete) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $event->delete();

        return response()->json(['message' => 'Event deleted successfully']);
    }

    /**
     * Get upcoming events
     */
    public function upcoming(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $days = $request->get('days', 7); // Default to next 7 days

        $events = Event::with(['createdBy', 'branch', 'mc'])
            ->visibleToUser($user)
            ->active()
            ->where('event_date', '>=', now())
            ->where('event_date', '<=', now()->addDays($days))
            ->orderBy('event_date', 'asc')
            ->get();

        return response()->json(['upcoming_events' => $events]);
    }

    /**
     * Get today's events
     */
    public function today(): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $events = Event::with(['createdBy', 'branch', 'mc'])
            ->visibleToUser($user)
            ->active()
            ->whereDate('event_date', today())
            ->orderBy('event_date', 'asc')
            ->get();

        return response()->json(['todays_events' => $events]);
    }

    /**
     * Get calendar events for a specific month
     */
    public function calendar(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $validator = Validator::make($request->all(), [
            'year' => 'required|integer|min:2020|max:2030',
            'month' => 'required|integer|min:1|max:12',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $year = $request->get('year');
        $month = $request->get('month');

        $startDate = Carbon::create($year, $month, 1);
        $endDate = $startDate->copy()->endOfMonth();

        $events = Event::with(['createdBy', 'branch', 'mc'])
            ->visibleToUser($user)
            ->active()
            ->whereBetween('event_date', [$startDate, $endDate])
            ->orderBy('event_date', 'asc')
            ->get();

        return response()->json([
            'calendar_events' => $events,
            'period' => [
                'year' => $year,
                'month' => $month,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
            ]
        ]);
    }
}
