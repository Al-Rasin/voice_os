import '../services/llm/response_parser.dart';

class PipelineResult {
  final bool success;
  final String? thought;
  final List<ParsedAction>? actions;
  final String? speak;
  final String? error;

  PipelineResult._({
    required this.success,
    this.thought,
    this.actions,
    this.speak,
    this.error,
  });

  factory PipelineResult.success({
    String? thought,
    List<ParsedAction>? actions,
    String? speak,
  }) {
    return PipelineResult._(
      success: true,
      thought: thought,
      actions: actions,
      speak: speak,
    );
  }

  factory PipelineResult.error(String error) {
    return PipelineResult._(
      success: false,
      error: error,
    );
  }
}
