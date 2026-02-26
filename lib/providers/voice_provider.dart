import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/tts_service.dart';
import '../services/voice_input_service.dart';

enum VoiceState {
  idle,
  listening,
  processing,
  success,
  error,
}

class VoiceProvider extends ChangeNotifier {
  final VoiceInputService _voiceInput = VoiceInputService();
  final TTSService _tts = TTSService();

  VoiceState _state = VoiceState.idle;
  String _partialText = '';
  String _finalText = '';
  String _responseText = '';
  String _errorMessage = '';
  bool _vibrateOnCommand = true;
  bool _speakResponses = true;
  bool _continuousListeningEnabled = false;
  bool _isContinuousListening = false;
  bool _isDisposed = false;

  VoiceState get state => _state;
  String get partialText => _partialText;
  String get finalText => _finalText;
  String get responseText => _responseText;
  String get errorMessage => _errorMessage;
  bool get isListening => _state == VoiceState.listening;
  bool get isProcessing => _state == VoiceState.processing;
  bool get continuousListeningEnabled => _continuousListeningEnabled;
  bool get isContinuousListening => _isContinuousListening;

  VoiceInputService get voiceInputService => _voiceInput;
  TTSService get ttsService => _tts;

  Future<void> init() async {
    await _voiceInput.initialize();
    await _tts.initialize();
  }

  void setSettings({
    required bool vibrateOnCommand,
    required bool speakResponses,
    required double speechRate,
  }) {
    _vibrateOnCommand = vibrateOnCommand;
    _speakResponses = speakResponses;
    _tts.setSpeechRate(speechRate);
  }

  Future<void> startListening() async {
    // Reset state
    _partialText = '';
    _finalText = '';
    _responseText = '';
    _errorMessage = '';

    // Vibrate on start
    if (_vibrateOnCommand) {
      HapticFeedback.mediumImpact();
    }

    _state = VoiceState.listening;
    notifyListeners();

    await _voiceInput.startListening(
      onResult: _onResult,
      onPartialResult: _onPartialResult,
      onListeningStarted: _onListeningStarted,
      onListeningStopped: _onListeningStopped,
      onError: _onError,
    );
  }

  Future<void> stopListening() async {
    await _voiceInput.stopListening();
    _state = VoiceState.idle;
    notifyListeners();
  }

  void _onResult(String text) {
    _finalText = text;

    if (_vibrateOnCommand) {
      HapticFeedback.lightImpact();
    }

    // Set to processing state - the command pipeline will take over
    _state = VoiceState.processing;
    notifyListeners();
  }

  void _onPartialResult(String text) {
    _partialText = text;
    notifyListeners();
  }

  void _onListeningStarted() {
    _state = VoiceState.listening;
    notifyListeners();
  }

  void _onListeningStopped() {
    if (_state == VoiceState.listening) {
      // Listening stopped without a result
      if (_partialText.isEmpty && _finalText.isEmpty) {
        _errorMessage = "I didn't catch that";
        _state = VoiceState.error;
      }
      notifyListeners();
    }
  }

  void _onError(String error) {
    if (_isDisposed) return;

    _errorMessage = error;
    _state = VoiceState.error;
    notifyListeners();

    // Auto-reset after showing error
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isDisposed && _state == VoiceState.error) {
        reset();
      }
    });
  }

  void setProcessing() {
    _state = VoiceState.processing;
    notifyListeners();
  }

  void setResponse(String response) {
    if (_isDisposed) return;

    _responseText = response;
    _state = VoiceState.success;

    if (_vibrateOnCommand) {
      HapticFeedback.lightImpact();
    }

    notifyListeners();

    // Speak response
    if (_speakResponses && response.isNotEmpty) {
      _tts.speak(response);
    }

    // Auto-reset after showing response
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isDisposed && _state == VoiceState.success) {
        reset();
      }
    });
  }

  void setError(String error) {
    if (_isDisposed) return;

    _errorMessage = error;
    _state = VoiceState.error;
    notifyListeners();

    // Auto-reset after showing error
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isDisposed && _state == VoiceState.error) {
        reset();
      }
    });
  }

  void reset() {
    if (_isDisposed) return;

    _state = VoiceState.idle;
    _partialText = '';
    _finalText = '';
    _responseText = '';
    _errorMessage = '';
    notifyListeners();

    // If continuous listening is enabled, restart listening after reset
    if (_isContinuousListening) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed && _isContinuousListening && _state == VoiceState.idle) {
          startListening();
        }
      });
    }
  }

  // Continuous Listening Mode
  void setContinuousListeningEnabled(bool enabled) {
    _continuousListeningEnabled = enabled;
    notifyListeners();
  }

  Future<void> startContinuousListening() async {
    _isContinuousListening = true;
    notifyListeners();
    await startListening();
  }

  Future<void> stopContinuousListening() async {
    _isContinuousListening = false;
    await stopListening();
    reset();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isContinuousListening = false;
    _voiceInput.dispose();
    _tts.dispose();
    super.dispose();
  }
}
