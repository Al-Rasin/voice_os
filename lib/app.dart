import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/settings_service.dart';

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
      home: const _InitialScreen(),
    );
  }
}

class _InitialScreen extends StatefulWidget {
  const _InitialScreen();

  @override
  State<_InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<_InitialScreen> {
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final complete = await SettingsService.isOnboardingComplete();
    setState(() {
      _onboardingComplete = complete;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      // Loading
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_onboardingComplete!) {
      return const HomeScreen();
    } else {
      return const OnboardingScreen();
    }
  }
}
