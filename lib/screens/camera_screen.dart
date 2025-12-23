import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isPermissionDenied = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isPermissionDenied = false;
      _errorMessage = null;
    });

    final status = await Permission.camera.request();

    if (!status.isGranted) {
      setState(() => _isPermissionDenied = true);
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No camera available on this device.');
        return;
      }

      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _controller = controller;
      _initializeControllerFuture = controller.initialize();

      setState(() {});
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize camera: $e');
    }
  }

  Future<void> _captureAndNavigate() async {
    final controller = _controller;
    final initializeFuture = _initializeControllerFuture;

    if (controller == null || initializeFuture == null) {
      return;
    }

    try {
      setState(() => _isSaving = true);
      await initializeFuture;
      final image = await controller.takePicture();
      final savedPath = await _persistImage(image);
      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultScreen(imagePath: savedPath)),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  Future<String> _persistImage(XFile file) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'scan_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final savedPath = p.join(directory.path, fileName);
    await File(file.path).copy(savedPath);
    return savedPath;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan product'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        color: Colors.black,
        child: SafeArea(child: Center(child: _buildCameraContent(colorScheme))),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: FilledButton.icon(
          icon: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt_outlined),
          onPressed: (_controller == null || _isSaving)
              ? null
              : _captureAndNavigate,
          label: Text(_isSaving ? 'Saving...' : 'Capture ingredients'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraContent(ColorScheme colorScheme) {
    if (_isPermissionDenied) {
      return _PermissionMessage(onOpenSettings: openAppSettings);
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _initializeCamera,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final initializeFuture = _initializeControllerFuture;
    final controller = _controller;

    if (controller == null || initializeFuture == null) {
      return const CircularProgressIndicator();
    }

    return FutureBuilder(
      future: initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CameraPreview(controller),
            ),
          );
        }
        if (snapshot.hasError) {
          return Text('Camera error: ${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }
}

class _PermissionMessage extends StatelessWidget {
  const _PermissionMessage({required this.onOpenSettings});

  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 48, color: Colors.white70),
          const SizedBox(height: 16),
          const Text(
            'Camera permission is required to scan ingredients.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => onOpenSettings(),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }
}
