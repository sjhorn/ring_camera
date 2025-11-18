# Ring Camera API Examples

Comprehensive examples demonstrating Ring Camera API features, organized similarly to the TypeScript examples in `ring-client-api/packages/examples`.

## Overview

This Flutter app contains 7 examples, each demonstrating different aspects of the Ring Camera API:

1. **Live Stream** - View live video from Ring cameras (browser-example.ts)
2. **Snapshot** - Take periodic snapshots
3. **Record to File** - Record video clips to local files (record-example.ts)
4. **Events & Notifications** - Listen for motion, doorbell, and other events (example.ts)
5. **Locations API** - List locations, devices, and monitoring status (api-example.ts)
6. **Camera History** - View event history and get recording URLs (api-example.ts)
7. **Return Audio** - Send audio to camera speaker (return-audio-example.ts)

## Setup

### 1. Configure Credentials

Create a `.env` file in this directory:

```env
refresh_token=your_refresh_token_here
camera_id=your_camera_id_here
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run -d macos
```

## Examples Structure

Each example is in its own file under `lib/`.

## Requirements

- Flutter 3.0+
- Dart 3.0+
- ffmpeg (for recording and streaming)
- Valid Ring refresh token
