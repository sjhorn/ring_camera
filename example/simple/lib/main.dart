import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flutter;

import 'package:ring_camera/ring_camera.dart';

void main() async {
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String refreshIdToken = '';
  String cameraId = '';
  final _formKey = GlobalKey<FormState>();
  final _refreshTokenController = TextEditingController();
  final _cameraIdController = TextEditingController();

  @override
  void dispose() {
    _refreshTokenController.dispose();
    _cameraIdController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        refreshIdToken = _refreshTokenController.text;
        cameraId = _cameraIdController.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = refreshIdToken.isNotEmpty && cameraId.isNotEmpty;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Ring Camera')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _refreshTokenController,
                      decoration: const InputDecoration(
                        labelText: 'Refresh Token',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter refresh token';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cameraIdController,
                      decoration: const InputDecoration(labelText: 'Camera ID'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter camera ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
              if (hasData) ...[
                const SizedBox(height: 24),
                Expanded(
                  child: CameraWidget(
                    refreshToken: refreshIdToken,
                    cameraId: int.parse(cameraId),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CameraWidget extends StatelessWidget {
  final String refreshToken;
  final int cameraId;
  const CameraWidget({
    super.key,
    required this.refreshToken,
    required this.cameraId,
  });

  Future<RingCamera?> fetchData() async {
    final ringApi = RingApi(RefreshTokenAuth(refreshToken: refreshToken));
    return ringApi.getCamera(cameraId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RingCamera?>(
      future: fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == flutter.ConnectionState.waiting) {
          return Center(child: Text('Loading...'));
        }

        if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }

        return RingCameraViewer(camera: snapshot.data!);
      },
    );
  }
}
