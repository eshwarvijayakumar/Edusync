class ChatMessage {
  final String id;
  final String conversationId;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final List<String> suggestedFollowUps;
  final List<String> sourceCitations;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.suggestedFollowUps = const [],
    this.sourceCitations = const [],
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'created_at': timestamp.toIso8601String(),
      'suggested_follow_ups': suggestedFollowUps,
      'source_citations': sourceCitations,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      suggestedFollowUps: (json['suggested_follow_ups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sourceCitations: (json['source_citations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class ChatConversation {
  final String id;
  final String userId;
  final String title;
  final String? subject;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.title,
    this.subject,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'subject': subject,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Study Session',
      subject: json['subject'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
