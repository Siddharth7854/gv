# Firebase FCM Token Setup Guide

## Current Status
- ✅ Mock FCM service working (for development)
- ⏳ Real Firebase integration ready (needs activation)

## Real FCM Token ke liye Setup Steps:

### 1. pubspec.yaml mein Firebase enable karo
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
```

### 2. main.dart mein Firebase initialize karo
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:gv/services/real_firebase_fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await RealFirebaseFCMService.initialize();
  runApp(MyApp());
}
```

### 3. Firebase Console Setup:
1. https://console.firebase.google.com/ par jao
2. New project banao: "GrievanceApp"
3. Android app add karo:
   - Package name: `com.government.grievance.gv`
   - google-services.json download karo
   - `android/app/` folder mein copy karo

### 4. Android Configuration:
**android/app/build.gradle:**
```gradle
apply plugin: 'com.google.gms.google-services'
```

**android/build.gradle:**
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

### 5. Real Token Get karo:
```dart
// Login screen mein ye button add karo:
onPressed: () async {
  await RealFirebaseFCMService.testRealFirebaseFCM();
}
```

### 6. Firebase Console Test:
1. Console > Cloud Messaging > "Send your first message"
2. Title: "Test Notification"
3. Body: "Firebase se aaya notification"
4. "Send test message" click karo
5. App se mila token paste karo
6. "Test" button press karo

## Current Mock vs Real Firebase:

| Feature | Mock Service | Real Firebase |
|---------|--------------|---------------|
| Token | Fake token | Real FCM token |
| Notifications | Local only | Push from server |
| Console Testing | ❌ | ✅ |
| Production Ready | ❌ | ✅ |

## Quick Test Commands:
```bash
# Mock notifications test (current)
flutter run -d windows --debug

# Real Firebase test (after setup)
flutter run -d android --debug
```

## Firebase Console Token Testing:
1. Token format: `fGHJ234KLM567...` (164 characters)
2. Copy from debug logs: "Real Firebase FCM Token"
3. Paste in Firebase Console test message
4. Send aur phone par notification check karo!

## Troubleshooting:
- Token null aa raha hai? → Firebase initialization check karo
- Notification nahi aa raha? → Permission check karo
- Android build fail? → google-services.json path check karo

Real FCM token sirf Android/iOS par milega, Windows par nahi!
