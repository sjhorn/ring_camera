# Simple Snapshot Example

Minimal example showing how to display periodic snapshots from a Ring camera (battery-friendly alternative to live streaming).

## Setup

1. Create a `.env` file in this directory:
```bash
refresh_token=your_refresh_token_here
camera_id=your_camera_id_here
```

2. Run the example:
```bash
flutter run -d macos
```

## Getting Your Credentials

### Refresh Token
See the main [ring_camera README](../../README.md) for instructions on getting your refresh token.

### Camera ID
Run the camera_viewer example to see all your cameras and their IDs, or use the ring_client_api to list them programmatically.

## Features

- **Minimal code** (~130 lines) - Shows the simplest possible snapshot setup  
- **Easy configuration** - Just create a .env file, no command-line parameters
- **Periodic updates** - Refreshes every 10 seconds (configurable)
- **Battery friendly** - Much more efficient than live streaming
- **Error handling** - Clear error messages for common issues

## Code Overview

The example demonstrates the 3-step process:

1. Load credentials from `.env` file
2. Initialize `RingApi` and fetch camera by ID
3. Display periodic snapshots with `RingCameraSnapshotViewer` widget

The `RingCameraSnapshotViewer` widget automatically:
- Fetches new snapshots at the specified interval
- Handles loading states
- Shows errors when snapshots fail to load
- Resizes images appropriately

## Use Cases

Snapshot mode is ideal for:
- **Battery-powered devices** - Doorbells, stick-up cams (avoids draining battery)
- **Low-bandwidth situations** - Uses much less data than video streaming
- **Monitoring multiple cameras** - Can show many cameras simultaneously
- **Reducing server load** - Lighter on Ring's servers than WebRTC streams
