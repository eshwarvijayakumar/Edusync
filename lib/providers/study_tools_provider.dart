import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_model.dart';
import '../models/flashcard_model.dart';
import '../models/study_material.dart';
import '../models/student_profile.dart';
import '../services/ai_service.dart';
import '../services/notes_service.dart';

class StudyToolsProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final NotesService _notesService = NotesService();

  List<Quiz> _savedQuizzes = [];
  List<FlashcardDeck> _savedDecks = [];
  List<StudyMaterial> _uploadedMaterials = [];
  bool _isLoading = false;

  // Study progress metrics
  int _studyStreakDays = 4;
  int _minutesStudiedThisWeek = 280;
  int _quizzesCompletedCount = 6;

  List<Quiz> get savedQuizzes => List.unmodifiable(_savedQuizzes);
  List<FlashcardDeck> get savedDecks => List.unmodifiable(_savedDecks);
  List<StudyMaterial> get uploadedMaterials => List.unmodifiable(_uploadedMaterials);
  bool get isLoading => _isLoading;
  int get studyStreakDays => _studyStreakDays;
  int get minutesStudiedThisWeek => _minutesStudiedThisWeek;
  int get quizzesCompletedCount => _quizzesCompletedCount;

  static const String _quizzesKey = 'edusync_saved_quizzes_v1';
  static const String _decksKey = 'edusync_saved_decks_v1';

  Future<void> loadAll(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Quizzes
      final qStr = prefs.getString(_quizzesKey);
      if (qStr != null) {
        final List<dynamic> list = jsonDecode(qStr);
        _savedQuizzes = list.map((item) => Quiz.fromJson(item)).toList();
      }

      // 2. Flashcards
      final dStr = prefs.getString(_decksKey);
      if (dStr != null) {
        final List<dynamic> list = jsonDecode(dStr);
        _savedDecks = list.map((item) => FlashcardDeck.fromJson(item)).toList();
      }

      // 3. Materials
      _uploadedMaterials = await _notesService.loadMaterials(userId);
    } catch (e) {
      debugPrint('Error loading study tools data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Quiz Generator ---
  Future<Quiz> createQuiz({
    required StudentProfile profile,
    required String topic,
    required String subject,
    required String mode,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final quiz = await _aiService.generateQuiz(
        profile: profile,
        topic: topic,
        subject: subject,
        mode: mode,
      );
      _savedQuizzes.insert(0, quiz);
      await _persistQuizzes();
      return quiz;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordQuizResult(String quizId, int score) async {
    final idx = _savedQuizzes.indexWhere((q) => q.id == quizId);
    if (idx != -1) {
      _savedQuizzes[idx] = _savedQuizzes[idx].copyWith(
        score: score,
        isCompleted: true,
      );
      _quizzesCompletedCount++;
      await _persistQuizzes();
      notifyListeners();
    }
  }

  Future<void> _persistQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _savedQuizzes.map((q) => q.toJson()).toList();
    await prefs.setString(_quizzesKey, jsonEncode(jsonList));
  }

  // --- Flashcard Generator ---
  Future<FlashcardDeck> createFlashcards({
    required StudentProfile profile,
    required String topic,
    required String subject,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final deck = await _aiService.generateFlashcards(
        profile: profile,
        topic: topic,
        subject: subject,
      );
      _savedDecks.insert(0, deck);
      await _persistDecks();
      return deck;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleCardMastery(String deckId, String cardId) async {
    final deckIdx = _savedDecks.indexWhere((d) => d.id == deckId);
    if (deckIdx != -1) {
      final cardIdx = _savedDecks[deckIdx].cards.indexWhere((c) => c.id == cardId);
      if (cardIdx != -1) {
        final card = _savedDecks[deckIdx].cards[cardIdx];
        card.isMastered = !card.isMastered;
        await _persistDecks();
        notifyListeners();
      }
    }
  }

  Future<void> _persistDecks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _savedDecks.map((d) => d.toJson()).toList();
    await prefs.setString(_decksKey, jsonEncode(jsonList));
  }

  // --- Study Materials ---
  Future<StudyMaterial?> uploadMaterial(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final material = await _notesService.pickAndUploadDocument(userId);
      if (material != null) {
        _uploadedMaterials.insert(0, material);
        notifyListeners();
      }
      return material;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMaterial(String materialId) async {
    await _notesService.deleteMaterial(materialId);
    _uploadedMaterials.removeWhere((m) => m.id == materialId);
    notifyListeners();
  }
}
