# Firebase Cloud Messaging (FCM) Real Setup Guide

## 🚀 Complete FCM Integration Steps

### Step 1: Firebase Console Setup
1. Go to https://console.firebase.google.com/
2. Create new project: "Government Portal"
3. Enable Cloud Messaging

### Step 2: Android App Registration
1. Add Android app in Firebase Console
2. Package name: `com.example.gv` (from your android/app/build.gradle)
3. Download `google-services.json`
4. Place in `android/app/` folder

### Step 3: Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
```

### Step 4: Android Configuration
Add to `android/app/build.gradle`:
```gradle
plugins {
    id 'com.google.gms.google-services'
}
```

Add to `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

### Step 5: Real FCM Token
Replace mock token with:
```dart
final token = await FirebaseMessaging.instance.getToken();
```

### Step 6: Online Testing
Use Firebase Console > Cloud Messaging to send test notifications

## 🎯 Current Status
✅ Local notifications working (Windows Toast)
⚠️ Need Firebase setup for online FCM
⚠️ Need real FCM token for cloud messaging

## 🔄 Next Actions
1. Firebase project creation
2. google-services.json download
3. Real FCM token generation
4. Online notification testing
