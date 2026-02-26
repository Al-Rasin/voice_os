import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../config/constants.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  double _speechRate = AppConstants.defaultSpeechRate;

  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((message) {
        debugPrint('TTS error: $message');
        _isSpeaking = false;
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    // Stop any current speech
    if (_isSpeaking) {
      await stop();
    }

    try {
      _isSpeaking = true;
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(
      AppConstants.minSpeechRate,
      AppConstants.maxSpeechRate,
    );
    if (_isInitialized) {
      await _tts.setSpeechRate(_speechRate);
    }
  }

  double get speechRate => _speechRate;

  void dispose() {
    _tts.stop();
  }
}
