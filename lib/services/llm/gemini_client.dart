import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';
import '../../models/chat_message.dart';
import '../../models/llm_response.dart';
import 'llm_client.dart';

class GeminiClient implements LLMClient {
  final String apiKey;
  final String model;
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiClient({
    required this.apiKey,
    required this.model,
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
      // Build contents array (Gemini uses "model" instead of "assistant")
      final contents = <Map<String, dynamic>>[
        ...history.map((m) => {
              'role': m.role == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': m.content}
              ],
            }),
        {
          'role': 'user',
          'parts': [
            {'text': userMessage}
          ],
        },
      ];

      // Build request body
      final body = jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
        'contents': contents,
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        },
      });

      // Build URL with API key
      final url = '$baseUrl/$model:generateContent?key=$apiKey';

      // Build headers
      final headers = {
        'Content-Type': 'application/json',
      };

      // Make request with timeout
      final response = await http
          .post(
            Uri.parse(url),
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
      } else if (response.statusCode == 401 || response.statusCode == 403) {
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
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map?;
        if (content != null) {
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] as String?;
          }
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
