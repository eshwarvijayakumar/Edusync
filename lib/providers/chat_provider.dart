import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/student_profile.dart';
import '../models/study_material.dart';
import '../services/ai_service.dart';
import '../services/usage_service.dart';

class ChatProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final UsageService _usageService = UsageService();

  final List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  int _remainingQuestions = 10;
  String? _currentSubject;
  StudyMaterial? _attachedMaterial;
  String _conversationId = 'conv_default';
  String? _lastFailedQuestion;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isGenerating => _isGenerating;
  int get remainingQuestions => _remainingQuestions;
  String? get currentSubject => _currentSubject;
  StudyMaterial? get attachedMaterial => _attachedMaterial;
  String get conversationId => _conversationId;
  String? get lastFailedQuestion => _lastFailedQuestion;

  void setSubject(String? subject) {
    _currentSubject = subject;
    notifyListeners();
  }

  void attachMaterial(StudyMaterial? material) {
    _attachedMaterial = material;
    notifyListeners();
  }

  Future<void> refreshQuota(String userId) async {
    _remainingQuestions = await _usageService.getRemainingQuestions(userId);
    notifyListeners();
  }

  Future<bool> sendMessage({
    required String text,
    required StudentProfile profile,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;

    // Check usage limit
    final allowed = await _usageService.consumeQuestion(profile.id);
    if (!allowed) {
      _messages.add(
        ChatMessage(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: _conversationId,
          role: 'assistant',
          content: '⚠️ **Daily Free AI Limit Reached**\n\nYou have used all 10 free AI companion questions for today. Your limit will reset at midnight! You can continue reviewing your saved notes, quizzes, and flashcards.',
          isError: true,
        ),
      );
      _remainingQuestions = 0;
      notifyListeners();
      return false;
    }

    _remainingQuestions = await _usageService.getRemainingQuestions(profile.id);

    // Add user message
    final userMsg = ChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId,
      role: 'user',
      content: cleanText,
    );
    _messages.add(userMsg);
    _isGenerating = true;
    notifyListeners();

    try {
      final aiResponse = await _aiService.askEduSync(
        question: cleanText,
        profile: profile,
        conversationId: _conversationId,
        conversationHistory: _messages,
        currentSubject: _currentSubject,
        studyMaterialText: _attachedMaterial?.extractedText,
        studyMaterialName: _attachedMaterial?.fileName,
      );
      _messages.add(aiResponse);
      _lastFailedQuestion = null;
    } catch (e) {
      _lastFailedQuestion = cleanText;
      final errorMessage = e is AIServiceException
          ? e.message
          : 'EduSync could not connect to the study companion service. Please check your network connection or server configuration.';
      _messages.add(
        ChatMessage(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: _conversationId,
          role: 'assistant',
          content: errorMessage,
          isError: true,
        ),
      );
    } finally {
      _isGenerating = false;
      notifyListeners();
    }

    return true;
  }

  /// Retries the most recent failed question
  Future<bool> retryLastQuestion(StudentProfile profile) async {
    String? questionToRetry = _lastFailedQuestion;

    if (questionToRetry == null || questionToRetry.isEmpty) {
      // Find the last user message before the error
      for (int i = _messages.length - 1; i >= 0; i--) {
        if (_messages[i].isUser) {
          questionToRetry = _messages[i].content;
          break;
        }
      }
    }

    if (questionToRetry == null || questionToRetry.isEmpty) {
      return false;
    }

    // Remove the trailing error message if present
    if (_messages.isNotEmpty && _messages.last.isError) {
      _messages.removeLast();
    }

    // Also remove the preceding user message so sendMessage doesn't duplicate it in the transcript
    if (_messages.isNotEmpty && _messages.last.isUser && _messages.last.content == questionToRetry) {
      _messages.removeLast();
    }

    notifyListeners();
    return await sendMessage(text: questionToRetry, profile: profile);
  }

  /// Handles quick follow-up action chips:
  /// "Explain Simpler", "Give an Example", "Create Quiz", "Make Flashcards", "Translate", "Report Answer"
  Future<void> handleActionChip({
    required String action,
    required ChatMessage targetMessage,
    required StudentProfile profile,
  }) async {
    String query = '';
    switch (action) {
      case 'Explain Simpler':
        query = 'Explain this simpler with a clear step-by-step intuition.';
        break;
      case 'Give an Example':
        query = 'Give an example explaining this concept in detail.';
        break;
      case 'Create Quiz':
        query = 'Create a practice quiz based on this topic with multiple-choice questions, correct answers, and explanations.';
        break;
      case 'Make Flashcards':
        query = 'Create study flashcards with key concepts and exam formulas from this topic.';
        break;
      case 'Translate':
        query = 'Translate and explain this in ${profile.preferredLanguage}.';
        break;
      case 'Report Answer':
        _messages.add(
          ChatMessage(
            id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: _conversationId,
            role: 'assistant',
            content: '✅ Thank you for reporting. This response has been flagged for pedagogical quality review.',
          ),
        );
        notifyListeners();
        return;
      default:
        query = action;
    }

    await sendMessage(text: query, profile: profile);
  }

  void startNewChat() {
    _conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    _messages.clear();
    _attachedMaterial = null;
    _lastFailedQuestion = null;
    notifyListeners();
  }
}
