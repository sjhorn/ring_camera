import 'dart:async';
import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:logging/logging.dart';
import 'package:ring_client_api/ring_client_api.dart';
import 'flutter_peer_connection.dart';
import 'webrtc_connection.dart';

final _log = Logger('RingCameraRecorder');

/// Records video from a Ring camera to a file
///
/// This class manages the WebRTC connection and MediaRecorder to capture
/// video from a Ring camera and save it to a local file.
///
/// Uses flutter_webrtc's MediaRecorder for native recording without FFmpeg.
///
/// Example usage:
/// ```dart
/// final recorder = RingCameraRecorder(
///   camera: myCamera,
///   outputPath: '/path/to/output.mp4',
///   duration: 10, // seconds
/// );
///
/// await recorder.startRecording();
/// ```
class RingCameraRecorder {
  final RingCamera camera;
  final String outputPath;
  final int durationSeconds;
  final void Function(String message)? onProgress;
  final void Function(Object error)? onError;

  FlutterWebrtcConnection? _connection;
  FlutterPeerConnection? _peerConnection;
  Timer? _durationTimer;
  Timer? _frameCaptureTimer;
  bool _isRecording = false;
  bool _isStopped = false;
  final List<String> _framePaths = [];

  RingCameraRecorder({
    required this.camera,
    required this.outputPath,
    required this.durationSeconds,
    this.onProgress,
    this.onError,
  });

  /// Start recording video from the camera
  Future<void> startRecording() async {
    if (_isRecording) {
      throw StateError('Recording already in progress');
    }

    _isRecording = true;
    _isStopped = false;
    _log.info('Starting recording for $durationSeconds seconds to $outputPath');
    onProgress?.call('Connecting to camera...');

    try {
      // Get WebRTC ticket
      onProgress?.call('Requesting ticket...');
      _log.info('Requesting WebRTC ticket for camera ${camera.id}');
      final ticket = await camera.createWebrtcTicket();
      _log.info('Got ticket, length: ${ticket.length}');

      // Create peer connection
      onProgress?.call('Creating connection...');
      _log.info('Creating FlutterPeerConnection');
      _peerConnection = FlutterPeerConnection();
      _log.info('FlutterPeerConnection created (will initialize asynchronously)');

      // Listen for remote stream - same pattern as RingCameraViewer
      final streamCompleter = Completer<webrtc.MediaStream>();

      _log.info('Setting up onRemoteStream listener');
      _peerConnection!.onRemoteStream.listen((stream) {
        _log.info('onRemoteStream fired! Stream: ${stream.id}');
        final videoTracks = stream.getVideoTracks();
        _log.info('Stream has ${videoTracks.length} video tracks');

        if (!streamCompleter.isCompleted && videoTracks.isNotEmpty) {
          _log.info('Completing with stream that has video tracks');
          streamCompleter.complete(stream);
        } else if (videoTracks.isEmpty) {
          _log.warning('Ignoring stream with no video tracks');
        } else {
          _log.warning('Stream completer already completed, ignoring stream');
        }
      });

      // Create WebRTC connection - exactly like RingCameraViewer does
      _log.info('Creating FlutterWebrtcConnection');
      _connection = FlutterWebrtcConnection(
        ticket: ticket,
        camera: camera,
        peerConnection: _peerConnection,
      );
      _log.info('FlutterWebrtcConnection created');

      // Handle connection errors
      _connection!.onError.listen((error) {
        _log.severe('Connection error: $error');
        onError?.call(error);
        stopRecording();
      });

      // Wait for remote stream (same timeout as RingCameraViewer)
      onProgress?.call('Waiting for video stream...');
      _log.info('Waiting for remote stream (30s timeout)...');
      final stream = await streamCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log.severe('Timeout waiting for video stream!');
          throw TimeoutException('Failed to receive video stream');
        },
      );
      _log.info('Stream received!');

      onProgress?.call('Stream connected, starting recording...');

      // Start recording using MediaRecorder
      await _startMediaRecording(stream);
    } catch (e) {
      _log.severe('Failed to start recording: $e');
      onError?.call(e);
      await stopRecording();
      rethrow;
    }
  }

  /// Record using frame capture + FFmpeg encoding
  Future<void> _startMediaRecording(webrtc.MediaStream stream) async {
    if (_isStopped) return;

    try {
      // Get video tracks from stream
      final videoTracks = stream.getVideoTracks();
      _log.info('Stream has ${videoTracks.length} video tracks');

      if (videoTracks.isEmpty) {
        throw StateError('No video tracks available in stream');
      }

      final videoTrack = videoTracks.first;
      _log.info('Video track: ${videoTrack.id}, kind: ${videoTrack.kind}, enabled: ${videoTrack.enabled}');

      // Create temporary directory for frames
      final tempDir = Directory.systemTemp.createTempSync('ring_recording_');
      _log.info('Storing frames in ${tempDir.path}');

      onProgress?.call('Recording video...');
      _log.info('Starting frame capture for $durationSeconds seconds');

      // Record start time
      final startTime = DateTime.now();
      final endTime = startTime.add(Duration(seconds: durationSeconds));
      _log.info('Recording from $startTime to $endTime');

      // Capture frames until duration is reached
      int frameCount = 0;
      while (_isRecording && !_isStopped && DateTime.now().isBefore(endTime)) {
        final loopStartTime = DateTime.now();
        final remainingTime = endTime.difference(loopStartTime);

        if (frameCount % 10 == 0) {
          _log.info('Frame $frameCount, remaining: ${remainingTime.inSeconds}s, _isRecording=$_isRecording, _isStopped=$_isStopped');
        }
        try {
          final frameStartTime = DateTime.now();

          // Capture frame
          final frame = await videoTrack.captureFrame();
          final framePath = '${tempDir.path}/frame_${frameCount.toString().padLeft(6, '0')}.png';

          // Save frame
          await File(framePath).writeAsBytes(frame.asUint8List());
          _framePaths.add(framePath);

          frameCount++;

          // Progress update every 30 frames
          if (frameCount % 30 == 0) {
            final elapsed = DateTime.now().difference(startTime).inSeconds;
            onProgress?.call('Recording... ${elapsed}s / $durationSeconds s');
            _log.info('Captured $frameCount frames in ${elapsed}s');
          }

          // Calculate delay to maintain ~30fps
          final frameDuration = DateTime.now().difference(frameStartTime);
          final targetFrameTime = const Duration(milliseconds: 33);
          final delay = targetFrameTime - frameDuration;

          if (delay.isNegative) {
            _log.fine('Frame capture took ${frameDuration.inMilliseconds}ms (target: 33ms)');
          } else {
            await Future.delayed(delay);
          }
        } catch (e) {
          _log.warning('Error capturing frame: $e');
        }
      }

      _isRecording = false;
      final actualDuration = DateTime.now().difference(startTime);
      final actualSeconds = actualDuration.inMilliseconds / 1000.0;
      final fps = frameCount / actualSeconds;
      _log.info('Capture complete: $frameCount frames in ${actualSeconds.toStringAsFixed(2)}s (${fps.toStringAsFixed(1)} fps)');
      _log.info('Loop exit reason: _isRecording=$_isRecording, _isStopped=$_isStopped, time=${DateTime.now().isAfter(endTime) ? "expired" : "remaining"}');

      if (_framePaths.isEmpty) {
        throw StateError('No frames captured');
      }

      _log.info('Captured ${_framePaths.length} frames');
      onProgress?.call('Processing video with FFmpeg...');

      // Encode with FFmpeg using actual FPS
      await _encodeFramesToVideo(tempDir.path, fps);

      // Cleanup
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        _log.warning('Failed to cleanup temp directory: $e');
      }

      onProgress?.call('Recording complete!');
    } catch (e) {
      _log.severe('Error during recording: $e');
      onError?.call(e);
      rethrow;
    }
  }

  /// Encode captured frames to video using FFmpeg
  Future<void> _encodeFramesToVideo(String framesDir, double fps) async {
    // Use actual FPS from capture instead of hardcoded 30fps
    // This ensures the video duration matches the recording duration
    final fpsRounded = fps.toStringAsFixed(2);
    _log.info('Encoding with framerate: $fpsRounded fps');

    // FFmpeg command: frames → MP4
    final command = '-framerate $fpsRounded '
        '-pattern_type glob -i "$framesDir/*.png" '
        '-c:v libx264 '
        '-pix_fmt yuv420p '
        '-movflags +faststart '
        '-y "$outputPath"';

    _log.info('Running FFmpeg: ffmpeg $command');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      _log.info('Video created successfully at $outputPath');

      // Verify file
      final file = File(outputPath);
      if (await file.exists()) {
        final size = await file.length();
        _log.info('Output file size: $size bytes');
      }
    } else {
      final output = await session.getOutput();
      final errorMessage = 'FFmpeg failed with return code $returnCode\n$output';
      _log.severe(errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// Stop recording and cleanup resources
  Future<void> stopRecording() async {
    if (_isStopped) return;

    _log.info('Stopping recording');
    _isStopped = true;
    _isRecording = false;

    _durationTimer?.cancel();
    _frameCaptureTimer?.cancel();

    // Close WebRTC connection
    if (_connection != null) {
      try {
        _connection!.stop();
      } catch (e) {
        _log.warning('Error stopping connection: $e');
      }
    }
  }
}

/// Helper function to record video from a Ring camera
///
/// This is a convenience function that creates a recorder and waits
/// for the recording to complete.
///
/// Example:
/// ```dart
/// await recordCameraToFile(
///   camera: myCamera,
///   outputPath: '/path/to/video.mp4',
///   durationSeconds: 10,
///   onProgress: (message) => print(message),
/// );
/// ```
Future<void> recordCameraToFile({
  required RingCamera camera,
  required String outputPath,
  required int durationSeconds,
  void Function(String message)? onProgress,
  void Function(Object error)? onError,
}) async {
  final recorder = RingCameraRecorder(
    camera: camera,
    outputPath: outputPath,
    durationSeconds: durationSeconds,
    onProgress: onProgress,
    onError: onError,
  );

  await recorder.startRecording();

  // Wait for recording to complete (duration + 1 second buffer)
  await Future.delayed(Duration(seconds: durationSeconds + 1));

  // Ensure cleanup
  await recorder.stopRecording();
}
