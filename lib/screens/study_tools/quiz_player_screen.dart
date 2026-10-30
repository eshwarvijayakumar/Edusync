import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../models/quiz_model.dart';
import '../../providers/study_tools_provider.dart';
import '../../widgets/custom_button.dart';

class QuizPlayerScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizPlayerScreen({super.key, required this.quiz});

  @override
  State<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends State<QuizPlayerScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // question index -> option index
  final Map<int, String> _shortAnswers = {}; // question index -> text answer
  bool _showExplanation = false;
  bool _quizCompleted = false;
  int _score = 0;

  void _submitAnswer() {
    setState(() {
      _showExplanation = true;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _showExplanation = false;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    int calculatedScore = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      final q = widget.quiz.questions[i];
      if (q.isShortAnswer) {
        if (_shortAnswers[i]?.trim().isNotEmpty == true) {
          calculatedScore++;
        }
      } else {
        if (_selectedAnswers[i] == q.correctOptionIndex) {
          calculatedScore++;
        }
      }
    }

    setState(() {
      _score = calculatedScore;
      _quizCompleted = true;
    });

    Provider.of<StudyToolsProvider>(context, listen: false)
        .recordQuizResult(widget.quiz.id, calculatedScore);
  }

  @override
  Widget build(BuildContext context) {
    if (_quizCompleted) {
      return _buildResultScreen();
    }

    final question = widget.quiz.questions[_currentQuestionIndex];
    final isLast = _currentQuestionIndex == widget.quiz.questions.length - 1;

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: Text(widget.quiz.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EduTheme.textMuted),
                  ),
                  Text(
                    widget.quiz.mode.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EduTheme.primaryIndigo),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                backgroundColor: EduTheme.borderSubtle,
                valueColor: const AlwaysStoppedAnimation<Color>(EduTheme.primaryIndigo),
                borderRadius: BorderRadius.circular(EduTheme.radiusFull),
              ),
              const SizedBox(height: 24),

              // Question Card
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: EduTheme.surface,
                          borderRadius: BorderRadius.circular(EduTheme.radiusLarge),
                          border: Border.all(color: EduTheme.borderSubtle),
                          boxShadow: EduTheme.cardShadow,
                        ),
                        child: Text(
                          question.question,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: EduTheme.textNavy,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // MCQ Options or Short Answer Input
                      if (!question.isShortAnswer) ...[
                        ...question.options.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final text = entry.value;
                          final isSelected = _selectedAnswers[_currentQuestionIndex] == idx;
                          final isCorrect = idx == question.correctOptionIndex;

                          Color borderCol = EduTheme.borderSubtle;
                          Color bgCol = EduTheme.surface;
                          if (_showExplanation) {
                            if (isCorrect) {
                              borderCol = EduTheme.successGreen;
                              bgCol = const Color(0xFFECFDF5);
                            } else if (isSelected) {
                              borderCol = EduTheme.errorRed;
                              bgCol = const Color(0xFFFEF2F2);
                            }
                          } else if (isSelected) {
                            borderCol = EduTheme.primaryIndigo;
                            bgCol = EduTheme.primaryIndigoLight;
                          }

                          return GestureDetector(
                            onTap: _showExplanation
                                ? null
                                : () => setState(() => _selectedAnswers[_currentQuestionIndex] = idx),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: bgCol,
                                borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
                                border: Border.all(color: borderCol, width: isSelected ? 2 : 1),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isSelected ? EduTheme.primaryIndigo : EduTheme.background,
                                    child: Text(
                                      String.fromCharCode(65 + idx),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : EduTheme.textNavy,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      text,
                                      style: const TextStyle(fontSize: 14, color: EduTheme.textNavy, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ] else ...[
                        // Short Answer
                        TextField(
                          enabled: !_showExplanation,
                          maxLines: 4,
                          onChanged: (val) => _shortAnswers[_currentQuestionIndex] = val,
                          decoration: const InputDecoration(
                            hintText: 'Type your explanation / answer here...',
                          ),
                        ),
                      ],

                      // Explanation box
                      if (_showExplanation) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: EduTheme.orangeLight,
                            borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lightbulb_rounded, size: 18, color: EduTheme.highlightOrange),
                                  SizedBox(width: 6),
                                  Text(
                                    'Concept Explanation',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                question.explanation,
                                style: const TextStyle(fontSize: 13.5, color: EduTheme.textNavy, height: 1.4),
                              ),
                              if (question.isShortAnswer) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Key points expected: ${question.idealAnswer}',
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: EduTheme.textMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action buttons
              if (!_showExplanation)
                CustomButton(
                  text: 'Check Answer',
                  onPressed: (_selectedAnswers.containsKey(_currentQuestionIndex) ||
                          _shortAnswers[_currentQuestionIndex]?.isNotEmpty == true)
                      ? _submitAnswer
                      : null,
                )
              else
                CustomButton(
                  text: isLast ? 'View Final Results' : 'Next Question',
                  onPressed: _nextQuestion,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final total = widget.quiz.questions.length;
    final percentage = (total > 0) ? ((_score / total) * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(title: const Text('Quiz Completed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: EduTheme.primaryIndigoLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded, color: EduTheme.primaryIndigo, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Great Effort!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: EduTheme.textNavy),
              ),
              const SizedBox(height: 8),
              Text(
                'You scored $_score out of $total ($percentage%)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: EduTheme.primaryIndigo),
              ),
              const SizedBox(height: 12),
              const Text(
                'Review your mistake points and consult EduSync AI for any concepts you found challenging.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: EduTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 36),
              CustomButton(
                text: 'Done & Return to Study Tools',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
