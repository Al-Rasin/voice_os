class LLMResponse {
  final String rawText;
  final bool success;
  final String? error;

  const LLMResponse({
    required this.rawText,
    required this.success,
    this.error,
  });

  factory LLMResponse.success(String rawText) {
    return LLMResponse(
      rawText: rawText,
      success: true,
    );
  }

  factory LLMResponse.failure(String error) {
    return LLMResponse(
      rawText: '',
      success: false,
      error: error,
    );
  }
}
