# ring_camera_example

Example Flutter app demonstrating the use of `ring_camera` for Ring camera streaming.

## Features

This example demonstrates:

- 📝 Authentication with Ring refresh token
- 📋 Listing all Ring cameras
- 📹 Live video streaming with WebRTC
- 📸 Snapshot viewer for battery-powered cameras
- 🎤 Two-way audio (microphone toggle)
- 💡 Camera light control
- 🔔 Siren control
- ℹ️ Camera information display

## Prerequisites

Before running this example, you need:

1. **A Ring account** with at least one camera
2. **A refresh token** - Obtain using the CLI tool from the core package

### Getting a Refresh Token

From the `ring_client_api` package directory:

```bash
cd /path/to/ring_client_api
dart run bin/ring_auth_cli.dart
```

Follow the prompts to enter your Ring credentials and 2FA code. Save the refresh token securely.

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Platform-Specific Setup

#### iOS

Add camera and microphone permissions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access for two-way communication with Ring devices</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access for two-way audio with Ring devices</string>
```

#### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />

<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

#### macOS

Add entitlements to `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.device.camera</key>
<true/>
<key>com.apple.security.device.audio-input</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

#### Web

WebRTC is supported on web browsers. No additional setup required.

## Running the App

```bash
flutter run
```

Or select your target device in your IDE and run.

## Using the App

### 1. Enter Refresh Token

On the main screen:
1. Paste your Ring refresh token into the text field
2. Tap "Load Cameras"
3. Wait for your cameras to load

### 2. View Cameras

Once loaded, you'll see a list of all your Ring cameras. Each camera card shows:
- Camera name
- Camera ID
- Features (light, siren)
- Type (doorbell or camera)

### 3. Open Camera Viewer

Tap the menu button (⋮) on any camera to choose:

- **Live Stream** - WebRTC real-time video streaming
  - High quality video
  - Low latency
  - Two-way audio support
  - Connection status indicator

- **Snapshots** - Periodic still images
  - Battery friendly
  - Refreshes every 10 seconds
  - Best for battery-powered cameras

### 4. Camera Controls

In the camera viewer, you can:

- **Toggle Microphone** (streaming mode) - Tap the microphone icon in the app bar
- **Toggle Light** - If camera has a light
- **Toggle Siren** - If camera has a siren
- **Get Snapshot** - Fetch and display a still image

## Troubleshooting

### "Failed to load cameras"

- Verify your refresh token is correct and not expired
- Check your internet connection
- Ensure your Ring account is active

### "WebRTC streaming not implemented"

This is expected - full WebRTC implementation requires:
1. Completing the WebRTC signaling with Ring's servers
2. Handling ICE candidates
3. SIP session management

The example shows the UI structure; actual streaming requires the backend implementation mentioned in the main package's `WEBRTC_OPTIONS.md`.

### Permission Errors

- iOS/Android: Ensure camera/microphone permissions are granted
- Check platform-specific setup steps above
- Try uninstalling and reinstalling the app

### Camera Not Connecting

- Some cameras may require specific network configurations
- Battery-powered cameras may be in power-saving mode
- Try using snapshot mode instead

## Code Structure

```
lib/
├── main.dart                 # App entry point and camera list
└── camera_viewer_page.dart   # Camera viewer with streaming/snapshot modes
```

### Key Files

- **main.dart**:
  - Initializes RingApi with refresh token
  - Displays list of available cameras
  - Handles token refresh events

- **camera_viewer_page.dart**:
  - Shows live stream or snapshots
  - Camera control buttons
  - Error handling and status display

## Security Notes

⚠️ **Important**: Never commit your refresh token to version control!

In a production app:
- Store refresh token in secure storage (e.g., `flutter_secure_storage`)
- Implement proper authentication UI
- Handle token expiration gracefully
- Monitor for token refresh events

## Learn More

- [ring_client_api_flutter Documentation](https://pub.dev/packages/ring_client_api_flutter)
- [ring_client_api Core Package](https://pub.dev/packages/ring_client_api)
- [WebRTC Options Guide](https://github.com/sjhorn/ring_client_api/blob/main/WEBRTC_OPTIONS.md)
- [TypeScript Differences](https://github.com/sjhorn/ring_client_api/blob/main/TYPESCRIPT_DIFFERENCES.md)

## Support

For issues, questions, or contributions:
- [GitHub Issues](https://github.com/sjhorn/ring_client_api/issues)
- [Package Repository](https://github.com/sjhorn/ring_client_api)
