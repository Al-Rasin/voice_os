class AppConstants {
  // App info
  static const String appName = 'VoiceOS';
  static const String appVersion = '1.0.0';

  // Platform channel
  static const String platformChannelName = 'com.voiceos.app/native';

  // Voice settings defaults
  static const double defaultSpeechRate = 1.0;
  static const double minSpeechRate = 0.5;
  static const double maxSpeechRate = 2.0;

  // LLM settings defaults
  static const double defaultTemperature = 0.3;
  static const double minTemperature = 0.0;
  static const double maxTemperature = 1.0;
  static const int defaultMaxTokens = 1024;

  // Timeouts
  static const int llmTimeoutSeconds = 30;
  static const int speechListenTimeoutSeconds = 30;
  static const int speechPauseSeconds = 3;

  // Conversation history
  static const int maxConversationHistory = 6;
  static const int conversationHistoryTimeoutMinutes = 5;

  // Command history
  static const int maxCommandHistory = 50;

  // Screen context
  static const int maxScreenNodes = 40;
  static const int maxTextLength = 60;
  static const int maxNodeDepth = 10;

  // Storage keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keySelectedProviderId = 'selected_provider_id';
  static const String keySelectedModelId = 'selected_model_id';
  static const String keySpeakResponses = 'speak_responses';
  static const String keySpeechRate = 'speech_rate';
  static const String keyVibrateOnCommand = 'vibrate_on_command';
  static const String keyTemperature = 'temperature';
  static const String keyApiKey = 'api_key';
  static const String keyCommandHistory = 'command_history';
  static const String keyFloatingWidgetEnabled = 'floating_widget_enabled';
}
