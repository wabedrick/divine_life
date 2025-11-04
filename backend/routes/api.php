<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\MCController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\BranchReportController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\AnnouncementController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\SermonController;
use App\Http\Controllers\Api\SocialMediaPostController;
use App\Http\Controllers\Api\BirthdayController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Authentication routes
Route::prefix('auth')->group(function () {
    Route::post('login', [AuthController::class, 'login']);
    Route::post('register', [AuthController::class, 'register']);
    Route::post('logout', [AuthController::class, 'logout']);
    Route::post('refresh', [AuthController::class, 'refresh']);
    Route::get('profile', [AuthController::class, 'profile']);
});

// Test route to verify API is working
Route::get('/test', function () {
    return response()->json(['message' => 'Divine Life Church API is working!']);
});

// Public routes (no authentication required)
// Branches - needed for registration form
Route::get('branches/public', [\App\Http\Controllers\Api\BranchController::class, 'publicIndex']);

// Protected routes requiring authentication
Route::middleware('auth:api')->group(function () {

    // User management routes
    Route::prefix('users')->group(function () {
        Route::get('/', [UserController::class, 'index']);
        Route::get('pending', [UserController::class, 'pending']);
        Route::get('statistics', [UserController::class, 'statistics']);
        Route::get('dashboard', [UserController::class, 'memberDashboard']);
        Route::get('{id}', [UserController::class, 'show']);
        Route::post('/', [UserController::class, 'store']);
        Route::put('{id}', [UserController::class, 'update']);
        Route::delete('{id}', [UserController::class, 'destroy']);
        Route::put('{id}/approval-status', [UserController::class, 'updateApprovalStatus']);
        Route::put('{id}/password', [UserController::class, 'changePassword']);
    });

    // Missional Communities routes
    Route::prefix('mcs')->group(function () {
        Route::get('/', [MCController::class, 'index']);
        Route::get('/{mc}', [MCController::class, 'show']);
        Route::post('/', [MCController::class, 'store']);
        Route::put('/{mc}', [MCController::class, 'update']);
        Route::delete('/{mc}', [MCController::class, 'destroy']);
        Route::get('/{mc}/members', [MCController::class, 'getMembers']);
        Route::post('/{mc}/members', [MCController::class, 'addMember']);
        Route::delete('/{mc}/members/{user}', [MCController::class, 'removeMember']);
    });

    // Branch management routes
    Route::get('branches', [\App\Http\Controllers\Api\BranchController::class, 'index']);
    Route::get('branches/{branch}', [\App\Http\Controllers\Api\BranchController::class, 'show']);
    Route::post('branches', [\App\Http\Controllers\Api\BranchController::class, 'store']);
    Route::put('branches/{branch}', [\App\Http\Controllers\Api\BranchController::class, 'update']);
    Route::delete('branches/{branch}', [\App\Http\Controllers\Api\BranchController::class, 'destroy']);
    Route::get('branches/{branch}/users', [\App\Http\Controllers\Api\BranchController::class, 'getUsers']);
    Route::post('branches/{branch}/assign-user', [\App\Http\Controllers\Api\BranchController::class, 'assignUser']);
    Route::get('branches/{branch}/statistics', [\App\Http\Controllers\Api\BranchController::class, 'getStatistics']);

    // MC Reports routes (weekly reports by MC leaders)
    Route::get('reports', [\App\Http\Controllers\Api\ReportController::class, 'index']);
    Route::get('reports/pending', [\App\Http\Controllers\Api\ReportController::class, 'pending']);
    Route::get('reports/statistics', [\App\Http\Controllers\Api\ReportController::class, 'statistics']);
    Route::get('reports/{report}', [\App\Http\Controllers\Api\ReportController::class, 'show']);
    Route::post('reports', [\App\Http\Controllers\Api\ReportController::class, 'store']);
    Route::put('reports/{report}', [\App\Http\Controllers\Api\ReportController::class, 'update']);
    Route::delete('reports/{report}', [\App\Http\Controllers\Api\ReportController::class, 'destroy']);
    Route::post('reports/{report}/approve', [\App\Http\Controllers\Api\ReportController::class, 'approve']);
    Route::post('reports/{report}/reject', [\App\Http\Controllers\Api\ReportController::class, 'reject']);

    // Branch Reports routes (aggregated reports by branch admins)
    Route::get('branch-reports', [\App\Http\Controllers\Api\BranchReportController::class, 'index']);
    Route::get('branch-reports/aggregated-stats', [\App\Http\Controllers\Api\BranchReportController::class, 'getAggregatedMCStats']);
    Route::post('branch-reports/generate-automated', [\App\Http\Controllers\Api\BranchReportController::class, 'generateAutomatedReports']);
    Route::get('branch-reports/pending-automated', [\App\Http\Controllers\Api\BranchReportController::class, 'getPendingAutomatedReports']);
    Route::get('branch-reports/pending-for-branch', [\App\Http\Controllers\Api\BranchReportController::class, 'getPendingForBranch']);
    Route::post('branch-reports/{branchReport}/send-to-super-admin', [\App\Http\Controllers\Api\BranchReportController::class, 'sendToSuperAdmin']);
    Route::post('branch-reports/{branchReport}/mark-sent', [\App\Http\Controllers\Api\BranchReportController::class, 'markAsSent']);
    Route::get('branch-reports/{branchReport}', [\App\Http\Controllers\Api\BranchReportController::class, 'show']);
    Route::post('branch-reports', [\App\Http\Controllers\Api\BranchReportController::class, 'store']);
    Route::put('branch-reports/{branchReport}', [\App\Http\Controllers\Api\BranchReportController::class, 'update']);
    Route::delete('branch-reports/{branchReport}', [\App\Http\Controllers\Api\BranchReportController::class, 'destroy']);

    // Events routes
    Route::get('events', [\App\Http\Controllers\Api\EventController::class, 'index']);
    Route::get('events/upcoming', [\App\Http\Controllers\Api\EventController::class, 'upcoming']);
    Route::get('events/today', [\App\Http\Controllers\Api\EventController::class, 'today']);
    Route::get('events/calendar', [\App\Http\Controllers\Api\EventController::class, 'calendar']);
    Route::get('events/{event}', [\App\Http\Controllers\Api\EventController::class, 'show']);
    Route::post('events', [\App\Http\Controllers\Api\EventController::class, 'store']);
    Route::put('events/{event}', [\App\Http\Controllers\Api\EventController::class, 'update']);
    Route::delete('events/{event}', [\App\Http\Controllers\Api\EventController::class, 'destroy']);

    // Announcements routes
    Route::get('announcements', [\App\Http\Controllers\Api\AnnouncementController::class, 'index']);
    Route::get('announcements/recent', [\App\Http\Controllers\Api\AnnouncementController::class, 'recent']);
    Route::get('announcements/urgent', [\App\Http\Controllers\Api\AnnouncementController::class, 'urgent']);
    Route::get('announcements/priority/{priority}', [\App\Http\Controllers\Api\AnnouncementController::class, 'byPriority']);
    Route::get('announcements/{announcement}', [\App\Http\Controllers\Api\AnnouncementController::class, 'show']);
    Route::post('announcements', [\App\Http\Controllers\Api\AnnouncementController::class, 'store']);
    Route::put('announcements/{announcement}', [\App\Http\Controllers\Api\AnnouncementController::class, 'update']);
    Route::delete('announcements/{announcement}', [\App\Http\Controllers\Api\AnnouncementController::class, 'destroy']);
    Route::post('announcements/{announcement}/mark-read', [\App\Http\Controllers\Api\AnnouncementController::class, 'markAsRead']);

    // Chat routes
    Route::prefix('chat')->group(function () {
        Route::get('conversations', [\App\Http\Controllers\Api\ChatController::class, 'getConversations']);
        Route::get('conversations/{conversationId}/messages', [\App\Http\Controllers\Api\ChatController::class, 'getMessages']);
        Route::post('messages', [\App\Http\Controllers\Api\ChatController::class, 'sendMessage']);
        Route::put('messages/{id}', [\App\Http\Controllers\Api\ChatController::class, 'updateMessage']);
        Route::delete('messages/{id}', [\App\Http\Controllers\Api\ChatController::class, 'deleteMessage']);
        Route::post('conversations', [\App\Http\Controllers\Api\ChatController::class, 'createConversation']);
        Route::post('conversations/category', [\App\Http\Controllers\Api\ChatController::class, 'getOrCreateCategoryConversation']);
    });

    // File uploads (used by mobile/web clients)
    // Accepts multipart/form-data with key 'file' and returns JSON { data: { url: ... }, url: ... }
    Route::post('files', [\App\Http\Controllers\Api\FilesController::class, 'store']);

    // Sermons routes
    Route::prefix('sermons')->group(function () {
        Route::get('/', [SermonController::class, 'index']);
        Route::get('featured', [SermonController::class, 'featured']);
        Route::get('categories', [SermonController::class, 'categories']);
        Route::get('{id}', [SermonController::class, 'show']);
        Route::post('/', [SermonController::class, 'store']);
        Route::put('{id}', [SermonController::class, 'update']);
        Route::delete('{id}', [SermonController::class, 'destroy']);
    });

    // Social Media Posts routes
    Route::prefix('social-media')->group(function () {
        Route::get('/', [SocialMediaPostController::class, 'index']);
        Route::get('featured', [SocialMediaPostController::class, 'featured']);
        Route::get('platforms', [SocialMediaPostController::class, 'platforms']);
        Route::get('platform/{platform}', [SocialMediaPostController::class, 'byPlatform']);
        Route::get('{id}', [SocialMediaPostController::class, 'show']);
        Route::post('/', [SocialMediaPostController::class, 'store']);
        Route::put('{id}', [SocialMediaPostController::class, 'update']);
        Route::delete('{id}', [SocialMediaPostController::class, 'destroy']);
    });

    // Birthday notification routes
    Route::prefix('birthdays')->group(function () {
        Route::get('notifications', [BirthdayController::class, 'getBirthdayNotifications']);
        Route::get('upcoming', [BirthdayController::class, 'getUpcomingBirthdays']);
        Route::post('acknowledge', [BirthdayController::class, 'acknowledgeBirthday']);
    });
});
