import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum AirGesture {
  none,
  swipeLeft,
  swipeRight,
  swipeUp,
  swipeDown,
  tap,
}

class AirGestureService {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isProcessing = false;
  bool _isRunning = false;

  // Gesture tracking
  Point<double>? _lastWristPosition;
  DateTime? _lastPositionTime;
  final List<Point<double>> _positionHistory = [];
  static const int _historySize = 5;
  static const double _swipeThreshold = 100.0; // pixels
  static const int _swipeTimeThreshold = 500; // milliseconds

  Function(AirGesture)? onGestureDetected;

  bool get isRunning => _isRunning;

  Future<bool> initialize() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.base,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('Air gesture init error: $e');
      return false;
    }
  }

  Future<void> start() async {
    if (_isRunning || _cameraController == null) return;

    _isRunning = true;
    _positionHistory.clear();
    _lastWristPosition = null;

    await _cameraController!.startImageStream(_processImage);
  }

  Future<void> stop() async {
    _isRunning = false;
    if (_cameraController?.value.isStreamingImages ?? false) {
      await _cameraController?.stopImageStream();
    }
  }

  void _processImage(CameraImage image) async {
    if (_isProcessing || !_isRunning) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final poses = await _poseDetector?.processImage(inputImage);
      if (poses != null && poses.isNotEmpty) {
        _analyzePose(poses.first);
      }
    } catch (e) {
      debugPrint('Pose detection error: $e');
    }

    _isProcessing = false;
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  void _analyzePose(Pose pose) {
    // Track right wrist (primary hand for most users)
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

    // Use whichever wrist is more visible/confident
    PoseLandmark? wrist;
    if (rightWrist != null && leftWrist != null) {
      wrist = rightWrist.likelihood > leftWrist.likelihood ? rightWrist : leftWrist;
    } else {
      wrist = rightWrist ?? leftWrist;
    }

    if (wrist == null || wrist.likelihood < 0.5) return;

    final currentPosition = Point(wrist.x, wrist.y);
    final now = DateTime.now();

    // Add to history
    _positionHistory.add(currentPosition);
    if (_positionHistory.length > _historySize) {
      _positionHistory.removeAt(0);
    }

    // Detect gesture
    if (_lastWristPosition != null && _lastPositionTime != null) {
      final timeDiff = now.difference(_lastPositionTime!).inMilliseconds;

      if (timeDiff < _swipeTimeThreshold && _positionHistory.length >= 3) {
        final gesture = _detectGesture();
        if (gesture != AirGesture.none) {
          onGestureDetected?.call(gesture);
          _positionHistory.clear(); // Reset after detecting
        }
      }
    }

    _lastWristPosition = currentPosition;
    _lastPositionTime = now;
  }

  AirGesture _detectGesture() {
    if (_positionHistory.length < 3) return AirGesture.none;

    final start = _positionHistory.first;
    final end = _positionHistory.last;

    final deltaX = end.x - start.x;
    final deltaY = end.y - start.y;

    final absX = deltaX.abs();
    final absY = deltaY.abs();

    // Check if movement is significant enough
    if (absX < _swipeThreshold && absY < _swipeThreshold) {
      return AirGesture.none;
    }

    // Determine primary direction
    if (absX > absY) {
      // Horizontal swipe (camera is mirrored, so invert)
      return deltaX > 0 ? AirGesture.swipeLeft : AirGesture.swipeRight;
    } else {
      // Vertical swipe
      return deltaY > 0 ? AirGesture.swipeDown : AirGesture.swipeUp;
    }
  }

  CameraController? get cameraController => _cameraController;

  void dispose() {
    stop();
    _cameraController?.dispose();
    _poseDetector?.close();
  }
}
