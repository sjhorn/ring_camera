import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ring_client_api/ring_client_api.dart';

/// Return Audio Example
///
/// Demonstrates sending audio to camera speaker (two-way audio).
/// Similar to return-audio-example.ts in the TypeScript examples.
///
/// Note: This requires an audio source. The TypeScript example plays
/// from a file, but in Flutter you'd typically use microphone input.
class ReturnAudioExample extends StatefulWidget {
  const ReturnAudioExample({super.key});

  @override
  State<ReturnAudioExample> createState() => _ReturnAudioExampleState();
}

class _ReturnAudioExampleState extends State<ReturnAudioExample> {
  RingCamera? _camera;
  bool _loading = true;
  String? _error;
  bool _audioActive = false;
  StreamingSession? _liveCall;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    // Note: StreamingSession.stop() is only available in ring_camera package
    // _liveCall?.stop();
    super.dispose();
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
          controlCenterDisplayName: 'Return Audio Example',
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

  Future<void> _startReturnAudio() async {
    if (_camera == null || _audioActive) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      debugPrint('Starting live call...');
      final liveCall = await _camera!.startLiveCall();

      // Note: activateCameraSpeaker() is only available in ring_camera package
      // await liveCall.activateCameraSpeaker();
      debugPrint('Live call started (speaker activation requires ring_camera package)...');

      // TypeScript example uses transcodeReturnAudio() with an audio file input
      // In Flutter, you would typically:
      // 1. Get microphone input
      // 2. Encode it properly
      // 3. Send it via transcodeReturnAudio()
      //
      // For this example, we just show the API structure:
      // await liveCall.transcodeReturnAudio(
      //   FfmpegOptions(input: ['path/to/audio/source']),
      // );

      setState(() {
        _liveCall = liveCall;
        _audioActive = true;
        _loading = false;
      });

      debugPrint('Return audio activated!');
    } catch (e) {
      debugPrint('Error starting return audio: $e');
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _stopReturnAudio() async {
    if (_liveCall == null) return;

    try {
      // Note: StreamingSession.stop() is only available in ring_camera package
      // await _liveCall!.stop();
      setState(() {
        _liveCall = null;
        _audioActive = false;
      });
      debugPrint('Return audio stopped (actual stop requires ring_camera package)');
    } catch (e) {
      debugPrint('Error stopping return audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Audio Example'),
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
            const SizedBox(height: 32),

            Icon(
              _audioActive ? Icons.mic : Icons.mic_off,
              size: 80,
              color: _audioActive ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 24),

            Text(
              _audioActive
                  ? 'Return Audio Active'
                  : 'Return Audio Inactive',
              style: TextStyle(
                fontSize: 20,
                color: _audioActive ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            if (!_audioActive)
              ElevatedButton.icon(
                onPressed: _startReturnAudio,
                icon: const Icon(Icons.mic),
                label: const Text('Start Return Audio'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _stopReturnAudio,
                icon: const Icon(Icons.mic_off),
                label: const Text('Stop Return Audio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),

            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(height: 8),
                  Text(
                    'Note: Full audio streaming requires additional implementation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Similar to return-audio-example.ts, this demonstrates:\n'
                    '• startLiveCall()\n'
                    '• activateCameraSpeaker()\n'
                    '• transcodeReturnAudio()\n\n'
                    'For full implementation, you would:\n'
                    '1. Capture microphone input\n'
                    '2. Encode audio stream\n'
                    '3. Send via transcodeReturnAudio()',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
