## 0.1.1

### Dependencies

- **Upgraded flutter_webrtc** from ^0.11.7 to ^1.2.0
  - Updated to WebRTC-SDK m137 (137.7151.04)
  - Improved Android device compatibility with 16kb page support
  - Enhanced local recording API for Darwin and Android
  - Better texture-based rendering for web platform
  - H265/HEVC codec support
  - Improved logger integration

### Improvements

- Enhanced onTrack logging for better debugging
- Verified compatibility with latest WebRTC stack
- All tests passing with new version

### Testing

- Confirmed video streaming works on macOS with flutter_webrtc 1.2.0
- No breaking changes in API
- Connection stability maintained

## 0.1.0

### Package Rename

**BREAKING**: Package renamed from `ring_client_api_flutter` to `ring_camera`
- More descriptive of package functionality (camera-specific)
- Shorter, more memorable name
- Update your imports: `package:ring_camera/ring_camera.dart`

### Initial Release

Flutter widgets for Ring camera streaming with full WebRTC support.

#### Features

- **Live Video Streaming** - Full WebRTC support using flutter_webrtc
  - H.264 video codec
  - Opus and PCMU audio codecs
  - ICE candidate handling
  - Connection state management

- **Two-Way Audio** - Optional microphone support for visitor communication
  - Echo cancellation
  - Noise suppression
  - Auto gain control

- **Ready-to-Use Widgets**
  - `RingCameraViewer` - Live streaming with WebRTC
  - `RingCameraSnapshotViewer` - Battery-friendly periodic snapshots
  - Connection status indicators
  - Error handling

- **Cross-Platform Support**
  - iOS, Android, Web, macOS, Windows, Linux
  - Platform-specific permissions documented

- **Example App** - Complete working example demonstrating:
  - Ring authentication
  - Camera list
  - Live streaming
  - Snapshot viewing
  - Camera controls (light, siren)
  - Two-way audio toggle

#### Documentation

- Complete README with setup instructions
- Platform-specific configuration guides
- Troubleshooting section
- Security best practices

#### Compatibility

- Flutter 3.0 or later
- Dart 3.0 or later
- ring_client_api ^0.1.0
- flutter_webrtc ^0.11.7
