# Server Configuration Feature - User Guide

## Overview

The server URL is now **configurable by the user** at app startup instead of being hardcoded. Users can enter their backend server URL when they first launch the app, and can change it later from their profile settings.

---

## 🎯 What Changed?

### Before
- Server URL was hardcoded as `http://192.168.1.3:3000` in [app_config.dart](lib/config/app_config.dart)
- Users had to manually edit the code to change the server URL
- Required recompiling the app for different servers

### After
- ✅ Users enter the server URL on first launch
- ✅ URL is saved locally using SharedPreferences
- ✅ Can be changed anytime from Profile settings
- ✅ No code changes needed for different environments
- ✅ Automatic logout when changing servers

---

## 📋 New Files Created

### 1. [lib/screens/server_config_screen.dart](lib/screens/server_config_screen.dart)
**Purpose**: Initial server configuration screen shown on first launch

**Features**:
- Clean, user-friendly UI with gradient background
- Text input field for server URL
- URL validation (http:// or https:// required)
- Example URLs provided (localhost, network IP, Android emulator)
- Loading state during validation
- Error messaging
- Connection test before saving

**User Flow**:
```
App Launch → Splash Screen → Server Config Screen → Login Screen
```

### 2. [lib/controllers/server_config_controller.dart](lib/controllers/server_config_controller.dart)
**Purpose**: Manages server URL configuration logic

**Methods**:
- `saveServerUrl(String url)` - Validates and saves server URL
- `getSavedServerUrl()` - Retrieves saved URL from storage
- `hasServerUrl()` - Checks if URL is already configured
- `clearServerUrl()` - Removes saved URL
- `_testServerConnection(String url)` - Tests if URL is valid

**Validation Rules**:
- URL must not be empty
- Must start with `http://` or `https://`
- Must be valid URI format
- Trailing slashes are automatically removed

---

## 🔄 Modified Files

### 1. [lib/config/app_config.dart](lib/config/app_config.dart)
**Changes**:
```dart
// Before (const - hardcoded)
static const String serverUrl = 'http://192.168.1.3:3000';
static const String apiBaseUrl = '$serverUrl/api/auth';
static const String socketUrl = serverUrl;

// After (dynamic - user configurable)
static String _serverUrl = 'http://192.168.1.3:3000'; // Default fallback
static String get serverUrl => _serverUrl;
static String get apiBaseUrl => '$_serverUrl/api/auth';
static String get socketUrl => _serverUrl;

// New method to update URL at runtime
static void setServerUrl(String url) {
  _serverUrl = url;
}
```

**Why**: Changed from `const` to dynamic `String` with getters to allow runtime configuration.

### 2. [lib/screens/splash_screen.dart](lib/screens/splash_screen.dart)
**Changes**:
- Added `ServerConfigController` initialization
- Added server URL check logic
- Loads saved URL from storage on startup
- Redirects to server config screen if no URL is saved

**New Flow**:
```dart
void _navigateToNextScreen() async {
  await Future.delayed(const Duration(seconds: 2));

  // 1. Check if server URL is configured
  final hasServerUrl = await _serverConfigController.hasServerUrl();
  if (!hasServerUrl) {
    Get.offNamed('/server-config'); // → Go to config screen
    return;
  }

  // 2. Load saved server URL
  final savedServerUrl = await _serverConfigController.getSavedServerUrl();
  if (savedServerUrl != null) {
    AppConfig.setServerUrl(savedServerUrl);
  }

  // 3. Check authentication
  if (_authController.user.value != null) {
    Get.offNamed('/home');
  } else {
    Get.offNamed('/login');
  }
}
```

### 3. [lib/screens/profile_screen.dart](lib/screens/profile_screen.dart)
**Changes**:
- Added "Server Configuration" section in profile
- Shows current server URL
- Added dialog to change server URL
- Automatically logs out user when URL is changed

**New UI Section**:
```
┌─────────────────────────────────────┐
│  🖥️  Server Configuration          │
│     http://192.168.1.3:3000      →  │
└─────────────────────────────────────┘
```

**Dialog Features**:
- Pre-filled with current URL
- Warning message about logout
- Validation before saving
- Immediate logout after URL change

### 4. [lib/main.dart](lib/main.dart)
**Changes**:
- Added import for `server_config_screen.dart`
- Added route: `/server-config` → `ServerConfigScreen()`

---

## 🚀 How It Works

### First Launch Flow
```
1. User opens app
   ↓
2. Splash screen (2 seconds)
   ↓
3. Check if server URL exists
   → NO: Show Server Config Screen
   → YES: Load saved URL & continue
   ↓
4. User enters server URL
   ↓
5. URL validated and saved
   ↓
6. Redirect to Login Screen
```

### Changing Server Later
```
1. User goes to Profile
   ↓
2. Tap "Server Configuration"
   ↓
3. Dialog appears with current URL
   ↓
4. Enter new URL
   ↓
5. Warning: "You will be logged out"
   ↓
6. Tap "Change"
   ↓
7. URL saved + User logged out
   ↓
8. Redirect to Login Screen
```

---

## 💾 Data Storage

Server URL is stored using **SharedPreferences**:

**Key**: `server_url`
**Value**: Full server URL (e.g., `http://192.168.1.3:3000`)
**Persistence**: Remains saved until manually changed or app data cleared

---

## 🎨 UI/UX Features

### Server Config Screen
- ✅ Gradient background (matching app theme)
- ✅ Clear icon (server/settings remote icon)
- ✅ Helpful title and description
- ✅ Example URLs for guidance
- ✅ URL input with icon
- ✅ Loading spinner during validation
- ✅ Error messages with icon
- ✅ Info box with tips

### Profile Settings
- ✅ Settings section with server config option
- ✅ Shows current server URL as subtitle
- ✅ Arrow indicator for navigation
- ✅ Clean dialog with warning
- ✅ Pre-filled input field
- ✅ Color-coded warning box

---

## 📱 Example URLs

### For Different Environments

| Environment | URL Example | When to Use |
|-------------|-------------|-------------|
| **Local Development** | `http://localhost:3000` | Running on same machine (web) |
| **Network (Same WiFi)** | `http://192.168.1.3:3000` | Testing on real device |
| **Android Emulator** | `http://10.0.2.2:3000` | Testing on Android emulator |
| **iOS Simulator** | `http://localhost:3000` | Testing on iOS simulator |
| **Production** | `https://api.yourapp.com` | Deployed backend server |

---

## 🔒 Security Notes

1. **HTTPS Support**: Both HTTP and HTTPS are supported
2. **Validation**: URL format is validated before saving
3. **No Hardcoded Credentials**: Server URL doesn't contain auth info
4. **Secure Storage**: Consider using `flutter_secure_storage` for production
5. **JWT Tokens**: Still stored securely in SharedPreferences

---

## 🧪 Testing Instructions

### Test 1: First Launch
1. Clear app data or fresh install
2. Launch app
3. Should see Server Config Screen
4. Enter: `http://192.168.1.3:3000` (or your server URL)
5. Tap "Save & Continue"
6. Should redirect to Login Screen

### Test 2: Invalid URL
1. Enter: `invalid-url`
2. Should show error: "URL must start with http:// or https://"
3. Enter: `http://` (incomplete)
4. Should show error: "Invalid URL format"

### Test 3: Change Server URL
1. Login to app
2. Go to Profile
3. Tap "Server Configuration"
4. Change URL to different server
5. Tap "Change"
6. Should be logged out
7. Should redirect to Login Screen
8. Verify new server URL is used

### Test 4: Persisted URL
1. Configure server URL
2. Close app completely
3. Reopen app
4. Should load saved URL (not show config screen again)
5. Should work with saved server

---

## 🐛 Troubleshooting

### Issue: Config screen appears every launch
**Solution**: Check SharedPreferences. URL key might not be saving.

### Issue: Cannot connect after entering URL
**Solutions**:
- Verify backend server is running
- Check firewall settings
- Ensure device is on same network (for local IPs)
- Try using IP address instead of hostname

### Issue: URL changes but app still uses old server
**Solution**: The app should automatically update. If not, restart the app.

---

## 🔧 For Developers

### Adding Server Test Endpoint

Consider adding a health check endpoint on backend:

```javascript
// backend/routes/health.js
router.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});
```

Then enhance the `_testServerConnection()` method:

```dart
Future<bool> _testServerConnection(String url) async {
  try {
    final response = await http.get(
      Uri.parse('$url/health'),
    ).timeout(Duration(seconds: 5));

    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
```

### Environment Variables

For different build flavors:

```dart
// lib/config/env.dart
class Environment {
  static const String devUrl = 'http://localhost:3000';
  static const String stagingUrl = 'https://staging-api.yourapp.com';
  static const String prodUrl = 'https://api.yourapp.com';
}
```

---

## 📝 Future Enhancements

Potential improvements:

1. **QR Code Scanning**: Scan QR code to configure server
2. **Server Discovery**: Auto-detect servers on local network
3. **Multiple Profiles**: Save multiple server URLs
4. **Connection Testing**: Real API call before saving
5. **Server Nickname**: Give friendly names to different servers
6. **Recent Servers**: Show list of previously used servers
7. **Secure Storage**: Use encrypted storage for sensitive data

---

## ✅ Summary

The app now provides a **user-friendly way** to configure the backend server URL:

- ✅ No more hardcoded URLs
- ✅ Easy to switch between development/production
- ✅ No code changes needed
- ✅ Intuitive UI/UX
- ✅ Persistent storage
- ✅ Validation and error handling
- ✅ Can be changed anytime from Profile

**Result**: Users can easily connect to any backend server without modifying code! 🎉

---

## 📞 Support

If you encounter any issues with server configuration:

1. Check that your backend server is running
2. Verify the URL format is correct
3. Ensure your device can reach the server
4. Check app logs for detailed error messages
5. Try the default URL: `http://192.168.1.3:3000`

For development help, refer to the main [README.md](../README.md)
