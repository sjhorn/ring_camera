import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ring_client_api/ring_client_api.dart';

/// Camera History Example
///
/// Demonstrates fetching camera event history and getting recording URLs.
/// Similar to api-example.ts in the TypeScript examples.
class HistoryExample extends StatefulWidget {
  const HistoryExample({super.key});

  @override
  State<HistoryExample> createState() => _HistoryExampleState();
}

class _HistoryExampleState extends State<HistoryExample> {
  RingCamera? _camera;
  List<CameraEvent>? _events;
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
          controlCenterDisplayName: 'History Example',
        ),
      );

      final cameras = await ringApi.getCameras();
      final camera = cameras.firstWhere(
        (c) => c.id.toString() == cameraId,
        orElse: () => throw Exception('Camera $cameraId not found'),
      );

      // Get camera events (similar to api-example.ts)
      final eventsResponse = await camera.getEvents(
        CameraEventOptions(
          limit: 20,
          // kind: 'ding', // Filter by doorbell events
          // state: 'accepted', // Filter by accepted events
        ),
      );

      setState(() {
        _camera = camera;
        _events = eventsResponse.events;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _getRecordingUrl(CameraEvent event, bool transcoded) async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final url = await _camera!.getRecordingUrl(
        event.dingIdStr,
        transcoded: transcoded,
      );

      setState(() {
        _loading = false;
      });

      // Show URL in dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(transcoded ? 'Transcoded URL' : 'Untranscoded URL'),
            content: SelectableText(url),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error getting recording URL: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera History'),
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

    if (_events == null || _events!.isEmpty) {
      return const Center(child: Text('No events found'));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.purple.withValues(alpha: 0.2),
          child: Text(
            '${_events!.length} events for ${_camera!.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _events!.length,
            itemBuilder: (context, index) {
              final event = _events![index];
              final hasRecording = event.recordingStatus == 'ready';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: Icon(
                    event.kind == 'ding'
                        ? Icons.doorbell
                        : Icons.motion_photos_on,
                    size: 36,
                  ),
                  title: Text(
                    '${event.kind.toUpperCase()} - ${event.state}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time: ${event.createdAt}'),
                      Text('Ding ID: ${event.dingIdStr}'),
                      Text('Recording: ${event.recordingStatus}'),
                    ],
                  ),
                  trailing: hasRecording
                      ? PopupMenuButton<String>(
                          icon: const Icon(Icons.play_circle_outline),
                          onSelected: (value) {
                            final transcoded = value == 'transcoded';
                            _getRecordingUrl(event, transcoded);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'transcoded',
                              child: Text('Get Transcoded URL'),
                            ),
                            const PopupMenuItem(
                              value: 'untranscoded',
                              child: Text('Get Untranscoded URL'),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.black26,
          child: const Text(
            'Similar to api-example.ts - uses getEvents() and getRecordingUrl()\n'
            'Tap play button to get recording URLs',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
