# ring_camera

[![pub package](https://img.shields.io/pub/v/ring_camera.svg)](https://pub.dev/packages/ring_camera)

Flutter companion package for [ring_client_api](https://pub.dev/packages/ring_client_api) providing full WebRTC video streaming support for Ring cameras.

This package extends the core ring_client_api with Flutter-specific implementations including live video streaming, two-way audio, and easy-to-use camera viewer widgets.

## Features

- 📹 **Live Video Streaming** - Full WebRTC support with H.264 codec
- 🎤 **Two-Way Audio** - Optional return audio for communication with visitors
- 📱 **Cross-Platform** - Works on iOS, Android, Web, macOS, Windows, and Linux
- 🎨 **Ready-to-Use Widgets** - Drop-in camera viewer components
- 🔄 **Automatic Connection Management** - Handles WebRTC lifecycle automatically
- 📸 **Snapshot Viewer** - Alternative to streaming for battery-powered cameras
- ⚡ **Performance Optimized** - Efficient video rendering with flutter_webrtc

## Installation

Add both packages to your `pubspec.yaml`:

```yaml
dependencies:
  ring_client_api: ^0.1.0
  ring_camera: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Camera Viewer

```dart
import 'package:flutter/material.dart';
import 'package:ring_camera/ring_camera.dart';

class CameraPage extends StatelessWidget {
  final RingCamera camera;

  const CameraPage({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(camera.name)),
      body: RingCameraViewer(
        camera: camera,
        onError: (error) => print('Error: $error'),
      ),
    );
  }
}
```

### With Two-Way Audio

```dart
RingCameraViewer(
  camera: camera,
  enableReturnAudio: true,  // Enable microphone
  showStatus: true,          // Show connection status
)
```

### Snapshot Viewer (Battery-Friendly)

```dart
RingCameraSnapshotViewer(
  camera: camera,
  refreshInterval: Duration(seconds: 10),
)
```

## Examples

The package includes three examples demonstrating different use cases:

### Simple Examples
- **[simple_live_stream](example/simple_live_stream/)** - Minimal (~130 lines) live streaming example
- **[simple_snapshot](example/simple_snapshot/)** - Minimal (~130 lines) snapshot viewer example

### Full Example
- **[camera_viewer](example/camera_viewer/)** - Complete app with camera list, live streaming, snapshots, and controls

Each example includes its own README with setup instructions.

## Logging

The package uses the `logging` package for internal diagnostics. By default, only INFO level and above messages are logged. To enable debug logging:

```dart
import 'package:logging/logging.dart';

// Enable debug logging
Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) {
  print('${record.level.name}: ${record.time}: ${record.message}');
});
```

For production apps, the default INFO level is recommended.

## Documentation

- [API Reference](https://pub.dev/documentation/ring_camera/latest/)
- [Core Package (ring_client_api)](https://pub.dev/packages/ring_client_api)
- [Example Apps](example/) - Three examples showing different use cases
- [Platform Configuration](#platform-configuration) - Setup for macOS, iOS, and other platforms

## Platform Configuration

### macOS

Add network entitlements to both Debug and Release configurations:

**`macos/Runner/DebugProfile.entitlements`**
```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

**`macos/Runner/Release.entitlements`**
```xml
<key>com.apple.security.network.client</key>
<true/>
```

If using two-way audio, also add microphone permission:
```xml
<key>com.apple.security.device.audio-input</key>
<true/>
```

### iOS

Add camera and microphone permissions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to display Ring camera video streams.</string>

<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to send audio during Ring camera calls.</string>
```

### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Permissions for Ring camera streaming -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

**Note:** The camera feature is marked as `required="false"` so the app can still be installed on devices without a camera (since you're viewing Ring cameras, not using the device's camera).

### Web, Windows, Linux

These platforms work out of the box with no additional configuration required.

## Requirements

- Flutter 3.0 or later
- Dart 3.0 or later
- ring_client_api ^0.1.0
- flutter_webrtc ^1.2.0

## License

MIT License - Copyright (c) 2025 Scott Horn

Based on the TypeScript [ring-client-api](https://github.com/dgreif/ring) by Dusty Greif.
