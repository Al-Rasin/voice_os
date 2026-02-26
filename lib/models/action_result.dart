class ActionResult {
  final bool success;
  final String? error;
  final List<String>? details;

  ActionResult._({
    required this.success,
    this.error,
    this.details,
  });

  factory ActionResult.ok() {
    return ActionResult._(success: true);
  }

  factory ActionResult.fail(String error) {
    return ActionResult._(success: false, error: error);
  }

  factory ActionResult.withDetails(bool success, List<String> details) {
    return ActionResult._(success: success, details: details);
  }
}
