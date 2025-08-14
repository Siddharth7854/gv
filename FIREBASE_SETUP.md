# Firebase Configuration Guide

## Setup Instructions

### 1. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing project
3. Navigate to Project Settings > General
4. Add Android app:
   - Package name: `com.government.grievance.gv`
   - Download `google-services.json`
5. Add iOS app (if needed):
   - Bundle ID: `com.government.grievance.gv`
   - Download `GoogleService-Info.plist`

### 2. Android Configuration

1. Place `google-services.json` in `android/app/` directory

2. Add to `android/build.gradle.kts` (Root-level project-level Gradle file):

```kotlin
plugins {
    // Add the dependency for the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.3" apply false
}
```

3. Add to `android/app/build.gradle.kts` (Module app-level Gradle file):

```kotlin
plugins {
    id("com.android.application")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
    // ... existing plugins
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))

    // Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")

    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
}
```

### 3. iOS Configuration (if needed)

1. Place `GoogleService-Info.plist` in `ios/Runner/`
2. Add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### 4. Firebase Admin SDK (Backend)

1. Go to Firebase Console > Project Settings > Service Accounts
2. Generate new private key (downloads JSON file)
3. Save as `firebase-service-account.json` in your backend root
4. Add to your `.env`:

```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY_ID=your-private-key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=your-client-id
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
```

### 5. Backend Dependencies

Add to your `package.json`:

```json
{
  "dependencies": {
    "firebase-admin": "^11.11.0"
  }
}
```

### 6. Environment Variables Example

Create `.env` file in backend:

```env
# Database
DB_SERVER=localhost
DB_NAME=GrievanceDB
DB_USER=your_username
DB_PASSWORD=your_password

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY_ID=your-private-key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour private key here\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=your-client-id

# Server
PORT=5000
NODE_ENV=development
```

### 7. Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />

<!-- Add inside <application> tag -->
<service
    android:name="com.google.firebase.messaging.FirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>

<!-- Notification icon -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />

<!-- Notification color -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />

<!-- Notification channel -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="grievance_notifications" />
```

### 8. Testing Push Notifications

#### From Firebase Console:

1. Go to Firebase Console > Cloud Messaging
2. Click "Send your first message"
3. Enter title and text
4. Select your app
5. Send test message

#### From Backend API:

```bash
# Update FCM token
curl -X POST http://localhost:5000/api/auth/fcm-token \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "fcm_token": "your_fcm_token_here",
    "platform": "flutter"
  }'

# Send notification via backend
curl -X POST http://localhost:5000/api/notifications/send \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -d '{
    "user_id": 1,
    "notification": {
      "title": "Test Notification",
      "body": "This is a test notification",
      "data": {
        "type": "grievance_status",
        "grievance_id": "123"
      }
    }
  }'
```

### 9. Common Issues & Solutions

#### "Firebase not initialized"

- Make sure `google-services.json` is in correct location
- Check that Firebase dependencies are added correctly

#### "Token not received"

- Check internet connection
- Verify app is in foreground for initial token generation
- Check device date/time settings

#### "Notifications not showing"

- Verify notification permissions are granted
- Check notification channels are created
- Test with Firebase Console first

### 10. Production Checklist

- [ ] Firebase project configured for production
- [ ] Service account key secured (not in source control)
- [ ] Environment variables properly set
- [ ] Database tables created
- [ ] Android app signing configured
- [ ] iOS certificates configured (if applicable)
- [ ] Rate limiting configured for notification endpoints
- [ ] Error handling and logging implemented
- [ ] User consent for notifications obtained
- [ ] Unsubscribe mechanism implemented

### 11. Monitoring & Analytics

1. Enable Firebase Analytics for notification tracking
2. Set up custom events for notification interactions
3. Monitor delivery rates and user engagement
4. Set up alerts for failed deliveries

### 12. Security Best Practices

- Store service account keys securely
- Implement rate limiting for notification sends
- Validate user permissions before sending notifications
- Log notification activities for audit
- Implement user preferences for notification types
- Use HTTPS for all API communications
