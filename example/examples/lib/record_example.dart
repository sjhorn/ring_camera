import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ring_camera/ring_camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Record Example
///
/// Records 10-second video clips from a Ring camera to a local file.
class RecordExample extends StatefulWidget {
  const RecordExample({super.key});

  @override
  State<RecordExample> createState() => _RecordExampleState();
}

class _RecordExampleState extends State<RecordExample> {
  RingCamera? _camera;
  bool _loading = true;
  String? _error;
  bool _recording = false;
  String? _recordingPath;
  String? _lastRecordedFile;
  String? _recordingProgress;

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
          controlCenterDisplayName: 'Record Example',
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

  Future<void> _startRecording() async {
    if (_camera == null || _recording) return;

    setState(() {
      _recording = true;
      _error = null;
      _recordingPath = null;
      _lastRecordedFile = null;
      _recordingProgress = 'Initializing...';
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final outputDir = Directory(path.join(directory.path, 'ring_recordings'));

      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final outputPath = path.join(outputDir.path, 'recording_$timestamp.mp4');

      setState(() {
        _recordingPath = outputPath;
      });

      debugPrint('Starting recording to: $outputPath');

      // Record 10 seconds of video using ring_camera recorder
      await recordCameraToFile(
        camera: _camera!,
        outputPath: outputPath,
        durationSeconds: 10,
        onProgress: (message) {
          debugPrint('Recording progress: $message');
          if (mounted) {
            setState(() {
              _recordingProgress = message;
            });
          }
        },
        onError: (error) {
          debugPrint('Recording error: $error');
        },
      );

      debugPrint('Recording complete: $outputPath');

      setState(() {
        _recording = false;
        _lastRecordedFile = outputPath;
      });
    } catch (e) {
      debugPrint('Error recording: $e');
      setState(() {
        _recording = false;
        _error = 'Recording failed: $e';
      });
    }
  }

  Future<void> _openRecordingsFolder() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final outputDir = Directory(path.join(directory.path, 'ring_recordings'));

      if (!await outputDir.exists()) {
        setState(() {
          _error = 'No recordings folder found yet';
        });
        return;
      }

      if (Platform.isMacOS) {
        await Process.run('open', [outputDir.path]);
      } else {
        setState(() {
          _error = 'Recordings saved to: ${outputDir.path}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error opening folder: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Example'),
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Camera: ${_camera!.name}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            if (_recording) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Recording 10 seconds of video...'),
              if (_recordingProgress != null) ...[
                const SizedBox(height: 8),
                Text(
                  _recordingProgress!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ],
              if (_recordingPath != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Saving to:\n${path.basename(_recordingPath!)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ] else ...[
              ElevatedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.fiber_manual_record),
                label: const Text('Start Recording (10 seconds)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openRecordingsFolder,
                icon: const Icon(Icons.folder_open),
                label: const Text('Open Recordings Folder'),
              ),
            ],

            if (_lastRecordedFile != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Recording Complete!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      path.basename(_lastRecordedFile!),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Text(
              'This example uses camera.recordToFile() to capture\n'
              '10-second video clips from your Ring camera',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
