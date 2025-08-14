# Android FCM Notification Debugging Guide

## आपकी समस्या: FCM token paste करने पर notification नहीं आ रहा

### Step 1: FCM Test App Run करें
```bash
# Android device connect करें
# USB Debugging enable करें  
# App run करें Android पर (Windows नहीं)
```

### Step 2: FCM Test Screen Access करें
1. App में login screen खोलें
2. "FCM Comprehensive Test" button click करें
3. यह एक dedicated test screen खोलेगा

### Step 3: Token Generate और Copy करें
1. Screen पर FCM token दिखेगा
2. Token को copy करें (long press और select all)
3. यह token unique है आपके device के लिए

### Step 4: Notification Channels Check करें
Android में जाएं:
```
Settings → Apps → Your App Name → Notifications
- All channels should be enabled
- Importance should be "High" or "Medium"
```

### Step 5: Test Notification Send करें

#### Option A: Firebase Console
1. Firebase Console → Cloud Messaging
2. "Send your first message" click करें
3. FCM token paste करें
4. Title/Body add करें
5. Send करें

#### Option B: API Call (Postman/curl)
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "यह test notification है!"
    },
    "data": {
      "test": "true"
    }
  }'
```

### Step 6: Expected Results

#### App Foreground में है:
- ✅ Console में logs दिखेंगे
- ✅ Local notification popup 
- ✅ Test screen पर "Last Notification" update होगा

#### App Background में है:
- ✅ Android notification bar में notification
- ✅ Notification sound/vibration
- ✅ Tap करने पर app open होगा

#### App Terminated है:
- ✅ System notification आएगा
- ✅ Tap करने पर app launch होगा

### Debugging Commands

```bash
# Android logs check करें
adb logcat | grep -E "(FCM|Firebase|Notification)"

# App logs specifically  
adb logcat | grep "flutter"

# Network connectivity
adb shell ping google.com
```

### Common Issues और Solutions

#### 1. Token Generate नहीं हो रहा
```dart
// Check Firebase initialization
await Firebase.initializeApp();
String? token = await FirebaseMessaging.instance.getToken();
```

#### 2. Permission Denied
```dart
NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
if (settings.authorizationStatus != AuthorizationStatus.authorized) {
  // Permission नहीं मिली
}
```

#### 3. Server Key Invalid
- Firebase Console → Project Settings → Cloud Messaging
- Server key copy करें correctly

#### 4. Notification Channel Missing
```dart
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'test_channel',
  'Test Notifications',
  importance: Importance.high,
);
```

### Debug Console Output

देखने के लिए logs:
```
✅ Firebase initialized successfully
✅ FCM Permission: AuthorizationStatus.authorized  
✅ FCM Token: f1234567890abcdef...
✅ Android notification channel created
📨 Foreground message received: Test Title
📱 Local notification shown
```

### Testing Checklist

- [ ] Android device connected
- [ ] App running on Android (not Windows/Web)
- [ ] Internet connection working
- [ ] Firebase project setup correct
- [ ] google-services.json file present
- [ ] FCM dependencies added
- [ ] Notification permissions granted
- [ ] Valid FCM token generated
- [ ] Correct server key used
- [ ] Test notification sent
- [ ] Expected behavior observed

### Final Verification

1. **Generate Token**: App में test screen से
2. **Copy Token**: Complete token copy करें
3. **Send Test**: Firebase Console या API से
4. **Check Results**: 
   - Foreground: Local popup
   - Background: System notification
   - Logs: Console output

आप कौन सा step try कर रहे हैं और कहाँ issue आ रहा है?
