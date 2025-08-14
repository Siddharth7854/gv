# Grievance Update Fix Guide

## Issue Summary

After fixing the dropdown error, the admin panel encountered a 500 Internal Server Error when trying to update grievance status with progress photos. The error occurs because:

1. The Flutter client is sending requests to the wrong endpoint (`/grievances/:id/status` instead of `/grievances/:id/update-with-images`)
2. The server is not handling JSON-formatted image URLs properly

## Fix Implementation

The solution includes fixes for both client and server:

### Client Side Fix

1. Updated `updateGrievanceStatusWithImages` method in `admin_api_service.dart` to use the correct endpoint:

```dart
Future<Map<String, dynamic>> updateGrievanceStatusWithImages(
  String grievanceId,
  String newStatus,
  String? comments,
  List<String> imageUrls,
) async {
  try {
    // Use the correct endpoint for updating with images
    final url = Uri.parse(
      '$baseUrl/api/admin/grievances/$grievanceId/update-with-images',
    );
    final body = json.encode({
      'status': newStatus,
      'comments': comments,
      'progress_photos': imageUrls, // Include the progress photos
    });
    // ...
  }
}
```

### Server Side Fix

1. Added a new route handler in `admin.js` to properly process grievance updates with image URLs:

```javascript
// API route for updating grievance status with progress photos from JSON
router.put('/grievances/:id/update-with-images', authenticateAdmin, async (req, res) => {
  try {
    const dbService = req.app.get('dbService');  
    const { id } = req.params;
    const { status, comments, progress_photos } = req.body;
    const imageUrls = progress_photos || [];
    
    // Process update with image URLs
    // ...
    
    res.json({ 
      message: 'Grievance status updated successfully with images',
      // ...
    });
  } catch (error) {
    console.error('❌ Update grievance with images error:', error);
    res.status(500).json({ error: 'Failed to update grievance status' });
  }
});
```

## How to Apply the Fix

### Step 1: Update Flutter Code

1. Apply the client-side fix to `lib/services/admin_api_service.dart`:

```dart
// Update the endpoint URL from:
final url = Uri.parse('$baseUrl/api/admin/grievances/$grievanceId/status');

// To:
final url = Uri.parse('$baseUrl/api/admin/grievances/$grievanceId/update-with-images');
```

### Step 2: Update Server Code

1. Run the application script to add the new route handler:

```bash
cd d:\gv\api-server
node apply_grievance_update_fix.js
```

This script adds a new route handler to the `admin.js` file that properly processes JSON-formatted image URLs.

### Step 3: Test the Fix

1. Run the test script to verify the fix:

```bash
cd d:\gv\api-server
node test_grievance_update.js
```

This script tests updating a grievance with image URLs and verifies that the update was successful.

## Verification

After applying the fix:

1. Start the API server:

```bash
cd d:\gv\api-server
node server.js
```

2. Run the Flutter app:

```bash
cd d:\gv
flutter run
```

3. Login to the admin panel and try to update a grievance status with progress photos.

The update should now succeed without any errors.

## Common Issues

- If the update still fails, check the server logs for errors
- Make sure the client is sending the correct data format
- Verify that the grievance ID exists in the database
- Check that the image URLs are properly formatted

## Technical Details

The issue was caused by an endpoint mismatch between the client and server. The client was sending JSON data to the `/status` endpoint, which was designed to handle form data with actual file uploads. By adding a dedicated endpoint for JSON updates, we've fixed the issue without affecting existing functionality.
