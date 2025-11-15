# Simple Live Stream Example

Minimal example showing how to stream live video from a Ring camera.

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

- **Minimal code** (~130 lines) - Shows the simplest possible live streaming setup
- **Easy configuration** - Just create a .env file, no command-line parameters
- **Error handling** - Clear error messages for common issues
- **Full WebRTC** - Uses RingCameraViewer widget for complete video streaming

## Code Overview

The example demonstrates the 3-step process:

1. Load credentials from `.env` file
2. Initialize `RingApi` and fetch camera by ID
3. Display live stream with `RingCameraViewer` widget

The `RingCameraViewer` widget handles all the WebRTC complexity automatically including:
- WebSocket signaling
- SDP offer/answer exchange
- ICE candidate handling  
- Video rendering
- Connection state management
