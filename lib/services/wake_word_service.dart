import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class WakeWordService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _wakeWord = 'hey voice';
  List<String> _wakeWordVariants = [];

  Function()? onWakeWordDetected;
  Function(String)? onPartialResult;

  bool get isListening => _isListening;
  String get wakeWord => _wakeWord;

  void setWakeWord(String word) {
    _wakeWord = word.toLowerCase().trim();
    _generateVariants();
  }

  void _generateVariants() {
    final base = _wakeWord.toLowerCase();
    _wakeWordVariants = [
      base,
      base.replaceAll(' ', ''),
      'hey ${base.split(' ').last}',
      base.split(' ').last,
      // Common misheard variants
      base.replaceAll('voice', 'boys'),
      base.replaceAll('voice', 'choice'),
      'a $base',
      'hey boys',
    ];
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('Wake word error: ${error.errorMsg}');
          // Auto-restart on error if still supposed to be listening
          if (_isListening) {
            Future.delayed(const Duration(seconds: 1), () {
              _startListeningInternal();
            });
          }
        },
        onStatus: (status) {
          debugPrint('Wake word status: $status');
          if (status == 'done' && _isListening) {
            // Restart listening when done
            Future.delayed(const Duration(milliseconds: 500), () {
              _startListeningInternal();
            });
          }
        },
      );
      _generateVariants();
      return _isInitialized;
    } catch (e) {
      debugPrint('Wake word init error: $e');
      return false;
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    _isListening = true;
    await _startListeningInternal();
  }

  Future<void> _startListeningInternal() async {
    if (!_isListening) return;

    try {
      await _speech.listen(
        onResult: _handleResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      debugPrint('Wake word listen error: $e');
      // Retry after delay
      if (_isListening) {
        Future.delayed(const Duration(seconds: 2), () {
          _startListeningInternal();
        });
      }
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.toLowerCase();
    onPartialResult?.call(text);

    // Check for wake word
    for (final variant in _wakeWordVariants) {
      if (text.contains(variant)) {
        debugPrint('Wake word detected: "$variant" in "$text"');
        onWakeWordDetected?.call();
        // Brief pause before continuing to listen
        _speech.stop();
        Future.delayed(const Duration(seconds: 2), () {
          if (_isListening) {
            _startListeningInternal();
          }
        });
        return;
      }
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  void dispose() {
    _isListening = false;
    _speech.stop();
  }
}
