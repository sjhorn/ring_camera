import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:ring_client_api/ring_client_api.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'flutter_peer_connection.dart';

final _log = Logger('WebrtcConnection');

/// Flutter implementation of WebRTC connection for Ring camera streaming
///
/// Manages the WebSocket signaling and WebRTC peer connection lifecycle:
/// 1. Connects to Ring's WebSocket signaling server
/// 2. Creates SDP offer and sends to camera
/// 3. Receives SDP answer and ICE candidates
/// 4. Establishes WebRTC connection
/// 5. Maintains connection with periodic pings
class FlutterWebrtcConnection {
  final String _ticket;
  final RingCamera _camera;
  final String _dialogId;
  final FlutterPeerConnection _peerConnection;

  WebSocketChannel? _ws;
  String? _sessionId;
  bool _hasEnded = false;
  Timer? _pingTimer;
  bool _offerSent = false;

  // Observables for connection state
  final _onSessionIdController = ReplaySubject<String>(maxSize: 1);
  final _onOfferSentController = ReplaySubject<void>(maxSize: 1);
  final _onCameraConnectedController = ReplaySubject<void>(maxSize: 1);
  final _onCallAnsweredController = ReplaySubject<String>(maxSize: 1);
  final _onCallEndedController = ReplaySubject<void>(maxSize: 1);
  final _onErrorController = ReplaySubject<Object>(maxSize: 1);
  final _onMessageController = PublishSubject<Map<String, dynamic>>();
  final _onWsOpenController = ReplaySubject<void>(maxSize: 1);

  // Public streams
  Stream<String> get onSessionId => _onSessionIdController.stream;
  Stream<void> get onOfferSent => _onOfferSentController.stream;
  Stream<void> get onCameraConnected => _onCameraConnectedController.stream;
  Stream<String> get onCallAnswered => _onCallAnsweredController.stream;
  Stream<void> get onCallEnded => _onCallEndedController.stream;
  Stream<Object> get onError => _onErrorController.stream;
  Stream<Map<String, dynamic>> get onMessage => _onMessageController.stream;
  Stream<void> get onWsOpen => _onWsOpenController.stream;

  // Audio/Video RTP streams (pass-through from peer connection for now)
  Stream<dynamic> get onAudioRtp => const Stream.empty();
  Stream<dynamic> get onVideoRtp => const Stream.empty();

  FlutterWebrtcConnection({
    required String ticket,
    required RingCamera camera,
    FlutterPeerConnection? peerConnection,
  })  : _ticket = ticket,
        _camera = camera,
        _dialogId = const Uuid().v4(),
        _peerConnection = peerConnection ?? FlutterPeerConnection() {
    _initialize();
  }

  void _initialize() {
    _log.info('Initializing WebRTC connection for camera ${_camera.id}');

    // Connect to WebSocket signaling server
    _connectWebSocket();

    // Handle ICE candidates from peer connection
    _peerConnection.onIceCandidate.listen((candidate) {
      _log.info('Local ICE candidate: ${candidate.candidate}');
      _sendIceCandidate(candidate);
    });

    // Handle connection state changes
    _peerConnection.onConnectionState.listen((state) {
      _log.info('WebRTC connection state: $state');

      if (state == ConnectionState.failed ||
          state == ConnectionState.closed) {
        _handleError('WebRTC connection $state');
      }
    });
  }

  void _connectWebSocket() {
    final wsUrl = Uri.parse(
      'wss://api.prod.signalling.ring.devices.a2z.com:443/ws'
      '?api_version=4.0'
      '&auth_type=ring_solutions'
      '&client_id=ring_site-$_dialogId'
      '&token=$_ticket',
    );

    _log.info('Connecting to WebSocket: ${wsUrl.toString().replaceAll(_ticket, '***')}');

    try {
      // IMPORTANT: User-Agent header is REQUIRED or the socket closes immediately
      // Ring's signaling server validates this header
      _ws = IOWebSocketChannel.connect(
        wsUrl,
        headers: {
          'User-Agent': 'android:com.ringapp',
        },
      );

      _log.fine('WebSocket connected, setting up listeners');
      _onWsOpenController.add(null);

      // Listen for messages
      _ws!.stream.listen(
        _handleWebSocketMessage,
        onError: (error) {
          _log.severe('WebSocket error: $error');
          _handleError(error);
        },
        onDone: () {
          _log.info('WebSocket closed');
          if (!_hasEnded) {
            _handleCallEnded();
          }
        },
      );

      // Start sending periodic pings to keep connection alive
      _startPingTimer();

      // Initiate call once WebSocket is connected
      _initiateCall();
    } catch (e) {
      _log.severe('Failed to connect WebSocket: $e');
      _handleError(e);
    }
  }

  void _startPingTimer() {
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_hasEnded && _sessionId != null) {
        _log.info('Sending ping to keep connection alive');
        // Use _sendSessionMessage to ensure dialog_id is included
        _sendSessionMessage({
          'method': 'ping',
          'body': {
            'doorbot_id': _camera.id,
            'session_id': _sessionId,
          },
        });
      }
    });
  }

  Future<void> _initiateCall() async {
    try {
      _log.info('Creating SDP offer for camera ${_camera.id}');

      // Create SDP offer (BUNDLE line will be removed by peer connection)
      final offer = await _peerConnection.createOffer();
      _log.fine('SDP offer created: ${offer.sdp.length} chars');

      // Send live_view message with offer to start streaming
      _sendMessage({
        'method': 'live_view',
        'dialog_id': _dialogId,
        'body': {
          'doorbot_id': _camera.id,
          'stream_options': {
            'audio_enabled': true,
            'video_enabled': true,
          },
          'sdp': offer.sdp,
        },
      });

      _offerSent = true;
      _onOfferSentController.add(null);
      _log.info('SDP offer sent to camera');
    } catch (e) {
      _log.severe('Failed to initiate call: $e');
      _handleError(e);
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final method = json['method'] as String?;
      _log.fine('Received message: $method');

      _onMessageController.add(json);

      final incomingMessage = IncomingMessage(json);

      // Handle different message types
      if (incomingMessage.method == 'session_created') {
        final msg = incomingMessage.asSessionCreated!;
        _sessionId = msg.body.sessionId;
        _onSessionIdController.add(_sessionId!);
        _log.info('Session created: $_sessionId');
      }
      else if (incomingMessage.method == 'sdp') {
        final msg = incomingMessage.asAnswer!;
        _log.info('Received SDP answer from camera');
        _handleAnswer(msg.body.sdp);

        // IMPORTANT: Send activation AFTER accepting answer (required by Ring protocol)
        // This keeps the stream alive longer than 70 seconds
        _activate();
      }
      else if (incomingMessage.method == 'ice') {
        final msg = incomingMessage.asIceCandidate!;
        _log.fine('Received remote ICE candidate');
        _handleIceCandidate(msg.body.ice, msg.body.mlineindex);
      }
      else if (incomingMessage.method == 'camera_started') {
        _log.info('Camera started');
        _onCameraConnectedController.add(null);
      }
      else if (incomingMessage.method == 'notification') {
        final msg = incomingMessage.asNotification!;
        _log.info('Notification: ${msg.body.text} (ok: ${msg.body.isOk})');

        if (!msg.body.isOk) {
          _handleError('Camera notification error: ${msg.body.text}');
        }
      }
      else if (incomingMessage.method == 'close') {
        final msg = incomingMessage.asClose!;
        _log.info('Call ended by server: ${msg.body.reason.text}');
        _handleCallEnded();
      }
      else if (incomingMessage.method == 'pong') {
        // Pong received, connection is alive
        _log.finest('Pong received');
      }
      else if (incomingMessage.method == 'session_started') {
        _log.info('Session started');
      }
      else if (incomingMessage.method == 'stream_info') {
        final msg = incomingMessage.asStreamInfo!;
        _log.info('Stream info - transcoding: ${msg.body.transcoding}, '
                  'reason: ${msg.body.transcodingReason}');
      }
      else {
        _log.warning('Unknown message method: ${incomingMessage.method}');
      }
    } catch (e) {
      _log.severe('Error handling WebSocket message: $e');
      _handleError(e);
    }
  }

  void _handleAnswer(String sdp) {
    try {
      _peerConnection.acceptAnswer(SessionDescription(
        type: 'answer',
        sdp: sdp,
      ));

      _onCallAnsweredController.add(sdp);
      _log.info('SDP answer accepted');
    } catch (e) {
      _log.severe('Failed to accept answer: $e');
      _handleError(e);
    }
  }

  void _handleIceCandidate(String candidate, int sdpMLineIndex) {
    try {
      _peerConnection.addIceCandidate(RTCIceCandidate(
        candidate: candidate,
        sdpMLineIndex: sdpMLineIndex,
        sdpMid: null,
      ));

      _log.fine('Remote ICE candidate added');
    } catch (e) {
      _log.severe('Failed to add ICE candidate: $e');
      _handleError(e);
    }
  }

  void _sendIceCandidate(RTCIceCandidate candidate) {
    if (candidate.candidate.isEmpty) {
      return;
    }

    // Wait for offer to be sent first (prevents race condition)
    if (!_offerSent) {
      _log.fine('ICE candidate generated before offer sent, waiting...');
      return;
    }

    // Send ICE candidate with dialog_id (required by Ring signaling protocol)
    _sendMessage({
      'method': 'ice',
      'dialog_id': _dialogId,
      'body': {
        'doorbot_id': _camera.id,
        'ice': candidate.candidate,
        'mlineindex': candidate.sdpMLineIndex ?? 0,
      },
    });
    _log.fine('Local ICE candidate sent');
  }

  void _activate() {
    _log.info('ACTIVATING session (keeps stream alive >70s)');

    // IMPORTANT: Send TWO separate messages (required by Ring signaling protocol)
    // 1. activate_session - Activates the streaming session
    _sendSessionMessage({
      'method': 'activate_session',
      'body': {
        'doorbot_id': _camera.id,
        'session_id': _sessionId,
      },
    });
    _log.info('Sent activate_session message');

    // 2. stream_options - Configures audio/video preferences
    _sendSessionMessage({
      'method': 'stream_options',
      'body': {
        'doorbot_id': _camera.id,
        'session_id': _sessionId,
        'audio_enabled': true,
        'video_enabled': true,
      },
    });
    _log.info('Sent stream_options message - session fully activated');
  }

  void _sendSessionMessage(Map<String, dynamic> message) {
    // IMPORTANT: Add dialog_id to all session messages (required by Ring protocol)
    final messageWithDialogId = {
      ...message,
      'dialog_id': _dialogId,
    };

    if (_sessionId != null) {
      _sendMessage(messageWithDialogId);
    } else {
      // Queue message until session is created
      onSessionId.first.then((_) => _sendMessage(messageWithDialogId));
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_hasEnded || _ws == null) {
      _log.warning('Cannot send message - connection ended');
      return;
    }

    try {
      final json = jsonEncode(message);
      _ws!.sink.add(json);
      _log.fine('Sent message: ${message['method']}');
    } catch (e) {
      _log.severe('Failed to send message: $e');
      _handleError(e);
    }
  }

  void _handleError(Object error) {
    _onErrorController.add(error);
  }

  void _handleCallEnded() {
    if (_hasEnded) {
      return;
    }

    _hasEnded = true;
    _onCallEndedController.add(null);
    _cleanup();
  }

  /// Request a key frame from the camera
  void requestKeyFrame() {
    _peerConnection.requestKeyFrame();
  }

  /// Activate the camera speaker for two-way audio
  void activateCameraSpeaker() {
    if (_sessionId == null || _hasEnded) {
      return;
    }

    _sendSessionMessage({
      'method': 'activate_camera_speaker',
      'body': {
        'doorbot_id': _camera.id,
        'session_id': _sessionId,
      },
    });
    _log.info('Camera speaker activation requested');
  }

  /// Stop the streaming connection
  void stop() {
    _log.info('Stopping WebRTC connection');
    _handleCallEnded();
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _pingTimer = null;

    _ws?.sink.close();
    _ws = null;

    _peerConnection.close();

    // Close all streams
    _onSessionIdController.close();
    _onOfferSentController.close();
    _onCameraConnectedController.close();
    _onCallAnsweredController.close();
    _onCallEndedController.close();
    _onErrorController.close();
    _onMessageController.close();
    _onWsOpenController.close();
  }

  /// Get the peer connection for accessing remote media stream
  FlutterPeerConnection get peerConnection => _peerConnection;
}
