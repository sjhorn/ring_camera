/// Flutter widgets for Ring camera streaming
///
/// Provides full WebRTC streaming support for Ring cameras using flutter_webrtc.
///
/// This package extends the core ring_client_api package with Flutter-specific
/// implementations for camera video streaming, including:
/// - WebRTC peer connection using flutter_webrtc
/// - Camera viewer widgets
/// - Audio/video rendering
/// - Connection state management
///
/// ## Usage
///
/// ```dart
/// import 'package:ring_client_api/ring_client_api.dart';
/// import 'package:ring_camera/ring_camera.dart';
///
/// // In your Flutter widget
/// RingCameraViewer(
///   camera: ringCamera,
///   onError: (error) => print('Error: $error'),
/// )
/// ```
///
/// ## Features
///
/// - **Full WebRTC Support**: Live video streaming with H.264 codec
/// - **Two-way Audio**: Optional return audio for communication
/// - **Easy Integration**: Drop-in widgets for camera viewing
/// - **Connection Management**: Automatic connection handling and recovery
/// - **Snapshot Viewer**: Alternative to streaming for battery-powered cameras
///
/// ## Requirements
///
/// - Flutter 3.0 or later
/// - ring_client_api ^0.1.0
/// - flutter_webrtc ^0.11.0
///
/// See README.md for complete documentation and examples.
library;

// Core streaming implementation
export 'src/flutter_peer_connection.dart';
export 'src/webrtc_connection.dart';

// Widgets
export 'src/ring_camera_viewer.dart';

// Re-export core ring_client_api for convenience
export 'package:ring_client_api/ring_client_api.dart';
