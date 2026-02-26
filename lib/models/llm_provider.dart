class LLMModel {
  final String id;
  final String displayName;

  const LLMModel({
    required this.id,
    required this.displayName,
  });
}

class LLMProvider {
  final String id;
  final String name;
  final String iconName;
  final String baseUrl;
  final List<LLMModel> models;

  const LLMProvider({
    required this.id,
    required this.name,
    required this.iconName,
    required this.baseUrl,
    required this.models,
  });

  static const List<LLMProvider> providers = [
    LLMProvider(
      id: 'openai',
      name: 'OpenAI',
      iconName: 'psychology',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
      models: [
        LLMModel(id: 'gpt-4o', displayName: 'GPT-4o'),
        LLMModel(id: 'gpt-4o-mini', displayName: 'GPT-4o Mini'),
      ],
    ),
    LLMProvider(
      id: 'anthropic',
      name: 'Anthropic Claude',
      iconName: 'auto_awesome',
      baseUrl: 'https://api.anthropic.com/v1/messages',
      models: [
        LLMModel(id: 'claude-sonnet-4-20250514', displayName: 'Claude Sonnet 4'),
        LLMModel(
            id: 'claude-haiku-4-5-20251001', displayName: 'Claude Haiku 4.5'),
      ],
    ),
    LLMProvider(
      id: 'gemini',
      name: 'Google Gemini',
      iconName: 'star',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
      models: [
        LLMModel(id: 'gemini-2.0-flash', displayName: 'Gemini 2.0 Flash'),
        LLMModel(id: 'gemini-2.5-pro', displayName: 'Gemini 2.5 Pro'),
      ],
    ),
    LLMProvider(
      id: 'groq',
      name: 'Groq',
      iconName: 'bolt',
      baseUrl: 'https://api.groq.com/openai/v1/chat/completions',
      models: [
        LLMModel(
            id: 'llama-3.3-70b-versatile', displayName: 'Llama 3.3 70B'),
        LLMModel(id: 'mixtral-8x7b-32768', displayName: 'Mixtral 8x7B'),
      ],
    ),
    LLMProvider(
      id: 'deepseek',
      name: 'DeepSeek',
      iconName: 'search',
      baseUrl: 'https://api.deepseek.com/v1/chat/completions',
      models: [
        LLMModel(id: 'deepseek-chat', displayName: 'DeepSeek Chat'),
      ],
    ),
    LLMProvider(
      id: 'openrouter',
      name: 'OpenRouter',
      iconName: 'public',
      baseUrl: 'https://openrouter.ai/api/v1/chat/completions',
      models: [
        LLMModel(
            id: 'anthropic/claude-sonnet-4', displayName: 'Claude Sonnet 4'),
        LLMModel(
            id: 'google/gemini-2.0-flash-001', displayName: 'Gemini 2.0 Flash'),
        LLMModel(
            id: 'meta-llama/llama-3.3-70b-instruct',
            displayName: 'Llama 3.3 70B'),
      ],
    ),
  ];

  static LLMProvider? getById(String id) {
    try {
      return providers.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  static LLMProvider get defaultProvider => providers.first;
}
