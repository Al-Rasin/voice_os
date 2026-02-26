class ChatMessage {
  final String role; // "system", "user", "assistant"
  final String content;

  const ChatMessage({
    required this.role,
    required this.content,
  });

  Map<String, String> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }

  factory ChatMessage.user(String content) {
    return ChatMessage(role: 'user', content: content);
  }

  factory ChatMessage.assistant(String content) {
    return ChatMessage(role: 'assistant', content: content);
  }

  factory ChatMessage.system(String content) {
    return ChatMessage(role: 'system', content: content);
  }
}
