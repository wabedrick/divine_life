<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class FilesController extends Controller
{
    /**
     * Handle file uploads and return a public URL
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'file' => 'required|file|max:20480', // max 20MB
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $file = $request->file('file');

        if (!$file->isValid()) {
            return response()->json([
                'success' => false,
                'message' => 'Uploaded file is not valid',
            ], 400);
        }

        // Store file on the public disk inside uploads/
        $path = $file->store('uploads', 'public');

    // Build a publicly accessible URL
    // Storage::url returns a path like /storage/uploads/..., convert to absolute URL
    $relativeUrl = Storage::url($path);
    $url = url($relativeUrl);

        return response()->json([
            'success' => true,
            'data' => [
                'url' => $url,
                'file_url' => $url,
                'file_name' => $file->getClientOriginalName(),
                'file_size' => $file->getSize(),
                'path' => $path,
            ],
            // top-level url / file_url for clients that look for it
            'url' => $url,
            'file_url' => $url,
            'file_name' => $file->getClientOriginalName(),
            'file_size' => $file->getSize(),
        ]);
    }
}
