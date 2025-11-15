import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ring_camera/ring_camera.dart';
import 'camera_viewer_page.dart';

/// Example app demonstrating ring_camera usage
///
/// This app shows how to:
/// - Authenticate with Ring using a refresh token
/// - List cameras from your Ring account
/// - View live camera streams
/// - View camera snapshots
/// - Control camera features (light, siren)
Future<void> main() async {
  // Load .env file for testing (optional)
  // Create a .env file in the parent directory with your refresh_token
  try {
    await dotenv.load(fileName: './.env');
  } catch (e) {
    debugPrint('No .env file found: $e');
  }

  runApp(const RingExampleApp());
}

class RingExampleApp extends StatelessWidget {
  const RingExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ring Camera Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CameraListPage(),
    );
  }
}

class CameraListPage extends StatefulWidget {
  const CameraListPage({super.key});

  @override
  State<CameraListPage> createState() => _CameraListPageState();
}

class _CameraListPageState extends State<CameraListPage> {
  final _refreshTokenController = TextEditingController();
  RingApi? _ringApi;
  List<RingCamera>? _cameras;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-load refresh token from .env if available
    final envToken = dotenv.maybeGet('refresh_token');
    if (envToken != null && envToken.isNotEmpty) {
      _refreshTokenController.text = envToken;
      // Note: Removed auto-load to prevent auth loop
      // User must click "Load Cameras" button manually
    }
  }

  @override
  void dispose() {
    _refreshTokenController.dispose();
    _ringApi?.disconnect();
    super.dispose();
  }

  Future<void> _loadCameras() async {
    final refreshToken = _refreshTokenController.text.trim();
    if (refreshToken.isEmpty) {
      setState(() {
        _error = 'Please enter a refresh token';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _cameras = null;
    });

    try {
      // Disconnect existing API if any
      await _ringApi?.disconnect();

      // Create new API instance
      final ringApi = RingApi(
        RefreshTokenAuth(refreshToken: refreshToken),
        options: RingApiOptions(
          debug: false,
          controlCenterDisplayName: 'Ring Flutter Example',
        ),
      );

      // Listen for token updates
      ringApi.onRefreshTokenUpdated.listen((update) {
        debugPrint('Refresh token updated: ${update.newRefreshToken}');
        // In a real app, save this to secure storage
      });

      // Get cameras
      final cameras = await ringApi.getCameras();

      if (mounted) {
        setState(() {
          _ringApi = ringApi;
          _cameras = cameras;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load cameras: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ring Cameras'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Refresh token input
            TextField(
              controller: _refreshTokenController,
              decoration: const InputDecoration(
                labelText: 'Refresh Token',
                hintText: 'Enter your Ring refresh token',
                border: OutlineInputBorder(),
                helperText: 'Use ring_auth_cli to obtain a refresh token',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // Load cameras button
            ElevatedButton(
              onPressed: _isLoading ? null : _loadCameras,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load Cameras'),
            ),

            const SizedBox(height: 24),

            // Error display
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // Camera list
            if (_cameras != null) ...[
              const Divider(),
              Text(
                'Cameras (${_cameras!.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _cameras!.isEmpty
                    ? const Center(
                        child: Text('No cameras found'),
                      )
                    : ListView.builder(
                        itemCount: _cameras!.length,
                        itemBuilder: (context, index) {
                          final camera = _cameras![index];
                          return CameraListItem(camera: camera);
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CameraListItem extends StatelessWidget {
  final RingCamera camera;

  const CameraListItem({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          camera.isDoorbot ? Icons.doorbell : Icons.videocam,
          size: 32,
        ),
        title: Text(camera.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${camera.id}'),
            if (camera.hasLight) const Text('• Has Light'),
            if (camera.hasSiren) const Text('• Has Siren'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'stream':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraViewerPage(
                      camera: camera,
                      viewMode: CameraViewMode.stream,
                    ),
                  ),
                );
                break;
              case 'snapshot':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraViewerPage(
                      camera: camera,
                      viewMode: CameraViewMode.snapshot,
                    ),
                  ),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'stream',
              child: Row(
                children: [
                  Icon(Icons.play_circle),
                  SizedBox(width: 8),
                  Text('Live Stream'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'snapshot',
              child: Row(
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text('Snapshots'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
