import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ring_client_api/ring_client_api.dart';

/// Locations API Example
///
/// Demonstrates the Locations API: listing locations, devices, and monitoring status.
class LocationsExample extends StatefulWidget {
  const LocationsExample({super.key});

  @override
  State<LocationsExample> createState() => _LocationsExampleState();
}

class _LocationsExampleState extends State<LocationsExample> {
  List<Location>? _locations;
  Map<String, List<RingDevice>> _devicesByLocation = {};
  Map<String, dynamic> _monitoringStatus = {};
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
          controlCenterDisplayName: 'Locations Example',
        ),
      );

      final locations = await ringApi.getLocations();

      // Get devices for each location
      final devicesByLocation = <String, List<RingDevice>>{};
      final monitoringStatus = <String, dynamic>{};

      for (var location in locations) {
        final devices = await location.getDevices();
        devicesByLocation[location.id] = devices;

        try {
          final status = await location.getAccountMonitoringStatus();
          monitoringStatus[location.id] = status;
        } catch (e) {
          debugPrint('Error getting monitoring status for ${location.id}: $e');
        }
      }

      setState(() {
        _locations = locations;
        _devicesByLocation = devicesByLocation;
        _monitoringStatus = monitoringStatus;
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
        title: const Text('Locations API'),
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

    if (_locations == null || _locations!.isEmpty) {
      return const Center(child: Text('No locations found'));
    }

    return ListView.builder(
      itemCount: _locations!.length,
      itemBuilder: (context, index) {
        final location = _locations![index];
        final devices = _devicesByLocation[location.id] ?? [];
        final cameras = location.cameras;
        final monitoring = _monitoringStatus[location.id];

        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            leading: const Icon(Icons.location_city, size: 36),
            title: Text(
              location.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('ID: ${location.id}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cameras
                    Text(
                      'Cameras (${cameras.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (cameras.isEmpty)
                      const Text('No cameras')
                    else
                      ...cameras.map((camera) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 4),
                            child: Text(
                              '• ${camera.name} (${camera.deviceType})',
                            ),
                          )),

                    const SizedBox(height: 16),

                    // All Devices
                    Text(
                      'All Devices (${devices.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (devices.isEmpty)
                      const Text('No devices')
                    else
                      ...devices.map((device) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 4),
                            child: Text(
                              '• ${device.name} (${device.deviceType})',
                            ),
                          )),

                    if (monitoring != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Monitoring Status',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(monitoring.toString()),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
