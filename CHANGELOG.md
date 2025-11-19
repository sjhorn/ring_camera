## 0.1.6

### New Features

- **Added video recording support** - Record video from Ring cameras to local files
  - New `RingCameraRecorder` class for managing recording sessions
  - Frame capture from WebRTC video stream using `captureFrame()`
  - FFmpeg encoding using ffmpeg_kit_flutter_new
  - Configurable duration with progress callbacks
  - Helper function `recordCameraToFile()` for simple usage
  - Automatic framerate adjustment to match actual capture performance
  - Cross-platform support (macOS, iOS, Android)

### Dependencies

- **Added ffmpeg_kit_flutter_new** ^4.1.0 for video encoding
- **Added path_provider** ^2.1.0 for file system access

### Examples

- **Updated record_example** to use new ring_camera recording API
  - Changed from ring_client_api (stub) to ring_camera (full implementation)
  - Added progress indicators showing recording status
  - Shows recording path and completion status

### Technical Details

- Frame capture loop with time-based recording (accurate duration)
- Dynamic FPS calculation based on actual capture performance
- FFmpeg encoding with H.264 codec, yuv420p pixel format
- Temporary frame storage with automatic cleanup
- Smart video track detection (waits for streams with video tracks)

## 0.1.5

### Platform Support

- **Added Android platform to camera_viewer example**
  - Complete Android manifest with all required permissions
  - Internet, Camera, Record Audio, Modify Audio Settings, Network State
  - Camera feature marked as optional (required="false")

- **Added iOS platform to camera_viewer example**
  - iOS project files and configuration
  - Ready for NSCameraUsageDescription and NSMicrophoneUsageDescription

### Documentation

- **Enhanced README.md** with Android permissions configuration
  - Detailed Android permissions section
  - Explanation of optional camera feature
  - Separated platform documentation (macOS, iOS, Android, Web/Windows/Linux)

- **Updated AGENTS.md** with Android guidelines
  - Reorganized Platform Permissions section
  - Added Android permissions subsection with examples
  - Guidelines for future Android development

## 0.1.4

### Documentation

- **Enhanced README.md** with platform-specific configuration
  - Added comprehensive Platform Configuration section
  - Documented macOS network entitlements (Debug and Release)
  - Documented iOS camera and microphone permissions
  - Updated Examples section to list all three examples
  - Fixed broken documentation links
  - Added specific version requirements

### Improvements

- **Updated AGENTS.md** with Flutter publishing instructions
  - Added `flutter pub publish` command (instead of `dart pub publish`)
  - Documented automated publishing with `echo "y" | flutter pub publish`

## 0.1.3

### New Examples

- **Added simple_live_stream example** - Minimal (~130 lines) example showing live video streaming
  - Simple .env file configuration (refresh_token, camera_id)
  - Clear setup instructions
  - Demonstrates RingCameraViewer widget usage

- **Added simple_snapshot example** - Minimal (~130 lines) example showing periodic snapshots
  - Battery-friendly alternative to live streaming
  - 10-second refresh interval (configurable)
  - Demonstrates RingCameraSnapshotViewer widget usage

### Improvements

- **Standardized .env configuration** across all examples
  - Consistent naming: `refresh_token` and `camera_id` (lowercase)
  - All examples include .env.example templates

- **Added macOS network entitlements** to new examples
  - Both Debug and Release configurations properly configured
  - Ready to run without permission errors

- **Updated AGENTS.md** with macOS entitlements guidelines
  - Clear instructions for future example development
  - Prevents common network permission issues

## 0.1.2

### Bug Fixes

- **Fixed 15-second stream disconnection issue**
  - Root cause: Session messages (ping, activate_session, stream_options, activate_camera_speaker) were missing required `dialog_id` field
  - Ring signaling server requires `dialog_id` in all session messages to properly route and acknowledge them
  - Server was timing out waiting for pings because it couldn't identify the session
  - Now all session messages include `dialog_id` matching TypeScript implementation
  - Streams now stay alive indefinitely with successful ping/pong exchanges

### Improvements

- Enhanced logging for better debugging of connection lifecycle
- Added INFO-level logging configuration in example app
- More detailed ping/pong message logging

### Technical Details

- Updated `_sendSessionMessage()` to automatically add `dialog_id` to all session messages
- Fixed activate_session timing (now sent after SDP answer, not after session creation)
- Consistent session message format across all methods

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
