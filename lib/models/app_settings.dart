import '../config/constants.dart';

class AppSettings {
  final String selectedProviderId;
  final String selectedModelId;
  final String apiKey;
  final bool speakResponses;
  final double speechRate;
  final bool vibrateOnCommand;
  final double temperature;

  const AppSettings({
    this.selectedProviderId = 'openai',
    this.selectedModelId = 'gpt-4o',
    this.apiKey = '',
    this.speakResponses = true,
    this.speechRate = AppConstants.defaultSpeechRate,
    this.vibrateOnCommand = true,
    this.temperature = AppConstants.defaultTemperature,
  });

  AppSettings copyWith({
    String? selectedProviderId,
    String? selectedModelId,
    String? apiKey,
    bool? speakResponses,
    double? speechRate,
    bool? vibrateOnCommand,
    double? temperature,
  }) {
    return AppSettings(
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      apiKey: apiKey ?? this.apiKey,
      speakResponses: speakResponses ?? this.speakResponses,
      speechRate: speechRate ?? this.speechRate,
      vibrateOnCommand: vibrateOnCommand ?? this.vibrateOnCommand,
      temperature: temperature ?? this.temperature,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedProviderId': selectedProviderId,
      'selectedModelId': selectedModelId,
      'speakResponses': speakResponses,
      'speechRate': speechRate,
      'vibrateOnCommand': vibrateOnCommand,
      'temperature': temperature,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      selectedProviderId: json['selectedProviderId'] as String? ?? 'openai',
      selectedModelId: json['selectedModelId'] as String? ?? 'gpt-4o',
      speakResponses: json['speakResponses'] as bool? ?? true,
      speechRate:
          (json['speechRate'] as num?)?.toDouble() ?? AppConstants.defaultSpeechRate,
      vibrateOnCommand: json['vibrateOnCommand'] as bool? ?? true,
      temperature:
          (json['temperature'] as num?)?.toDouble() ?? AppConstants.defaultTemperature,
    );
  }
}
