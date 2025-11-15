import 'package:flutter_test/flutter_test.dart';
import 'package:ring_camera/ring_camera.dart';

void main() {
  test('package exports core ring_client_api', () {
    // Verify that core classes are accessible
    expect(RingApi, isNotNull);
    expect(RingCamera, isNotNull);
    expect(Location, isNotNull);
  });

  test('package exports Flutter-specific classes', () {
    // Verify Flutter-specific classes are accessible
    expect(FlutterPeerConnection, isNotNull);
    expect(RingCameraViewer, isNotNull);
    expect(RingCameraSnapshotViewer, isNotNull);
  });
}
