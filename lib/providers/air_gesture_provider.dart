import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../services/air_gesture_service.dart';

class AirGestureProvider extends ChangeNotifier {
  final AirGestureService _service = AirGestureService();
  bool _isEnabled = false;
  bool _isInitialized = false;
  AirGesture? _lastGesture;
  DateTime? _lastGestureTime;

  Function(AirGesture)? onGestureDetected;

  bool get isEnabled => _isEnabled;
  bool get isInitialized => _isInitialized;
  AirGesture? get lastGesture => _lastGesture;
  CameraController? get cameraController => _service.cameraController;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    final success = await _service.initialize();
    if (success) {
      _isInitialized = true;
      _service.onGestureDetected = _handleGesture;
      notifyListeners();
    }
    return success;
  }

  void _handleGesture(AirGesture gesture) {
    // Debounce - ignore gestures within 500ms of each other
    final now = DateTime.now();
    if (_lastGestureTime != null &&
        now.difference(_lastGestureTime!).inMilliseconds < 500) {
      return;
    }

    _lastGesture = gesture;
    _lastGestureTime = now;
    notifyListeners();

    onGestureDetected?.call(gesture);

    // Clear last gesture after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (_lastGesture == gesture) {
        _lastGesture = null;
        notifyListeners();
      }
    });
  }

  Future<void> enable() async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    await _service.start();
    _isEnabled = true;
    notifyListeners();
  }

  Future<void> disable() async {
    await _service.stop();
    _isEnabled = false;
    _lastGesture = null;
    notifyListeners();
  }

  Future<void> toggle() async {
    if (_isEnabled) {
      await disable();
    } else {
      await enable();
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
