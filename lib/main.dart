import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/accessibility_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/voice_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize providers
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  final voiceProvider = VoiceProvider();
  await voiceProvider.init();

  final accessibilityProvider = AccessibilityProvider();
  await accessibilityProvider.init();

  // Apply settings to voice provider
  voiceProvider.setSettings(
    vibrateOnCommand: settingsProvider.vibrateOnCommand,
    speakResponses: settingsProvider.speakResponses,
    speechRate: settingsProvider.speechRate,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: voiceProvider),
        ChangeNotifierProvider.value(value: accessibilityProvider),
      ],
      child: const VoiceOSApp(),
    ),
  );
}
