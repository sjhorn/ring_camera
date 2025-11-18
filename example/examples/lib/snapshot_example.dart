import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ring_camera/ring_camera.dart';

/// Snapshot Example
///
/// Takes periodic snapshots from a Ring camera.
/// Uses getSnapshot() to fetch still images at regular intervals.
class SnapshotExample extends StatefulWidget {
  const SnapshotExample({super.key});

  @override
  State<SnapshotExample> createState() => _SnapshotExampleState();
}

class _SnapshotExampleState extends State<SnapshotExample> {
  RingCamera? _camera;
  bool _loading = true;
  String? _error;

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
          controlCenterDisplayName: 'Snapshot Example',
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
        title: const Text('Snapshot Example'),
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

    return Center(
      child: RingCameraSnapshotViewer(
        camera: _camera!,
        refreshInterval: const Duration(seconds: 10),
      ),
    );
  }
}
