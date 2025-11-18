import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ring_camera/ring_camera.dart';

/// Live Stream Example
///
/// Shows live video stream from a Ring camera using RingCameraViewer widget.
/// Similar to browser-example.ts which creates an HLS stream viewable in browser.
class LiveStreamExample extends StatefulWidget {
  const LiveStreamExample({super.key});

  @override
  State<LiveStreamExample> createState() => _LiveStreamExampleState();
}

class _LiveStreamExampleState extends State<LiveStreamExample> {
  RingCamera? _camera;
  bool _loading = true;
  String? _error;
  String? _lastStreamError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final refreshToken = dotenv.env['refresh_token'] ?? '';
      final cameraId = dotenv.env['camera_id'] ?? '';

      if (refreshToken.isEmpty || cameraId.isEmpty) {
        setState(() {
          _error = 'Missing refresh_token or camera_id in .env file.\n\n'
              'Create a .env file with:\n'
              'refresh_token=your_refresh_token_here\n'
              'camera_id=your_camera_id_here';
          _loading = false;
        });
        return;
      }

      final ringApi = RingApi(
        RefreshTokenAuth(refreshToken: refreshToken),
        options: RingApiOptions(
          controlCenterDisplayName: 'Live Stream Example',
        ),
      );

      final cameras = await ringApi.getCameras();
      final camera = cameras.firstWhere(
        (c) => c.id.toString() == cameraId,
        orElse: () => throw Exception('Camera $cameraId not found'),
      );

      setState(() {
        _camera = camera;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Stream Example'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_camera == null) {
      return const Center(child: Text('No camera found'));
    }

    return Column(
      children: [
        Expanded(
          child: RingCameraViewer(
            camera: _camera!,
            showStatus: true,
            onError: (error) {
              setState(() {
                _lastStreamError = error.toString();
              });
              debugPrint('Stream error: $error');
            },
            onConnectionStateChanged: (state) {
              debugPrint('Connection state: $state');
            },
          ),
        ),

        // Error display
        if (_lastStreamError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.red.shade100,
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastStreamError!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _lastStreamError = null;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
