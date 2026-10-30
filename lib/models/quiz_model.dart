class QuizQuestion {
  final String id;
  final String question;
  final List<String> options; // Empty for short-answer mode
  final int correctOptionIndex; // -1 for short answer
  final String idealAnswer; // For short answer verification
  final String explanation;
  final bool isShortAnswer;

  QuizQuestion({
    required this.id,
    required this.question,
    this.options = const [],
    this.correctOptionIndex = -1,
    this.idealAnswer = '',
    required this.explanation,
    this.isShortAnswer = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correct_option_index': correctOptionIndex,
      'ideal_answer': idealAnswer,
      'explanation': explanation,
      'is_short_answer': isShortAnswer,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      correctOptionIndex: json['correct_option_index'] as int? ?? -1,
      idealAnswer: json['ideal_answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      isShortAnswer: json['is_short_answer'] as bool? ?? false,
    );
  }
}

class Quiz {
  final String id;
  final String userId;
  final String title;
  final String subject;
  final String mode; // 'mcq' or 'short_answer'
  final List<QuizQuestion> questions;
  final int? score;
  final int totalQuestions;
  final bool isCompleted;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.userId,
    required this.title,
    required this.subject,
    required this.mode,
    required this.questions,
    this.score,
    required this.totalQuestions,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'subject': subject,
      'mode': mode,
      'questions': questions.map((q) => q.toJson()).toList(),
      'score': score,
      'total_questions': totalQuestions,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Subject Quiz',
      subject: json['subject'] as String? ?? 'General',
      mode: json['mode'] as String? ?? 'mcq',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      score: json['score'] as int?,
      totalQuestions: json['total_questions'] as int? ?? 5,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Quiz copyWith({
    int? score,
    bool? isCompleted,
  }) {
    return Quiz(
      id: id,
      userId: userId,
      title: title,
      subject: subject,
      mode: mode,
      questions: questions,
      score: score ?? this.score,
      totalQuestions: totalQuestions,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
