import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/llm_provider.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();
  bool _isLoading = true;
  bool _isInitialized = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Convenience getters
  String get selectedProviderId => _settings.selectedProviderId;
  String get selectedModelId => _settings.selectedModelId;
  String get apiKey => _settings.apiKey;
  bool get speakResponses => _settings.speakResponses;
  double get speechRate => _settings.speechRate;
  bool get vibrateOnCommand => _settings.vibrateOnCommand;
  double get temperature => _settings.temperature;

  LLMProvider? get currentProvider => LLMProvider.getById(_settings.selectedProviderId);

  LLMModel? get currentModel {
    final provider = currentProvider;
    if (provider == null) return null;
    try {
      return provider.models.firstWhere((m) => m.id == _settings.selectedModelId);
    } catch (e) {
      return provider.models.isNotEmpty ? provider.models.first : null;
    }
  }

  bool get hasApiKey => _settings.apiKey.isNotEmpty;

  Future<void> init() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _settings = await SettingsService.loadSettings();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _settings = const AppSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await SettingsService.saveSettings(newSettings);
  }

  Future<void> setProvider(String providerId) async {
    final provider = LLMProvider.getById(providerId);
    if (provider == null) return;

    // When changing provider, reset model to first available
    final firstModel = provider.models.isNotEmpty ? provider.models.first.id : '';

    await updateSettings(_settings.copyWith(
      selectedProviderId: providerId,
      selectedModelId: firstModel,
    ));
  }

  Future<void> setModel(String modelId) async {
    await updateSettings(_settings.copyWith(selectedModelId: modelId));
  }

  Future<void> setApiKey(String apiKey) async {
    await updateSettings(_settings.copyWith(apiKey: apiKey));
  }

  Future<void> setSpeakResponses(bool value) async {
    await updateSettings(_settings.copyWith(speakResponses: value));
  }

  Future<void> setSpeechRate(double value) async {
    await updateSettings(_settings.copyWith(speechRate: value));
  }

  Future<void> setVibrateOnCommand(bool value) async {
    await updateSettings(_settings.copyWith(vibrateOnCommand: value));
  }

  Future<void> setTemperature(double value) async {
    await updateSettings(_settings.copyWith(temperature: value));
  }

  Future<void> resetSettings() async {
    await SettingsService.clearAllSettings();
    _settings = const AppSettings();
    notifyListeners();
  }
}
