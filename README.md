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

## Example App

See the [example](example/) directory for a complete Flutter app demonstrating:
- Camera list with Ring authentication
- Live video streaming
- Snapshot viewer
- Camera controls (light, siren)
- Two-way audio support

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
- [Core Package](https://pub.dev/packages/ring_client_api)
- [WebRTC Options Guide](https://github.com/sjhorn/ring_client_api/blob/main/WEBRTC_OPTIONS.md)
- [TypeScript Differences](https://github.com/sjhorn/ring_client_api/blob/main/TYPESCRIPT_DIFFERENCES.md)

## Requirements

- Flutter 3.0 or later
- Dart 3.0 or later
- Platform-specific permissions (camera/microphone)

See full documentation for platform-specific setup instructions.

## License

MIT License - Copyright (c) 2025 Scott Horn

Based on the TypeScript [ring-client-api](https://github.com/dgreif/ring) by Dusty Greif.
