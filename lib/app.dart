import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';

class VoiceOSApp extends StatelessWidget {
  const VoiceOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoiceOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
