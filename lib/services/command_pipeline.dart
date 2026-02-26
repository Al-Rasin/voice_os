import 'package:intl/intl.dart';
import '../models/app_settings.dart';
import '../models/chat_message.dart';
import '../models/pipeline_result.dart';
import '../platform/native_bridge.dart';
import 'app_resolver_service.dart';
import 'llm/llm_client_factory.dart';
import 'llm/response_parser.dart';
import 'llm/system_prompt.dart';
import 'quick_command_handler.dart';
import 'screen_context_formatter.dart';

class CommandPipeline {
  final AppResolverService appResolver;
  final QuickCommandHandler quickHandler = QuickCommandHandler();

  List<ChatMessage> conversationHistory = [];
  Map<String, dynamic>? lastScreenContext;
  DateTime? _lastInteraction;

  CommandPipeline({required this.appResolver});

  Future<PipelineResult> processCommand(
    String spokenText,
    AppSettings settings,
  ) async {
    // Check conversation timeout (5 minutes)
    if (_lastInteraction != null &&
        DateTime.now().difference(_lastInteraction!).inMinutes > 5) {
      conversationHistory.clear();
    }
    _lastInteraction = DateTime.now();

    // Check for quick commands first (no LLM needed)
    final quickResult = quickHandler.tryHandle(spokenText);
    if (quickResult != null) {
      return quickResult;
    }

    // Need LLM - check if API key is configured
    if (settings.apiKey.isEmpty) {
      return PipelineResult.error('Please configure your API key in settings');
    }

    try {
      // Step 1: Get current screen context
      lastScreenContext = await NativeBridge.getScreenContext();

      // Step 2: Get installed apps
      await appResolver.ensureInitialized();

      // Step 3: Format everything into prompt
      final screenText = ScreenContextFormatter.format(lastScreenContext!);
      final appNames = appResolver.appNamesForPrompt;
      final now = DateTime.now();
      final dateTimeStr = DateFormat('EEEE, MMMM d, y, h:mm a').format(now);

      final userPrompt = SystemPrompt.buildUserPrompt(
        dateTime: dateTimeStr,
        screenContext: screenText,
        installedApps: appNames,
        voiceCommand: spokenText,
      );

      // Step 4: Send to LLM
      final client = LLMClientFactory.createClient(settings);
      final response = await client.sendMessage(
        systemPrompt: SystemPrompt.prompt,
        userMessage: userPrompt,
        history: conversationHistory,
        temperature: settings.temperature,
      );

      if (!response.success) {
        return PipelineResult.error('AI error: ${response.error}');
      }

      // Step 5: Parse LLM response
      final parsed = ResponseParser.parse(response.rawText);

      // Step 6: Update conversation history (keep last 6 messages)
      conversationHistory.add(ChatMessage.user(spokenText));
      conversationHistory.add(ChatMessage.assistant(response.rawText));
      if (conversationHistory.length > 6) {
        conversationHistory =
            conversationHistory.sublist(conversationHistory.length - 6);
      }

      // Step 7: Return parsed result
      return PipelineResult.success(
        thought: parsed.thought,
        actions: parsed.actions,
        speak: parsed.speak,
      );
    } catch (e) {
      return PipelineResult.error('Error: $e');
    }
  }

  void clearHistory() {
    conversationHistory.clear();
    _lastInteraction = null;
  }
}
