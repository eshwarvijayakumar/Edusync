class Flashcard {
  final String id;
  final String front;
  final String back;
  final String? keyConcept;
  bool isMastered;

  Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.keyConcept,
    this.isMastered = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'key_concept': keyConcept,
      'is_mastered': isMastered,
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String? ?? '',
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      keyConcept: json['key_concept'] as String?,
      isMastered: json['is_mastered'] as bool? ?? false,
    );
  }
}

class FlashcardDeck {
  final String id;
  final String userId;
  final String title;
  final String subject;
  final List<Flashcard> cards;
  final DateTime createdAt;

  FlashcardDeck({
    required this.id,
    required this.userId,
    required this.title,
    required this.subject,
    required this.cards,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get masteredCount => cards.where((c) => c.isMastered).length;
  double get masteryPercentage =>
      cards.isEmpty ? 0 : (masteredCount / cards.length) * 100;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'subject': subject,
      'cards': cards.map((c) => c.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) {
    return FlashcardDeck(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Revision Deck',
      subject: json['subject'] as String? ?? 'General',
      cards: (json['cards'] as List<dynamic>?)
              ?.map((c) => Flashcard.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
