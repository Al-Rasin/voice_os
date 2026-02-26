import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../config/constants.dart';

class VoiceInputService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        debugLogging: kDebugMode,
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Speech initialization error: $e');
      return false;
    }
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('Speech error: ${error.errorMsg}');
    _isListening = false;
  }

  void _handleStatus(String status) {
    debugPrint('Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onPartialResult,
    required Function() onListeningStarted,
    required Function() onListeningStopped,
    required Function(String) onError,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError('Speech recognition not available on this device');
        return;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      _isListening = true;
      onListeningStarted();

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            _isListening = false;
            onListeningStopped();
          } else {
            onPartialResult(result.recognizedWords);
          }
        },
        listenFor: Duration(seconds: AppConstants.speechListenTimeoutSeconds),
        pauseFor: Duration(seconds: AppConstants.speechPauseSeconds),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      _isListening = false;
      onError('Failed to start listening: $e');
      onListeningStopped();
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  Future<void> cancel() async {
    await _speech.cancel();
    _isListening = false;
  }

  void dispose() {
    _speech.stop();
  }
}
