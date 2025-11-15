# ring_camera - TODO

## Project Overview

Flutter companion package for ring_client_api providing full WebRTC video streaming support for Ring cameras.

**Current Version**: 0.1.0 (preparing for initial release)

**Status**: WebRTC streaming fully implemented and tested ✅

---

## Immediate Tasks (Pre-Publishing)

### Phase 1: Publishing Preparation ⏳

- [x] Package structure created
- [x] Core implementation complete
  - [x] FlutterPeerConnection
  - [x] RingCameraViewer widget
  - [x] RingCameraSnapshotViewer widget
- [x] Example app created
- [x] Documentation complete
  - [x] README.md
  - [x] CHANGELOG.md
  - [x] DEVELOPMENT.md
  - [x] example/README.md
- [x] Tests created
- [x] Analyzer passing (0 errors, 0 warnings)
- [x] **Wait for ring_client_api to be published**
- [x] Update pubspec.yaml dependency to `ring_client_api: ^0.1.0`
- [x] Run final checks
- [ ] Publish to pub.dev

---

## Post-Publishing Tasks

### Phase 2: Testing & Validation

- [x] Real device testing
  - [ ] Test on iOS device
  - [ ] Test on Android device
  - [x] Test on macOS (working)
  - [ ] Test on Web
  - [ ] Test on Windows (if available)
  - [ ] Test on Linux (if available)
- [ ] Verify two-way audio works on all platforms
- [ ] Performance testing
  - [ ] Measure video latency
  - [ ] Check CPU usage
  - [ ] Monitor memory usage
  - [ ] Battery impact on mobile devices

### Phase 3: Complete WebRTC Signaling ✅

**Status**: COMPLETED

**Implemented Features:**

1. **WebrtcConnection Implementation** ✅
   - Creates WebRTC session ticket with Ring camera
   - Establishes WebSocket connection for signaling
   - Sends SDP offer to Ring servers
   - Receives SDP answer from Ring servers
   - Handles ICE candidate exchange
   - Completes WebRTC handshake
   - Manages connection lifecycle with periodic pings

2. **FlutterPeerConnection** ✅
   - WebRTC peer connection wrapper
   - ICE candidate handling
   - Remote stream management
   - Two-way audio support
   - BUNDLE SDP modification for Ring compatibility

3. **RingCameraViewer Widget** ✅
   - Complete connection lifecycle management
   - Video rendering with flutter_webrtc
   - Connection state display
   - Error handling with timeouts
   - Automatic cleanup on dispose
   - Support for return audio

4. **Logging & Debugging** ✅
   - Clean logging using `logging` package
   - Default INFO level for production
   - Removed all debug print statements
   - Proper error reporting

### Phase 4: Additional Features

- [ ] **Recording Functionality**
  - [ ] Add recording controls to widget
  - [ ] Save video stream to file
  - [ ] Handle recording permissions
  - [ ] Support different video formats

- [ ] **Advanced Camera Controls**
  - [ ] Pan/Tilt controls (for supported cameras)
  - [ ] Zoom controls
  - [ ] Focus controls
  - [ ] Video quality settings

- [ ] **Enhanced Widgets**
  - [ ] Picture-in-picture support
  - [ ] Fullscreen mode
  - [ ] Customizable overlay controls
  - [ ] Connection quality indicator
  - [ ] Bandwidth usage display

- [ ] **Event Handling**
  - [ ] Motion detection events
  - [ ] Doorbell press events
  - [ ] Person detection events
  - [ ] Package detection events

### Phase 5: Optimization

- [ ] **Performance**
  - [ ] Optimize video rendering
  - [ ] Reduce latency
  - [ ] Implement adaptive bitrate
  - [ ] Add hardware acceleration hints

- [ ] **Battery Optimization**
  - [ ] Smart snapshot refresh rates
  - [ ] Power-saving mode for background streaming
  - [ ] Wake lock management

- [ ] **Memory Management**
  - [ ] Stream buffer optimization
  - [ ] Proper cleanup on dispose
  - [ ] Memory leak detection

### Phase 6: Testing & Quality

- [ ] **Unit Tests**
  - [ ] Test FlutterPeerConnection
  - [ ] Test widget lifecycle
  - [ ] Test error handling
  - [ ] Test connection state management

- [ ] **Integration Tests**
  - [ ] Test full streaming flow
  - [ ] Test with mock Ring servers
  - [ ] Test reconnection logic
  - [ ] Test two-way audio

- [ ] **Widget Tests**
  - [ ] Test RingCameraViewer rendering
  - [ ] Test control interactions
  - [ ] Test error states
  - [ ] Test loading states

- [ ] **Platform Tests**
  - [ ] iOS-specific tests
  - [ ] Android-specific tests
  - [ ] Web-specific tests
  - [ ] Desktop-specific tests

### Phase 7: Documentation

- [ ] **API Documentation**
  - [ ] Add dartdoc comments to all public APIs
  - [ ] Generate API reference docs
  - [ ] Create migration guides

- [ ] **Tutorials**
  - [ ] Basic setup tutorial
  - [ ] Advanced features tutorial
  - [ ] Custom widget tutorial
  - [ ] Troubleshooting guide

- [ ] **Examples**
  - [ ] Simple streaming example
  - [ ] Two-way audio example
  - [ ] Recording example
  - [ ] Custom UI example
  - [ ] Multi-camera example

### Phase 8: Community & Maintenance

- [ ] Set up GitHub repository
- [ ] Create issue templates
- [ ] Set up CI/CD pipeline
  - [ ] Automated tests
  - [ ] Analyzer checks
  - [ ] Format checks
  - [ ] Platform builds
- [ ] Create contribution guidelines
- [ ] Set up discussions forum
- [ ] Monitor and respond to issues

---

## Known Issues & Limitations

### Current Limitations

1. **Platform-Specific Issues**
   - Web: May require HTTPS for getUserMedia
   - iOS: Requires camera/microphone permissions in Info.plist
   - Android: Requires runtime permissions handling

2. **Feature Gaps from TypeScript**
   - No FFmpeg integration (TypeScript has recording)
   - No automatic reconnection logic (manual restart required)

3. **Testing Gaps**
   - Only tested on macOS so far
   - Need iOS/Android device testing
   - Need web platform testing

### Future Considerations

1. **Architecture**
   - Consider state management solution (Bloc, Riverpod, etc.)
   - Consider separating UI from logic more clearly
   - Consider plugin architecture for extensibility

2. **Platform Support**
   - Investigate pure Dart WebRTC options (future)
   - Consider platform channels for custom features
   - Evaluate Web Assembly for web performance

3. **Security**
   - Implement secure token storage
   - Add certificate pinning for Ring APIs
   - Implement session timeout handling

---

## Features Tracked from ring_client_api

The following features are intentionally not implemented in the core `ring_client_api` package (pure Dart) and are tracked here for the Flutter-specific `ring_camera` package.

### 1. 🎥 WebRTC Video Streaming

**Status**: ✅ **IMPLEMENTED in v0.1.0**

**What was moved from ring_client_api**:
- Full WebRTC peer connection implementation
- SDP offer/answer exchange
- ICE candidate handling
- WebSocket signaling with Ring servers
- Video/audio stream rendering

**Implementation**:
- ✅ `FlutterPeerConnection` - WebRTC peer connection wrapper
- ✅ `WebrtcConnection` - Signaling and handshake logic
- ✅ `RingCameraViewer` - Widget for live streaming
- ✅ `RingCameraSnapshotViewer` - Battery-friendly snapshot viewer
- ✅ Two-way audio support
- ✅ Connection lifecycle management

**Reference**: Originally stubbed in ring_client_api with pointers to this package.

---

### 2. 🎬 FFmpeg Integration & Recording

**Status**: ⏳ **PLANNED for v0.3.0**

**What was moved from ring_client_api**:
The TypeScript `ring-client-api` includes `ffmpeg.ts` for:
- Video transcoding
- Recording to file
- Stream format conversion
- Video quality adjustment

**Why not in ring_client_api**:
- Requires platform-specific FFmpeg binaries
- Different implementation per platform (iOS, Android, Web, Desktop)
- Flutter can use platform channels or packages like `ffmpeg_kit_flutter`

**Planned Implementation for ring_camera**:

#### Phase 4: Recording Functionality (v0.3.0)
- [ ] **Recording API**
  - [ ] Use `ffmpeg_kit_flutter` for native platforms
  - [ ] Implement `RingCamera.recordToFile(String outputPath, int duration)`
  - [ ] Support multiple video formats (MP4, MOV, etc.)
  - [ ] Handle recording permissions per platform
  - [ ] Progress callbacks during recording
  - [ ] Automatic file management

- [ ] **Recording Controls in Widget**
  - [ ] Add record button to `RingCameraViewer`
  - [ ] Recording indicator (red dot)
  - [ ] Duration display
  - [ ] Stop/pause controls
  - [ ] Save location picker

- [ ] **Stream Transcoding**
  - [ ] Quality settings (High, Medium, Low)
  - [ ] Bitrate adjustment
  - [ ] Resolution selection
  - [ ] Format conversion options

**Platform Considerations**:
- **iOS**: Use `ffmpeg_kit_flutter_min` or platform channels
- **Android**: Use `ffmpeg_kit_flutter_min` or ExoPlayer
- **Web**: Consider MediaRecorder API (no FFmpeg needed)
- **Desktop**: Full FFmpeg via `ffmpeg_kit_flutter_full`

**Dependencies to add**:
```yaml
dependencies:
  ffmpeg_kit_flutter_min: ^6.0.0  # For basic recording
  path_provider: ^2.1.0           # For file locations
  permission_handler: ^11.0.0     # For storage permissions
```

**References**:
- TypeScript implementation: `ring/packages/ring-client-api/ffmpeg.ts`
- FFmpeg Kit Flutter: https://pub.dev/packages/ffmpeg_kit_flutter

---

### 3. 🔔 Push Notifications (FCM Integration)

**Status**: ⏳ **PLANNED for v0.4.0+**

**What was moved from ring_client_api**:
The TypeScript `ring-client-api` includes push notification support using `@eneris/push-receiver`:
- Firebase Cloud Messaging (FCM) connection
- Ring's FCM project integration
- Credential persistence
- Push notification routing to devices
- Motion/doorbell event notifications

**Why not in ring_client_api**:
- Requires platform-specific Firebase setup
- Different implementation for Flutter vs CLI vs Web
- Beyond scope of pure Dart API library
- WebSocket already provides real-time updates

**Planned Implementation for ring_camera**:

#### Phase 5: Push Notifications (v0.4.0+)

- [ ] **Firebase Cloud Messaging Setup**
  - [ ] Add `firebase_messaging` dependency
  - [ ] Configure Firebase projects for each platform
  - [ ] Register with Ring's FCM project using these credentials:
    ```
    apiKey: '<key-here>'
    projectId: 'ring-17770'
    messagingSenderId: '876313859327'
    appId: '1:876313859327:android:e10ec6ddb3c81f39'
    ```

- [ ] **Push Receiver Implementation**
  - [ ] Create `RingPushNotificationManager` class
  - [ ] Handle FCM registration
  - [ ] Store and update push credentials
  - [ ] Route notifications to appropriate cameras/devices
  - [ ] Handle notification permissions per platform

- [ ] **Notification Types**
  - [ ] Motion detection alerts
  - [ ] Doorbell press alerts
  - [ ] Person detection alerts
  - [ ] Package detection alerts
  - [ ] Camera offline alerts
  - [ ] Low battery warnings

- [ ] **Notification UI**
  - [ ] Local notification display
  - [ ] Notification action buttons
  - [ ] Direct links to camera viewer
  - [ ] Notification history

- [ ] **Platform Configuration**
  - [ ] iOS: APNs certificate and Info.plist updates
  - [ ] Android: google-services.json configuration
  - [ ] Web: Firebase web config
  - [ ] Notification permissions handling

**Dependencies to add**:
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.0.0  # For local notification display
```

**Platform Setup Required**:
1. Create Firebase project or use Ring's existing project
2. Add platform-specific configuration files
3. Configure APNs for iOS
4. Update AndroidManifest.xml for Android
5. Handle runtime permissions

**Alternative for v0.1.0-v0.3.0**:
- ✅ WebSocket connections provide real-time updates
- Users can use `camera.onDoorbellPressed` stream
- Users can use `camera.onMotionDetected` stream
- No additional setup required

**References**:
- TypeScript implementation: `ring/packages/ring-client-api/api.ts` (_registerPushReceiver)
- Firebase Messaging: https://pub.dev/packages/firebase_messaging
- Ring's FCM config: See ring_client_api/lib/src/api.dart comments

---

## Version Planning

### v0.1.0 (Current)
- ✅ Complete WebRTC implementation
- ✅ Camera viewer widgets
- ✅ Example app with full streaming
- ✅ Documentation
- ✅ Clean logging (no debug prints)
- ✅ macOS testing complete
- ⏳ Awaiting publication

### v0.2.0 (Next Minor)
- iOS/Android device testing
- Web platform support verification
- Bug fixes from v0.1.0
- Performance optimizations

### v0.3.0
- Recording functionality
- Advanced camera controls
- Enhanced widgets
- Performance optimizations

### v1.0.0 (Stable)
- Feature complete
- Comprehensive tests
- Stable APIs
- Production ready

---

## Development Workflow

### Local Development

1. Use path dependency in pubspec.yaml:
   ```yaml
   dependencies:
     ring_client_api:
       path: ../ring_client_api
   ```

2. Make changes and test:
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   cd example && flutter run
   ```

3. Before committing:
   ```bash
   flutter format .
   flutter analyze
   flutter test
   ```

### Publishing Process

1. Update dependency to hosted:
   ```yaml
   dependencies:
     ring_client_api: ^0.1.0
   ```

2. Update version in pubspec.yaml

3. Update CHANGELOG.md

4. Run checks:
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   flutter pub publish --dry-run
   ```

5. Publish:
   ```bash
   flutter pub publish
   ```

6. Revert to path dependency for continued development

---

## Resources

### Documentation
- [Core Package](https://github.com/sjhorn/ring_client_api)
- [Flutter WebRTC](https://github.com/flutter-webrtc/flutter-webrtc)
- [Ring TypeScript API](https://github.com/dgreif/ring)

### References
- [WebRTC Options Analysis](https://github.com/sjhorn/ring_client_api/blob/main/WEBRTC_OPTIONS.md)
- [TypeScript Differences](https://github.com/sjhorn/ring_client_api/blob/main/TYPESCRIPT_DIFFERENCES.md)
- [Development Guide](DEVELOPMENT.md)

### Support
- GitHub Issues: https://github.com/sjhorn/ring_camera/issues
- Core Package Issues: https://github.com/sjhorn/ring_client_api/issues

---

## Progress Tracking

**Last Updated**: 2025-11-13

**Current Phase**: Phase 2 - Testing & Validation 🧪

**Completed**:
- ✅ Phase 1: Publishing Preparation (all package code complete)
- ✅ Phase 3: WebRTC Signaling (fully implemented and working)
- ✅ Code cleanup (removed debug print statements)
- ✅ Logging configuration (using Logger package)

**Blockers**:
- Waiting for core package (ring_client_api) to be published to pub.dev

**Next Milestone**:
- Complete device testing on iOS/Android/Web
- v0.1.0 initial release

---

## Notes

### Design Decisions

1. **Two-Package Architecture**: Keeps core package pure Dart, allows Flutter-specific features here
2. **Widget-Based API**: Provides easy-to-use widgets while allowing custom implementations
3. **flutter_webrtc**: Chose for mature platform support over pure Dart solutions
4. **Path Dependencies**: Use for development, hosted for publishing

### Lessons Learned

1. Union types in Dart require dynamic casting for accessing specific fields
2. flutter_webrtc requires async initialization
3. Platform permissions need careful documentation
4. Path dependencies complicate publishing workflow

### Future Ideas

- [ ] Camera groups/multi-view widget
- [ ] Event timeline viewer
- [ ] Integration with home automation systems
- [ ] Custom motion detection zones UI
- [ ] Camera health monitoring dashboard
- [ ] Notifications integration
