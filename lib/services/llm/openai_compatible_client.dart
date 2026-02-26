import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';
import '../../models/chat_message.dart';
import '../../models/llm_response.dart';
import 'llm_client.dart';

class OpenAICompatibleClient implements LLMClient {
  final String baseUrl;
  final String apiKey;
  final String model;
  final Map<String, String>? extraHeaders;

  OpenAICompatibleClient({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.extraHeaders,
  });

  @override
  Future<LLMResponse> sendMessage({
    required String systemPrompt,
    required String userMessage,
    List<ChatMessage> history = const [],
    double temperature = 0.3,
    int maxTokens = 1024,
  }) async {
    try {
      // Build messages array
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        ...history.map((m) => m.toJson()),
        {'role': 'user', 'content': userMessage},
      ];

      // Build request body
      final body = jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      });

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        ...?extraHeaders,
      };

      // Make request with timeout
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: headers,
            body: body,
          )
          .timeout(Duration(seconds: AppConstants.llmTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = _extractContent(data);
        if (content != null) {
          return LLMResponse.success(content);
        } else {
          return LLMResponse.failure('Could not parse response');
        }
      } else if (response.statusCode == 401) {
        return LLMResponse.failure('Invalid API key');
      } else if (response.statusCode == 429) {
        return LLMResponse.failure('Rate limited. Please wait and try again.');
      } else {
        final errorBody = _tryParseError(response.body);
        return LLMResponse.failure(
            'API error (${response.statusCode}): $errorBody');
      }
    } on TimeoutException {
      return LLMResponse.failure(
          'Request timed out after ${AppConstants.llmTimeoutSeconds} seconds');
    } on http.ClientException catch (e) {
      return LLMResponse.failure('Network error: ${e.message}');
    } on FormatException {
      return LLMResponse.failure('Invalid response format');
    } catch (e) {
      return LLMResponse.failure('Unexpected error: $e');
    }
  }

  String? _extractContent(Map<String, dynamic> data) {
    try {
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map?;
        if (message != null) {
          return message['content'] as String?;
        }
      }
    } catch (e) {
      // Failed to parse
    }
    return null;
  }

  String _tryParseError(String body) {
    try {
      final data = jsonDecode(body);
      if (data['error'] != null) {
        final error = data['error'];
        if (error is Map) {
          return error['message'] ?? error.toString();
        }
        return error.toString();
      }
    } catch (e) {
      // Not JSON
    }
    return body.length > 200 ? '${body.substring(0, 200)}...' : body;
  }
}
