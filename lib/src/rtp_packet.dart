import 'dart:typed_data';

/// Simple RTP packet builder for G.711 μ-law audio
///
/// This is a basic implementation of RTP (RFC 3550) for sending
/// G.711 μ-law audio to Ring cameras. It creates properly formatted
/// RTP packets with headers and payload.
///
/// **Note**: This is a simplified implementation for proof-of-concept.
/// A production implementation would need:
/// - SRTP encryption
/// - More robust timestamp handling
/// - RTCP support
/// - Jitter buffer
class RtpPacket {
  /// RTP version (always 2)
  static const int version = 2;

  /// Payload type for PCMU (G.711 μ-law)
  static const int payloadTypePCMU = 0;

  /// Clock rate for PCMU (8kHz)
  static const int clockRate = 8000;

  final int sequenceNumber;
  final int timestamp;
  final int ssrc;
  final Uint8List payload;
  final int payloadType;

  RtpPacket({
    required this.sequenceNumber,
    required this.timestamp,
    required this.ssrc,
    required this.payload,
    this.payloadType = payloadTypePCMU,
  });

  /// Serialize the RTP packet to bytes
  Uint8List toBytes() {
    final packet = ByteData(12 + payload.length);

    // Byte 0: V(2), P(1), X(1), CC(4)
    // V=2, P=0, X=0, CC=0
    packet.setUint8(0, (version << 6));

    // Byte 1: M(1), PT(7)
    // M=0 (not last packet), PT=0 (PCMU)
    packet.setUint8(1, payloadType & 0x7F);

    // Bytes 2-3: Sequence number
    packet.setUint16(2, sequenceNumber & 0xFFFF);

    // Bytes 4-7: Timestamp
    packet.setUint32(4, timestamp);

    // Bytes 8-11: SSRC
    packet.setUint32(8, ssrc);

    // Bytes 12+: Payload
    final buffer = packet.buffer.asUint8List();
    buffer.setRange(12, 12 + payload.length, payload);

    return buffer;
  }

  /// Create an RTP packet from bytes
  static RtpPacket fromBytes(Uint8List bytes) {
    if (bytes.length < 12) {
      throw ArgumentError('RTP packet must be at least 12 bytes');
    }

    final packet = ByteData.view(bytes.buffer);

    final version = (packet.getUint8(0) >> 6) & 0x03;
    if (version != 2) {
      throw ArgumentError('Invalid RTP version: $version');
    }

    final payloadType = packet.getUint8(1) & 0x7F;
    final sequenceNumber = packet.getUint16(2);
    final timestamp = packet.getUint32(4);
    final ssrc = packet.getUint32(8);

    final payload = Uint8List.fromList(bytes.sublist(12));

    return RtpPacket(
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      ssrc: ssrc,
      payload: payload,
      payloadType: payloadType,
    );
  }
}

/// Builder for creating RTP packets with automatic sequencing
class RtpPacketBuilder {
  int _sequenceNumber = 0;
  int _timestamp = 0;
  final int ssrc;
  final int payloadType;
  final int clockRate;

  RtpPacketBuilder({
    int? ssrc,
    this.payloadType = RtpPacket.payloadTypePCMU,
    this.clockRate = RtpPacket.clockRate,
  }) : ssrc = ssrc ?? DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;

  /// Create the next RTP packet with the given payload
  ///
  /// [payload] - The audio data (e.g., μ-law samples)
  /// [duration] - Duration of this packet's audio in milliseconds
  RtpPacket createPacket(Uint8List payload, {int? duration}) {
    final packet = RtpPacket(
      sequenceNumber: _sequenceNumber,
      timestamp: _timestamp,
      ssrc: ssrc,
      payload: payload,
      payloadType: payloadType,
    );

    // Increment sequence number (wraps at 65536)
    _sequenceNumber = (_sequenceNumber + 1) & 0xFFFF;

    // Increment timestamp based on payload duration
    // For PCMU: 8000 Hz clock, so 8 samples per ms
    if (duration != null) {
      _timestamp += (duration * clockRate ~/ 1000);
    } else {
      // Default: assume payload length equals number of samples
      _timestamp += payload.length;
    }

    return packet;
  }

  /// Reset the builder state
  void reset() {
    _sequenceNumber = 0;
    _timestamp = 0;
  }
}
