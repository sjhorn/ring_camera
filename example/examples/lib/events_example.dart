import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ring_client_api/ring_client_api.dart';
import 'dart:async';

/// Events & Notifications Example
///
/// Listens for camera events like motion detection and doorbell presses.
/// Also demonstrates refresh token update handling.
/// Similar to example.ts in the TypeScript examples.
class EventsExample extends StatefulWidget {
  const EventsExample({super.key});

  @override
  State<EventsExample> createState() => _EventsExampleState();
}

class _EventsExampleState extends State<EventsExample> {
  List<RingCamera>? _cameras;
  List<Location>? _locations;
  bool _loading = true;
  String? _error;
  final List<String> _events = [];
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _refreshTokenSubscription;
  final List<StreamSubscription> _connectionSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _refreshTokenSubscription?.cancel();
    for (var sub in _connectionSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final refreshToken = dotenv.env['refresh_token'] ?? '';

      if (refreshToken.isEmpty) {
        setState(() {
          _error = 'Missing refresh_token in .env file.\n\n'
              'Create a .env file with:\n'
              'refresh_token=your_refresh_token_here';
          _loading = false;
        });
        return;
      }

      final ringApi = RingApi(
        RefreshTokenAuth(refreshToken: refreshToken),
        options: RingApiOptions(
          controlCenterDisplayName: 'Events Example',
        ),
      );

      // Subscribe to refresh token updates (important for long-running apps)
      _refreshTokenSubscription = ringApi.onRefreshTokenUpdated.listen((event) {
        _addEvent(
          'Refresh token updated!\n'
          'Old: ${event.oldRefreshToken?.substring(0, 10)}...\n'
          'New: ${event.newRefreshToken.substring(0, 10)}...\n'
          'Remember to save this to your config!',
        );
      });

      final locations = await ringApi.getLocations();
      final cameras = await ringApi.getCameras();

      _addEvent(
        'Found ${locations.length} location(s) with ${cameras.length} camera(s)',
      );

      // Listen for location connection status
      for (var location in locations) {
        final sub = location.onConnected.listen((connected) {
          final status = connected ? 'Connected to' : 'Disconnected from';
          _addEvent('$status location ${location.name} - ${location.id}');
        });
        _connectionSubscriptions.add(sub);
      }

      // Listen for camera notifications (motion, doorbell, etc.)
      for (var camera in cameras) {
        final sub = camera.onNewNotification.listen((notification) {
          final action = notification.androidConfig.category;
          final event = action == 'motion'
              ? 'Motion detected'
              : action == 'ding'
                  ? 'Doorbell pressed'
                  : 'Video started ($action)';

          _addEvent(
            '$event on ${camera.name} camera\n'
            'Ding ID: ${notification.data.event.ding.id}\n'
            'Time: ${DateTime.now()}',
          );
        });
        _connectionSubscriptions.add(sub);
      }

      setState(() {
        _cameras = cameras;
        _locations = locations;
        _loading = false;
      });

      _addEvent('Listening for motion and doorbell presses...');
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _addEvent(String event) {
    if (mounted) {
      setState(() {
        _events.insert(0, '${DateTime.now().toIso8601String()}\n$event');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events & Notifications'),
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.withValues(alpha: 0.2),
          child: Column(
            children: [
              Text(
                '${_locations?.length ?? 0} Locations, ${_cameras?.length ?? 0} Cameras',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Listening for events...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: _events.isEmpty
              ? const Center(
                  child:
                      Text('No events yet. Trigger motion or press doorbell.'),
                )
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.notifications),
                        title: Text(
                          _events[index],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.black26,
          child: const Text(
            'Similar to example.ts - listens for onNewNotification,\n'
            'onRefreshTokenUpdated, and location connection status',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
