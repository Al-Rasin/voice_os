import 'package:flutter/foundation.dart';
import '../services/wake_word_service.dart';

class WakeWordProvider extends ChangeNotifier {
  final WakeWordService _service = WakeWordService();
  bool _isEnabled = false;
  bool _isInitialized = false;
  String _lastHeard = '';
  String _wakeWord = 'hey voice';

  Function()? onWakeWordDetected;

  bool get isEnabled => _isEnabled;
  bool get isInitialized => _isInitialized;
  String get lastHeard => _lastHeard;
  String get wakeWord => _wakeWord;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    final success = await _service.initialize();
    if (success) {
      _isInitialized = true;
      _service.onWakeWordDetected = _handleWakeWord;
      _service.onPartialResult = _handlePartialResult;
      notifyListeners();
    }
    return success;
  }

  void setWakeWord(String word) {
    _wakeWord = word.toLowerCase().trim();
    _service.setWakeWord(_wakeWord);
    notifyListeners();
  }

  void _handleWakeWord() {
    debugPrint('Wake word triggered!');
    onWakeWordDetected?.call();
  }

  void _handlePartialResult(String text) {
    _lastHeard = text;
    notifyListeners();
  }

  Future<void> enable() async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    await _service.startListening();
    _isEnabled = true;
    notifyListeners();
  }

  Future<void> disable() async {
    await _service.stopListening();
    _isEnabled = false;
    _lastHeard = '';
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
