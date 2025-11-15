import 'package:flutter/material.dart';
import 'package:ring_camera/ring_camera.dart';

enum CameraViewMode { stream, snapshot }

class CameraViewerPage extends StatefulWidget {
  final RingCamera camera;
  final CameraViewMode viewMode;

  const CameraViewerPage({
    super.key,
    required this.camera,
    required this.viewMode,
  });

  @override
  State<CameraViewerPage> createState() => _CameraViewerPageState();
}

class _CameraViewerPageState extends State<CameraViewerPage> {
  bool _enableReturnAudio = false;
  String? _lastError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.camera.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.viewMode == CameraViewMode.stream)
            IconButton(
              icon: Icon(
                _enableReturnAudio ? Icons.mic : Icons.mic_off,
              ),
              onPressed: () {
                setState(() {
                  _enableReturnAudio = !_enableReturnAudio;
                });
              },
              tooltip: 'Toggle microphone',
            ),
        ],
      ),
      body: Column(
        children: [
          // Camera viewer
          Expanded(
            child: widget.viewMode == CameraViewMode.stream
                ? RingCameraViewer(
                    camera: widget.camera,
                    enableReturnAudio: _enableReturnAudio,
                    showStatus: true,
                    onError: (error) {
                      setState(() {
                        _lastError = error.toString();
                      });
                    },
                    onConnectionStateChanged: (state) {
                      debugPrint('Connection state: $state');
                    },
                  )
                : RingCameraSnapshotViewer(
                    camera: widget.camera,
                    refreshInterval: const Duration(seconds: 10),
                  ),
          ),

          // Error display
          if (_lastError != null)
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
                      _lastError!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _lastError = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Camera controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.viewMode == CameraViewMode.stream
                      ? 'Live Stream'
                      : 'Snapshot Viewer',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Control buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (widget.camera.hasLight)
                      ElevatedButton.icon(
                        onPressed: () => _toggleLight(),
                        icon: const Icon(Icons.lightbulb),
                        label: const Text('Toggle Light'),
                      ),
                    if (widget.camera.hasSiren)
                      ElevatedButton.icon(
                        onPressed: () => _toggleSiren(),
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Toggle Siren'),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => _getSnapshot(),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Get Snapshot'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Camera info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Camera Info',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('ID', widget.camera.id.toString()),
                        _buildInfoRow('Type',
                            widget.camera.isDoorbot ? 'Doorbell' : 'Camera'),
                        _buildInfoRow(
                            'Light', widget.camera.hasLight ? 'Yes' : 'No'),
                        _buildInfoRow(
                            'Siren', widget.camera.hasSiren ? 'Yes' : 'No'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _toggleLight() async {
    try {
      // Get current light state from camera data
      // Use dynamic cast since data is AnyCameraData (union type)
      final currentState = (widget.camera.data as dynamic).ledStatus == 'on';
      await widget.camera.setLight(!currentState);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Light ${!currentState ? 'on' : 'off'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle light: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleSiren() async {
    try {
      // Get current siren state
      // Use dynamic cast since data is AnyCameraData (union type)
      final data = widget.camera.data as dynamic;
      final currentState = data.sirenStatus?.seconds != null &&
          data.sirenStatus!.seconds > 0;
      await widget.camera.setSiren(!currentState);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Siren ${!currentState ? 'on' : 'off'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle siren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getSnapshot() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final snapshot = await widget.camera.getSnapshot();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(snapshot),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get snapshot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
