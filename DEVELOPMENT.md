# ring_camera Development Guide

## Project Overview

This is the Flutter companion package for **ring_client_api**, providing full WebRTC video streaming support for Ring cameras.

### Package Purpose

- Extends the pure Dart `ring_client_api` with Flutter-specific WebRTC implementation
- Uses `flutter_webrtc` for native platform support (iOS, Android, Web, macOS, Windows, Linux)
- Provides ready-to-use widgets for camera viewing
- Handles WebRTC peer connections, ICE candidates, and media streams

## Architecture

### Two-Package Design

This package is part of a two-package architecture:

1. **ring_client_api** (core) - Pure Dart package
   - REST API client
   - WebSocket connections
   - Device models (cameras, chimes, intercoms)
   - Location management
   - Interface definitions for streaming

2. **ring_camera** (this package) - Flutter companion
   - WebRTC implementation using flutter_webrtc
   - Camera viewer widgets
   - Platform-specific features

### Why This Architecture?

The core `ring_client_api` package is pure Dart with no Flutter dependencies, making it:
- Usable in command-line tools
- Usable in web apps (with dart_webrtc)
- Testable without Flutter framework
- Lighter weight for non-GUI applications

The TypeScript version uses `werift`, a pure JavaScript WebRTC library. Dart doesn't have an equivalent pure Dart WebRTC implementation, so we use Flutter's flutter_webrtc for full platform support.

## Project Structure

```
ring_camera/
├── lib/
│   ├── ring_camera.dart      # Main library export
│   └── src/
│       ├── flutter_peer_connection.dart   # WebRTC implementation
│       └── ring_camera_viewer.dart        # UI widgets
├── example/
│   ├── lib/
│   │   ├── main.dart                      # Camera list app
│   │   └── camera_viewer_page.dart        # Camera viewer with controls
│   └── pubspec.yaml
├── test/
│   └── ring_camera_test.dart
├── README.md
├── CHANGELOG.md
├── DEVELOPMENT.md (this file)
└── pubspec.yaml
```

## Key Components

### FlutterPeerConnection

**File**: `lib/src/flutter_peer_connection.dart`

Implements the `BasicPeerConnection` interface from ring_client_api using flutter_webrtc.

**Features:**
- ICE candidate handling
- STUN/TURN server configuration (uses Ring's ICE servers)
- Codec support: H.264 (video), Opus/PCMU (audio)
- Two-way audio with echo cancellation, noise suppression, auto-gain
- Connection state management
- Transceiver setup (sendrecv audio, recvonly video)

**Key Methods:**
- `createOffer()` - Creates WebRTC offer
- `acceptAnswer()` - Handles SDP answer from Ring servers
- `addIceCandidate()` - Adds ICE candidates
- `setupReturnAudio()` - Enables microphone for two-way communication
- `close()` - Cleanup

**Streams:**
- `onIceCandidate` - Emits ICE candidates as they're discovered
- `onConnectionState` - Emits connection state changes
- `onRemoteStream` - Emits remote media stream from camera

### RingCameraViewer Widget

**File**: `lib/src/ring_camera_viewer.dart`

Stateful widget for displaying live camera streams.

**Features:**
- Full WebRTC lifecycle management
- Connection status overlay
- Error handling with callbacks
- Two-way audio toggle
- Automatic cleanup on dispose

**Properties:**
- `camera` - RingCamera instance
- `enableReturnAudio` - Enable microphone
- `showStatus` - Show connection status overlay
- `onError` - Error callback
- `onConnectionStateChanged` - State change callback

**Current Status**:
The widget provides the UI structure and WebRTC peer connection setup. Full integration with Ring's WebRTC signaling requires implementing the WebrtcConnection class from the core package, which handles:
1. Creating WebRTC session ticket with camera
2. Sending offer via WebSocket
3. Receiving answer and ICE candidates from Ring servers
4. Completing WebRTC handshake

### RingCameraSnapshotViewer Widget

**File**: `lib/src/ring_camera_viewer.dart`

Alternative to streaming for battery-powered cameras.

**Features:**
- Periodic snapshot refresh
- Battery-friendly (no continuous streaming)
- Configurable refresh interval
- Error handling with retry

## Dependencies

### Production Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  ring_client_api: ^0.1.0        # Core Ring API
  flutter_webrtc: ^0.11.7        # WebRTC support
  rxdart: ^0.28.0                # Reactive streams
  logging: ^1.2.0                # Logging
```

### Development Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.13
```

## Local Development Setup

### 1. Clone Both Repositories

```bash
cd ~/dev/dart
git clone https://github.com/sjhorn/ring_client_api.git
git clone https://github.com/sjhorn/ring_camera.git
```

### 2. Use Path Dependency for Development

In `pubspec.yaml`, use path dependency:

```yaml
dependencies:
  ring_client_api:
    path: ../ring_client_api  # Local development
```

### 3. Get Dependencies

```bash
flutter pub get
```

### 4. Run Example App

```bash
cd example
flutter run
```

## WebRTC Architecture

### Connection Flow

The complete WebRTC streaming process:

```
1. User opens RingCameraViewer widget
   ↓
2. Widget requests ticket: camera.createWebrtcTicket()
   → REST API: POST /clap/ticket/request/signalsocket
   → Returns: SocketTicketResponse with auth ticket
   ↓
3. Create FlutterWebrtcConnection(ticket, camera, peerConnection)
   ↓
4. WebSocket connects to Ring's signaling server:
   wss://api.prod.signalling.ring.devices.a2z.com:443/ws
   ?api_version=4.0
   &auth_type=ring_solutions
   &client_id=ring_site-{dialogId}
   &token={ticket}
   ↓
5. Send SDP offer via 'live_view' message:
   {
     "method": "live_view",
     "dialog_id": "{dialogId}",
     "body": {
       "doorbot_id": {cameraId},
       "stream_options": {"audio_enabled": true, "video_enabled": true},
       "sdp": "{offerSdp}"
     }
   }
   ↓
6. Receive signaling messages:
   - session_created: Get session_id for subsequent messages
   - sdp (answer): Accept remote SDP answer
   - ice: Add remote ICE candidates
   - camera_started: Camera is ready to stream
   ↓
7. Send local ICE candidates as discovered
   ↓
8. Maintain connection health:
   - Send 'ping' message every 5 seconds
   - Receive 'pong' response
   ↓
9. WebRTC peer connection establishes media path
   ↓
10. H.264 video stream displays in RTCVideoView widget
```

### Signaling Protocol

**Outgoing Messages:**
- `live_view` - Initial SDP offer to start streaming
- `ice` - Local ICE candidates for NAT traversal
- `ping` - Keep-alive messages (every 5 seconds)
- `activate_session` - Activate the streaming session
- `stream_options` - Configure audio/video preferences
- `activate_camera_speaker` - Enable two-way audio communication

**Incoming Messages:**
- `session_created` - Session established, provides session_id
- `sdp` - SDP answer from camera
- `ice` - Remote ICE candidates
- `camera_started` - Camera successfully connected
- `pong` - Ping response (connection alive)
- `notification` - Status updates from Ring servers
- `stream_info` - Stream metadata (transcoding info)
- `close` - Connection closed by server

### FlutterWebrtcConnection

**File**: `lib/src/webrtc_connection.dart` (398 lines)

Core WebRTC signaling implementation that manages the complete lifecycle:
- WebSocket connection to Ring's signaling server
- SDP offer/answer exchange
- Bidirectional ICE candidate handling
- Session management with periodic health checks
- Error handling and cleanup
- Two-way audio activation

**Key Methods:**
- `_connectWebSocket()` - Establishes signaling connection with required User-Agent header
- `_initiateCall()` - Creates and sends SDP offer
- `_handleWebSocketMessage()` - Processes all signaling messages
- `_handleAnswer()` - Accepts SDP answer from Ring
- `_handleIceCandidate()` - Processes remote ICE candidates
- `_sendIceCandidate()` - Sends local ICE candidates
- `_activate()` - Activates session (sends two required messages)
- `requestKeyFrame()` - Requests video key frame
- `activateCameraSpeaker()` - Enables two-way audio
- `stop()` - Gracefully closes connection

## WebRTC Implementation Details

### Codec Configuration

**Video**: H.264 codec required by Ring cameras
- Hardware accelerated on most platforms
- Configured via flutter_webrtc transceiver

**Audio**:
- Opus (48kHz, 2 channels) - High quality
- PCMU (8kHz, 1 channel) - Fallback

### ICE Configuration

Ring uses specific STUN servers defined in `ringIceServers`:
- stun:stun.kinesisvideo.us-east-1.amazonaws.com:443
- stun:stun.kinesisvideo.us-west-2.amazonaws.com:443

Configuration in peer connection:
```dart
final configuration = {
  'iceServers': ringIceServers.map((s) => {'urls': s}).toList(),
  'iceTransportPolicy': 'all',
  'bundlePolicy': 'max-bundle',
  'rtcpMuxPolicy': 'require',
};
```

### Transceiver Setup

```dart
// Audio: sendrecv for two-way communication
await _pc.addTransceiver(
  kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
  init: RTCRtpTransceiverInit(
    direction: TransceiverDirection.SendRecv,
  ),
);

// Video: recvonly (we only receive video from camera)
await _pc.addTransceiver(
  kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
  init: RTCRtpTransceiverInit(
    direction: TransceiverDirection.RecvOnly,
  ),
);
```

## Platform-Specific Setup

### iOS

Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access for two-way communication</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access for two-way audio</string>
```

### Android

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### macOS

Add to entitlements files:
```xml
<key>com.apple.security.device.camera</key>
<true/>
<key>com.apple.security.device.audio-input</key>
<true/>
```

### Web

No additional setup required - uses browser WebRTC.

## Testing

### Unit Tests

```bash
flutter test
```

Current tests verify:
- Core package exports are accessible
- Flutter-specific classes are exported
- Package structure

### Testing with Real Devices

1. Get a refresh token using core package CLI:
```bash
cd ../ring_client_api
dart run bin/ring_auth_cli.dart
```

2. Run example app:
```bash
cd example
flutter run
```

3. Enter refresh token and select a camera

## Differences from TypeScript Implementation

### TypeScript (werift)

The TypeScript version uses `werift`, a pure JavaScript WebRTC library:
- Runs in Node.js
- Full control over RTP packets
- Custom codec implementation
- Synchronous peer connection creation

### Dart/Flutter (flutter_webrtc)

This implementation uses flutter_webrtc:
- Wraps native platform WebRTC (Google's libwebrtc)
- Hardware acceleration support
- Asynchronous peer connection creation
- Platform-specific bindings

See [TYPESCRIPT_DIFFERENCES.md](https://github.com/sjhorn/ring_client_api/blob/main/TYPESCRIPT_DIFFERENCES.md) in the core package for complete comparison.

## Known Limitations

### Current Implementation

The implementation is **complete and functional**:
- ✅ WebRTC peer connection setup
- ✅ Full WebSocket signaling with Ring servers
- ✅ FlutterWebrtcConnection implementation
- ✅ ICE candidate handling
- ✅ SDP offer/answer exchange
- ✅ Media stream rendering
- ✅ Two-way audio support
- ✅ UI widgets with lifecycle management
- ✅ Session management with periodic pings
- ✅ Connection state tracking
- ✅ Error handling and cleanup

Future enhancements:
- ⏳ Recording functionality
- ⏳ Advanced camera controls (pan/tilt/zoom)
- ⏳ Automatic reconnection on failure

### Platform Support

| Platform | Video | Audio | Two-Way Audio | Status |
|----------|-------|-------|---------------|---------|
| iOS      | ✅    | ✅    | ✅            | Supported |
| Android  | ✅    | ✅    | ✅            | Supported |
| Web      | ✅    | ✅    | ✅            | Supported |
| macOS    | ✅    | ✅    | ✅            | Supported |
| Windows  | ✅    | ✅    | ✅            | Supported |
| Linux    | ✅    | ✅    | ✅            | Supported |

## Publishing

### Before Publishing

1. Update pubspec.yaml to use hosted dependency:
```yaml
dependencies:
  ring_client_api: ^0.1.0  # Instead of path
```

2. Run checks:
```bash
flutter pub get
flutter analyze
flutter test
flutter pub publish --dry-run
```

3. Commit and tag:
```bash
git add .
git commit -m "Release v0.1.0"
git tag v0.1.0
git push origin main
git push origin v0.1.0
```

4. Publish:
```bash
flutter pub publish
```

### After Publishing

Revert to path dependency for continued development:
```bash
git revert HEAD
```

## Contributing

### Code Style

- Follow Dart style guide
- Use `flutter format .`
- All public APIs must have documentation
- Add tests for new features

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Run `flutter analyze` and `flutter test`
5. Submit pull request with description

## Resources

### Documentation

- [Core Package README](https://github.com/sjhorn/ring_client_api/blob/main/README.md)
- [WebRTC Options Guide](https://github.com/sjhorn/ring_client_api/blob/main/WEBRTC_OPTIONS.md)
- [TypeScript Differences](https://github.com/sjhorn/ring_client_api/blob/main/TYPESCRIPT_DIFFERENCES.md)

### Related Projects

- [ring-client-api (TypeScript)](https://github.com/dgreif/ring) - Original TypeScript implementation
- [flutter_webrtc](https://github.com/flutter-webrtc/flutter-webrtc) - Flutter WebRTC plugin

### Ring API

- [Ring Developer Portal](https://ring.com/developers) - Official documentation
- [Ring Control Center](https://account.ring.com/account/control-center) - Manage authorized devices

## Support

- **Issues**: https://github.com/sjhorn/ring_camera/issues
- **Core Package Issues**: https://github.com/sjhorn/ring_client_api/issues
- **Discussions**: Use GitHub Discussions for questions

## License

MIT License - Copyright (c) 2025 Scott Horn

Based on the TypeScript [ring-client-api](https://github.com/dgreif/ring) by Dusty Greif.
