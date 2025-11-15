import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:ring_client_api/ring_client_api.dart' as ring;
import 'flutter_peer_connection.dart';
import 'webrtc_connection.dart';

/// Widget for displaying live video stream from a Ring camera
///
/// This widget handles the complete WebRTC connection lifecycle:
/// - Creating peer connection
/// - Establishing WebRTC stream
/// - Displaying video
/// - Handling connection state
/// - Cleanup on dispose
///
/// Example usage:
/// ```dart
/// RingCameraViewer(
///   camera: ringCamera,
///   onError: (error) => print('Stream error: $error'),
///   onConnectionStateChanged: (state) => print('Connection: $state'),
/// )
/// ```
class RingCameraViewer extends StatefulWidget {
  /// The Ring camera to stream from
  final ring.RingCamera camera;

  /// Callback when an error occurs
  final void Function(Object error)? onError;

  /// Callback when connection state changes
  final void Function(String state)? onConnectionStateChanged;

  /// Whether to show connection status overlay
  final bool showStatus;

  /// Whether to enable two-way audio
  final bool enableReturnAudio;

  const RingCameraViewer({
    super.key,
    required this.camera,
    this.onError,
    this.onConnectionStateChanged,
    this.showStatus = true,
    this.enableReturnAudio = false,
  });

  @override
  State<RingCameraViewer> createState() => _RingCameraViewerState();
}

class _RingCameraViewerState extends State<RingCameraViewer> {
  final _renderer = webrtc.RTCVideoRenderer();
  FlutterWebrtcConnection? _connection;
  String _connectionState = 'Initializing...';
  bool _isInitialized = false;
  Object? _error;
  Timer? _connectionTimeout;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    try {
      // Initialize video renderer
      await _renderer.initialize();
      setState(() {
        _connectionState = 'Requesting ticket...';
        _error = null;
      });

      // Get WebRTC ticket from Ring
      final ticket = await widget.camera.createWebrtcTicket();

      setState(() => _connectionState = 'Creating connection...');

      // Create peer connection
      final peerConnection = FlutterPeerConnection();

      // Set up return audio if enabled
      if (widget.enableReturnAudio) {
        await peerConnection.setupReturnAudio();
      }

      // Set connection timeout (30 seconds for initial connection)
      _connectionTimeout = Timer(const Duration(seconds: 30), () {
        if (!_isInitialized && mounted) {
          _handleConnectionTimeout();
        }
      });

      // Listen for connection state changes
      peerConnection.onConnectionState.listen((state) {
        if (!mounted) return;

        final stateStr = state.toString().split('.').last;
        setState(() {
          _connectionState = stateStr;
        });
        widget.onConnectionStateChanged?.call(state.toString());

        // Clear timeout on failed or closed state
        if (state == ring.ConnectionState.failed ||
            state == ring.ConnectionState.closed) {
          _connectionTimeout?.cancel();
        }
      });

      // Listen for remote stream
      peerConnection.onRemoteStream.listen((stream) {
        if (!mounted) return;

        _connectionTimeout?.cancel();

        setState(() {
          _renderer.srcObject = stream;
          _isInitialized = true;
          _connectionState = 'Connected';
          _error = null;
        });
      });

      // Create WebRTC connection with signaling
      setState(() => _connectionState = 'Establishing connection...');
      final connection = FlutterWebrtcConnection(
        ticket: ticket,
        camera: widget.camera,
        peerConnection: peerConnection,
      );
      _connection = connection;

      // Listen for connection events
      connection.onError.listen((error) {
        if (!mounted) return;
        _connectionTimeout?.cancel();

        setState(() {
          _connectionState = 'Connection failed';
          _error = error;
        });
        widget.onError?.call(error);
      });

      connection.onCallEnded.listen((_) {
        if (!mounted) return;
        _connectionTimeout?.cancel();

        setState(() {
          _connectionState = 'Call ended';
          _isInitialized = false;
        });
      });

      connection.onCameraConnected.listen((_) {
        if (!mounted) return;
        setState(() => _connectionState = 'Camera connected');
      });
    } catch (e) {
      if (!mounted) return;
      _connectionTimeout?.cancel();

      setState(() {
        _connectionState = 'Connection failed';
        _error = e;
      });
      widget.onError?.call(e);
    }
  }

  void _handleConnectionTimeout() {
    setState(() {
      _connectionState = 'Connection timed out';
      _error =
          TimeoutException('Failed to connect to camera within 30 seconds');
    });
    widget.onError?.call(_error!);
    _connection?.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video display
        if (_isInitialized)
          SizedBox.expand(
            child: webrtc.RTCVideoView(
              _renderer,
              objectFit:
                  webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          )
        else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _connectionState,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),

        // Status overlay
        if (widget.showStatus)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 12,
                    color: _getStatusColor(),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _connectionState,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  IconData _getStatusIcon() {
    if (_connectionState.contains('Connected')) {
      return Icons.videocam;
    } else if (_connectionState.contains('Error')) {
      return Icons.error;
    } else {
      return Icons.sync;
    }
  }

  Color _getStatusColor() {
    if (_connectionState.contains('Connected')) {
      return Colors.green;
    } else if (_connectionState.contains('Error')) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  @override
  void dispose() {
    _connectionTimeout?.cancel();
    _renderer.dispose();
    _connection?.stop();
    super.dispose();
  }
}

/// Simplified camera viewer for snapshots (non-streaming)
///
/// Displays periodic snapshots from the camera instead of live video.
/// Useful for battery-powered cameras or when full streaming isn't needed.
class RingCameraSnapshotViewer extends StatefulWidget {
  final ring.RingCamera camera;
  final Duration refreshInterval;

  const RingCameraSnapshotViewer({
    super.key,
    required this.camera,
    this.refreshInterval = const Duration(seconds: 10),
  });

  @override
  State<RingCameraSnapshotViewer> createState() =>
      _RingCameraSnapshotViewerState();
}

class _RingCameraSnapshotViewerState extends State<RingCameraSnapshotViewer> {
  Image? _currentSnapshot;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
    // Set up periodic refresh
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(widget.refreshInterval);
      if (mounted) {
        _loadSnapshot();
      }
      return mounted;
    });
  }

  Future<void> _loadSnapshot() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final bytes = await widget.camera.getSnapshot();

      if (mounted) {
        setState(() {
          _currentSnapshot = Image.memory(
            bytes,
            fit: BoxFit.cover,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load snapshot: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSnapshot,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        if (_currentSnapshot != null) SizedBox.expand(child: _currentSnapshot!),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
