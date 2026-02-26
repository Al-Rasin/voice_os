import '../../models/app_settings.dart';
import '../../models/llm_provider.dart';
import 'anthropic_client.dart';
import 'gemini_client.dart';
import 'llm_client.dart';
import 'openai_compatible_client.dart';

class LLMClientFactory {
  static LLMClient createClient(AppSettings settings) {
    final provider = LLMProvider.getById(settings.selectedProviderId);
    if (provider == null) {
      throw Exception('Unknown provider: ${settings.selectedProviderId}');
    }

    switch (settings.selectedProviderId) {
      case 'openai':
        return OpenAICompatibleClient(
          baseUrl: provider.baseUrl,
          apiKey: settings.apiKey,
          model: settings.selectedModelId,
        );

      case 'anthropic':
        return AnthropicClient(
          apiKey: settings.apiKey,
          model: settings.selectedModelId,
        );

      case 'gemini':
        return GeminiClient(
          apiKey: settings.apiKey,
          model: settings.selectedModelId,
        );

      case 'groq':
        return OpenAICompatibleClient(
          baseUrl: provider.baseUrl,
          apiKey: settings.apiKey,
          model: settings.selectedModelId,
        );

      case 'deepseek':
        return OpenAICompatibleClient(
          baseUrl: provider.baseUrl,
          apiKey: settings.apiKey,
          model: settings.selectedModelId,
        );

      case 'openrouter':
        return OpenAICompatibleClient(
          baseUrl: provider.baseUrl,
          apiKey: settings.apiKey,
          model: settings.selectedModelId,
          extraHeaders: {
            'HTTP-Referer': 'com.voiceos.app',
            'X-Title': 'VoiceOS',
          },
        );

      default:
        throw Exception('Unknown provider: ${settings.selectedProviderId}');
    }
  }

  static Future<bool> testConnection(AppSettings settings) async {
    try {
      final client = createClient(settings);
      final response = await client.sendMessage(
        systemPrompt: 'You are a helpful assistant.',
        userMessage: 'Respond with only: Connection successful',
        temperature: 0.0,
        maxTokens: 50,
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }
}
