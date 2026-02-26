import '../../models/chat_message.dart';
import '../../models/llm_response.dart';

abstract class LLMClient {
  Future<LLMResponse> sendMessage({
    required String systemPrompt,
    required String userMessage,
    List<ChatMessage> history = const [],
    double temperature = 0.3,
    int maxTokens = 1024,
  });
}
