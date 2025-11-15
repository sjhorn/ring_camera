import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:logging/logging.dart';
import 'package:ring_client_api/ring_client_api.dart';
import 'package:rxdart/rxdart.dart';

final _log = Logger('FlutterPeerConnection');

/// Flutter implementation of WebRTC peer connection for Ring cameras
///
/// Uses flutter_webrtc package to provide full WebRTC support including:
/// - Audio/video codec support (H.264, Opus, PCMU)
/// - ICE candidate handling
/// - STUN/TURN server support
/// - RTP/RTCP packet handling
class FlutterPeerConnection implements BasicPeerConnection {
  webrtc.RTCPeerConnection? _pc;
  final _onIceCandidateController = PublishSubject<RTCIceCandidate>();
  final _onConnectionStateController =
      ReplaySubject<ConnectionState>(maxSize: 1);

  /// Media stream for remote video/audio
  final onRemoteStream = PublishSubject<webrtc.MediaStream>();

  /// Local media stream for return audio
  webrtc.MediaStream? _localStream;

  /// Initialization future to ensure async setup completes
  late final Future<void> _initialized;

  FlutterPeerConnection() {
    _initialized = _initialize();
  }

  Future<void> _initialize() async {
    // Configure ICE servers for Ring cameras
    // IMPORTANT: Use 'max-compat' bundle policy for Ring compatibility
    // Ring servers expect unbundled media streams, but flutter_webrtc needs
    // bundling internally. We use 'max-compat' and strip BUNDLE from SDP later.
    final configuration = <String, dynamic>{
      'iceServers': ringIceServers
          .map((server) => {'urls': server})
          .toList(),
      'iceTransportPolicy': 'all',
      'bundlePolicy': 'max-compat',
    };

    _log.fine('Creating peer connection with ${ringIceServers.length} ICE servers');

    // Create peer connection
    final pc = await webrtc.createPeerConnection(configuration);
    _pc = pc;

    // Set up event handlers
    pc.onIceCandidate = (candidate) {
      if (!_onIceCandidateController.isClosed) {
        _onIceCandidateController.add(
          RTCIceCandidate(
            candidate: candidate.candidate ?? '',
            sdpMLineIndex: candidate.sdpMLineIndex,
            sdpMid: candidate.sdpMid,
          ),
        );
      }
    };

    // Monitor ICE connection state
    pc.onIceConnectionState = (state) {
      _log.fine('ICE connection state: $state');
      if (!_onConnectionStateController.isClosed) {
        _onConnectionStateController.add(_mapConnectionState(state));
      }
    };

    // Monitor peer connection state
    pc.onConnectionState = (state) {
      _log.fine('Peer connection state: $state');
      if (!_onConnectionStateController.isClosed) {
        _onConnectionStateController.add(_mapPeerConnectionState(state));
      }
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty && !onRemoteStream.isClosed) {
        onRemoteStream.add(event.streams[0]);
      }
    };

    // Add transceivers for Ring camera requirements
    await _setupTransceivers(pc);
  }

  Future<void> _setupTransceivers(webrtc.RTCPeerConnection pc) async {
    // Add audio transceiver (sendrecv for two-way audio)
    await pc.addTransceiver(
      kind: webrtc.RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: webrtc.RTCRtpTransceiverInit(
        direction: webrtc.TransceiverDirection.SendRecv,
      ),
    );

    // Add video transceiver (recvonly - we only receive video from camera)
    await pc.addTransceiver(
      kind: webrtc.RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: webrtc.RTCRtpTransceiverInit(
        direction: webrtc.TransceiverDirection.RecvOnly,
      ),
    );
  }

  @override
  Future<SessionDescription> createOffer() async {
    await _initialized;
    final offer = await _pc!.createOffer();

    // CRITICAL WORKAROUND: Ring server compatibility with flutter_webrtc bundling
    //
    // Problem: Ring servers expect unbundled media (separate ice-ufrag per m= line)
    // but flutter_webrtc always bundles media internally (same ice-ufrag).
    //
    // Solution:
    // 1. Set local description with ORIGINAL SDP (flutter_webrtc needs this)
    // 2. Remove BUNDLE line before sending to Ring server
    // 3. Use 'max-compat' bundle policy for best compatibility
    //
    // Without this, Ring server won't send remote ICE candidates and connection fails.
    await _pc!.setLocalDescription(offer);

    // Remove BUNDLE group line from SDP
    var sdp = offer.sdp ?? '';
    sdp = sdp.replaceAll(RegExp(r'^a=group:BUNDLE.*$', multiLine: true), '');
    sdp = sdp.replaceAll(RegExp(r'\n\n+'), '\n'); // Clean up double newlines

    _log.fine('SDP offer created, BUNDLE line removed for Ring compatibility');

    // Return modified SDP to send to server
    return SessionDescription(
      type: offer.type ?? 'offer',
      sdp: sdp,
    );
  }

  @override
  Future<void> acceptAnswer(SessionDescription answer) async {
    await _initialized;
    final rtcAnswer = webrtc.RTCSessionDescription(
      answer.sdp,
      answer.type,
    );
    await _pc!.setRemoteDescription(rtcAnswer);
  }

  @override
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _initialized;
    final rtcCandidate = webrtc.RTCIceCandidate(
      candidate.candidate,
      candidate.sdpMid,
      candidate.sdpMLineIndex,
    );
    await _pc!.addCandidate(rtcCandidate);
  }

  @override
  Stream<RTCIceCandidate> get onIceCandidate => _onIceCandidateController.stream;

  @override
  Stream<ConnectionState> get onConnectionState =>
      _onConnectionStateController.stream;

  @override
  void requestKeyFrame() {
    // Request PLI (Picture Loss Indication) for key frame
    // This is typically handled automatically by flutter_webrtc
    // but can be explicitly requested if needed
  }

  /// Set up local audio stream for return audio (two-way communication)
  Future<void> setupReturnAudio() async {
    await _initialized;
    if (_localStream != null) {
      return; // Already set up
    }

    try {
      _localStream = await webrtc.navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });

      // Add audio tracks to peer connection
      for (final track in _localStream!.getAudioTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }
    } catch (e) {
      _log.warning('Failed to set up return audio: $e');
      rethrow;
    }
  }

  /// Get remote video renderer
  ///
  /// Use this renderer to display video from the Ring camera
  webrtc.RTCVideoRenderer createVideoRenderer() {
    return webrtc.RTCVideoRenderer();
  }

  @override
  void close() {
    // First, clear event handlers to prevent new events
    if (_pc != null) {
      _pc!.onIceCandidate = null;
      _pc!.onIceConnectionState = null;
      _pc!.onConnectionState = null;
      _pc!.onTrack = null;
      _pc!.close();
    }

    // Then dispose local stream
    _localStream?.dispose();
    _localStream = null;

    // Finally, close stream controllers (order matters!)
    _onIceCandidateController.close();
    _onConnectionStateController.close();
    onRemoteStream.close();
  }

  // Helper methods to map flutter_webrtc states to our ConnectionState enum

  ConnectionState _mapConnectionState(webrtc.RTCIceConnectionState state) {
    switch (state) {
      case webrtc.RTCIceConnectionState.RTCIceConnectionStateNew:
        return ConnectionState.new_;
      case webrtc.RTCIceConnectionState.RTCIceConnectionStateChecking:
        return ConnectionState.connecting;
      case webrtc.RTCIceConnectionState.RTCIceConnectionStateConnected:
      case webrtc.RTCIceConnectionState.RTCIceConnectionStateCompleted:
        return ConnectionState.connected;
      case webrtc.RTCIceConnectionState.RTCIceConnectionStateFailed:
        return ConnectionState.failed;
      case webrtc.RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        return ConnectionState.disconnected;
      case webrtc.RTCIceConnectionState.RTCIceConnectionStateClosed:
        return ConnectionState.closed;
      default:
        return ConnectionState.new_;
    }
  }

  ConnectionState _mapPeerConnectionState(webrtc.RTCPeerConnectionState state) {
    return switch (state) {
      webrtc.RTCPeerConnectionState.RTCPeerConnectionStateNew =>
        ConnectionState.new_,
      webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnecting =>
        ConnectionState.connecting,
      webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected =>
        ConnectionState.connected,
      webrtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed =>
        ConnectionState.failed,
      webrtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected =>
        ConnectionState.disconnected,
      webrtc.RTCPeerConnectionState.RTCPeerConnectionStateClosed =>
        ConnectionState.closed,
    };
  }
}
