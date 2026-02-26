import 'dart:convert';

class ParsedAction {
  final String type;
  final Map<String, dynamic> params;

  ParsedAction({
    required this.type,
    required this.params,
  });

  factory ParsedAction.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'none';
    final params = Map<String, dynamic>.from(json)..remove('type');
    return ParsedAction(type: type, params: params);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      ...params,
    };
  }
}

class ParsedLLMResponse {
  final String thought;
  final List<ParsedAction> actions;
  final String speak;

  ParsedLLMResponse({
    required this.thought,
    required this.actions,
    required this.speak,
  });

  factory ParsedLLMResponse.fallback(String message) {
    return ParsedLLMResponse(
      thought: 'Could not parse response',
      actions: [],
      speak: message,
    );
  }
}

class ResponseParser {
  static ParsedLLMResponse parse(String rawResponse) {
    // Try multiple extraction methods
    Map<String, dynamic>? json;

    // Method 1: Direct JSON parse
    json = _tryDirectParse(rawResponse);

    // Method 2: Extract from markdown code blocks
    if (json == null) {
      json = _tryExtractFromCodeBlock(rawResponse);
    }

    // Method 3: Find first { and last }
    if (json == null) {
      json = _tryExtractBraces(rawResponse);
    }

    if (json == null) {
      return ParsedLLMResponse.fallback(
          'Sorry, something went wrong. Please try again.');
    }

    return _parseJson(json);
  }

  static Map<String, dynamic>? _tryDirectParse(String text) {
    try {
      final trimmed = text.trim();
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        return jsonDecode(trimmed) as Map<String, dynamic>;
      }
    } catch (e) {
      // Not valid JSON
    }
    return null;
  }

  static Map<String, dynamic>? _tryExtractFromCodeBlock(String text) {
    // Look for ```json ... ``` or ``` ... ```
    final patterns = [
      RegExp(r'```json\s*([\s\S]*?)\s*```'),
      RegExp(r'```\s*([\s\S]*?)\s*```'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final content = match.group(1);
        if (content != null) {
          try {
            return jsonDecode(content.trim()) as Map<String, dynamic>;
          } catch (e) {
            // Not valid JSON
          }
        }
      }
    }
    return null;
  }

  static Map<String, dynamic>? _tryExtractBraces(String text) {
    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');

    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      final jsonStr = text.substring(firstBrace, lastBrace + 1);
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        // Not valid JSON
      }
    }
    return null;
  }

  static ParsedLLMResponse _parseJson(Map<String, dynamic> json) {
    final thought = json['thought'] as String? ?? '';
    final speak =
        json['speak'] as String? ?? 'Done';

    // Parse actions
    List<ParsedAction> actions = [];
    final actionsJson = json['actions'];

    if (actionsJson is List) {
      for (final actionJson in actionsJson) {
        if (actionJson is Map<String, dynamic>) {
          if (actionJson.containsKey('type')) {
            actions.add(ParsedAction.fromJson(actionJson));
          }
        }
      }
    } else if (actionsJson is Map<String, dynamic>) {
      // Single action object instead of array
      if (actionsJson.containsKey('type')) {
        actions.add(ParsedAction.fromJson(actionsJson));
      }
    }

    return ParsedLLMResponse(
      thought: thought,
      actions: actions,
      speak: speak,
    );
  }

  /// Resolve element index to coordinates using screen context
  static ParsedAction resolveElementBounds(
      ParsedAction action, Map<String, dynamic> screenContext) {
    if (!action.params.containsKey('element')) {
      return action;
    }

    final elementIndex = action.params['element'] as int?;
    if (elementIndex == null) return action;

    final nodes = screenContext['nodes'] as List?;
    if (nodes == null || elementIndex >= nodes.length) return action;

    final node = nodes[elementIndex] as Map<String, dynamic>?;
    if (node == null) return action;

    final bounds = node['bounds'] as Map<String, dynamic>?;
    if (bounds == null) return action;

    final left = bounds['left'] as int? ?? 0;
    final top = bounds['top'] as int? ?? 0;
    final right = bounds['right'] as int? ?? 0;
    final bottom = bounds['bottom'] as int? ?? 0;

    final centerX = (left + right) ~/ 2;
    final centerY = (top + bottom) ~/ 2;

    final newParams = Map<String, dynamic>.from(action.params);
    newParams['x'] = centerX;
    newParams['y'] = centerY;

    return ParsedAction(type: action.type, params: newParams);
  }
}
