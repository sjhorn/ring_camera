import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';

// Import all example pages
import 'live_stream_example.dart';
import 'snapshot_example.dart';
import 'record_example.dart';
import 'events_example.dart';
import 'locations_example.dart';
import 'history_example.dart';
import 'return_audio_example.dart';

/// Ring Camera API Examples
///
/// This app demonstrates various Ring Camera API features, similar to the
/// TypeScript examples in ring-client-api/packages/examples
///
/// Each example is in its own file and can be run independently.
Future<void> main() async {
  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('[${record.loggerName}] ${record.level.name}: ${record.message}');
  });

  // Load .env file (optional)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('No .env file found: $e');
  }

  runApp(const RingExamplesApp());
}

class RingExamplesApp extends StatelessWidget {
  const RingExamplesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ring Camera Examples',
      theme: ThemeData.dark(),
      home: const ExamplesHomePage(),
    );
  }
}

class Example {
  final String title;
  final String description;
  final IconData icon;
  final Widget page;

  const Example({
    required this.title,
    required this.description,
    required this.icon,
    required this.page,
  });
}

class ExamplesHomePage extends StatelessWidget {
  const ExamplesHomePage({super.key});

  static final List<Example> examples = [
    Example(
      title: 'Live Stream',
      description: 'View live video stream from a Ring camera',
      icon: Icons.videocam,
      page: const LiveStreamExample(),
    ),
    Example(
      title: 'Snapshot',
      description: 'Take periodic snapshots from a Ring camera',
      icon: Icons.camera_alt,
      page: const SnapshotExample(),
    ),
    Example(
      title: 'Record to File',
      description: 'Record 10-second video clips to local files',
      icon: Icons.fiber_manual_record,
      page: const RecordExample(),
    ),
    Example(
      title: 'Events & Notifications',
      description: 'Listen for motion, doorbell, and notification events',
      icon: Icons.notifications_active,
      page: const EventsExample(),
    ),
    Example(
      title: 'Locations API',
      description: 'List locations, devices, and connection status',
      icon: Icons.location_on,
      page: const LocationsExample(),
    ),
    Example(
      title: 'Camera History',
      description: 'View camera events history and recording URLs',
      icon: Icons.history,
      page: const HistoryExample(),
    ),
    Example(
      title: 'Return Audio',
      description: 'Send audio to camera speaker (two-way audio)',
      icon: Icons.mic,
      page: const ReturnAudioExample(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ring Camera Examples'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final example = examples[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: Icon(example.icon, size: 36),
              title: Text(
                example.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(example.description),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => example.page,
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black26,
        child: const Text(
          'Configure your credentials in .env file:\n'
          'refresh_token=your_token\n'
          'camera_id=your_camera_id',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}
