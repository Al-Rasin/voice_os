import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const _secureStorage = FlutterSecureStorage();

  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load API key from secure storage
    final apiKey = await _secureStorage.read(key: AppConstants.keyApiKey) ?? '';

    // Load other settings from shared preferences
    final providerId = prefs.getString(AppConstants.keySelectedProviderId) ?? 'openai';
    final modelId = prefs.getString(AppConstants.keySelectedModelId) ?? 'gpt-4o';
    final speakResponses = prefs.getBool(AppConstants.keySpeakResponses) ?? true;
    final speechRate = prefs.getDouble(AppConstants.keySpeechRate) ?? AppConstants.defaultSpeechRate;
    final vibrateOnCommand = prefs.getBool(AppConstants.keyVibrateOnCommand) ?? true;
    final temperature = prefs.getDouble(AppConstants.keyTemperature) ?? AppConstants.defaultTemperature;

    return AppSettings(
      selectedProviderId: providerId,
      selectedModelId: modelId,
      apiKey: apiKey,
      speakResponses: speakResponses,
      speechRate: speechRate,
      vibrateOnCommand: vibrateOnCommand,
      temperature: temperature,
    );
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    // Save API key to secure storage
    await _secureStorage.write(key: AppConstants.keyApiKey, value: settings.apiKey);

    // Save other settings to shared preferences
    await prefs.setString(AppConstants.keySelectedProviderId, settings.selectedProviderId);
    await prefs.setString(AppConstants.keySelectedModelId, settings.selectedModelId);
    await prefs.setBool(AppConstants.keySpeakResponses, settings.speakResponses);
    await prefs.setDouble(AppConstants.keySpeechRate, settings.speechRate);
    await prefs.setBool(AppConstants.keyVibrateOnCommand, settings.vibrateOnCommand);
    await prefs.setDouble(AppConstants.keyTemperature, settings.temperature);
  }

  static Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.deleteAll();
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;
  }

  static Future<void> setOnboardingComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingComplete, complete);
  }
}
