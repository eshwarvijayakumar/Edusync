import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/study_tools_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/custom_button.dart';
import 'quiz_generator_sheet.dart';
import 'quiz_player_screen.dart';
import 'flashcard_generator_sheet.dart';
import 'flashcard_player_screen.dart';

class StudyToolsScreen extends StatefulWidget {
  const StudyToolsScreen({super.key});

  @override
  State<StudyToolsScreen> createState() => _StudyToolsScreenState();
}

class _StudyToolsScreenState extends State<StudyToolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _uploadFile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tools = Provider.of<StudyToolsProvider>(context, listen: false);
    final chat = Provider.of<ChatProvider>(context, listen: false);

    if (auth.userId != null) {
      try {
        final mat = await tools.uploadMaterial(auth.userId!);
        if (mat != null && mounted) {
          chat.attachMaterial(mat);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploaded "${mat.fileName}" successfully!'),
              backgroundColor: EduTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: EduTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tools = Provider.of<StudyToolsProvider>(context);

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: const Text('Study Tools'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: EduTheme.primaryIndigo,
          unselectedLabelColor: EduTheme.textLight,
          indicatorColor: EduTheme.primaryIndigo,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Quizzes'),
            Tab(text: 'Flashcards'),
            Tab(text: 'My Notes & PDFs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuizzesTab(tools),
          _buildFlashcardsTab(tools),
          _buildNotesTab(tools),
        ],
      ),
    );
  }

  Widget _buildQuizzesTab(StudyToolsProvider tools) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomButton(
            text: 'Generate New Practice Quiz',
            icon: Icons.add_rounded,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const QuizGeneratorSheet(),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Saved Quizzes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: tools.savedQuizzes.isEmpty
                ? _buildEmptyState(
                    icon: Icons.quiz_outlined,
                    title: 'No quizzes generated yet',
                    subtitle: 'Tap the button above to generate your first personalised practice quiz.',
                  )
                : ListView.builder(
                    itemCount: tools.savedQuizzes.length,
                    itemBuilder: (context, idx) {
                      final quiz = tools.savedQuizzes[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: EduTheme.surface,
                          borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
                          border: Border.all(color: EduTheme.borderSubtle),
                          boxShadow: EduTheme.cardShadow,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: EduTheme.primaryIndigoLight,
                              borderRadius: BorderRadius.circular(EduTheme.radiusSmall),
                            ),
                            child: const Icon(Icons.quiz_rounded, color: EduTheme.primaryIndigo, size: 22),
                          ),
                          title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          subtitle: Text(
                            '${quiz.subject} • ${quiz.totalQuestions} questions • ${quiz.isCompleted ? "Score: ${quiz.score}/${quiz.totalQuestions}" : "Not taken yet"}',
                            style: const TextStyle(fontSize: 12, color: EduTheme.textLight),
                          ),
                          trailing: const Icon(Icons.play_circle_fill_rounded, color: EduTheme.primaryIndigo, size: 28),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => QuizPlayerScreen(quiz: quiz)),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardsTab(StudyToolsProvider tools) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomButton(
            text: 'Create New Flashcard Deck',
            icon: Icons.add_rounded,
            backgroundColor: EduTheme.successGreen,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const FlashcardGeneratorSheet(),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Saved Flashcard Decks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: tools.savedDecks.isEmpty
                ? _buildEmptyState(
                    icon: Icons.style_outlined,
                    title: 'No flashcard decks yet',
                    subtitle: 'Create a deck to practice active recall with formulas and definitions.',
                  )
                : ListView.builder(
                    itemCount: tools.savedDecks.length,
                    itemBuilder: (context, idx) {
                      final deck = tools.savedDecks[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: EduTheme.surface,
                          borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
                          border: Border.all(color: EduTheme.borderSubtle),
                          boxShadow: EduTheme.cardShadow,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(EduTheme.radiusSmall),
                            ),
                            child: const Icon(Icons.style_rounded, color: EduTheme.successGreen, size: 22),
                          ),
                          title: Text(deck.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          subtitle: Text(
                            '${deck.subject} • ${deck.cards.length} cards • ${deck.masteredCount} mastered (${deck.masteryPercentage.toInt()}%)',
                            style: const TextStyle(fontSize: 12, color: EduTheme.textLight),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: EduTheme.textLight, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => FlashcardPlayerScreen(deck: deck)),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(StudyToolsProvider tools) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomButton(
            text: 'Upload PDF / Notes Document',
            icon: Icons.upload_file_rounded,
            backgroundColor: EduTheme.highlightOrange,
            onPressed: _uploadFile,
          ),
          const SizedBox(height: 8),
          const Text(
            'Supported: PDF, TXT (Maximum 15 MB). Uploads are stored privately.',
            style: TextStyle(fontSize: 12, color: EduTheme.textLight),
          ),
          const SizedBox(height: 20),
          const Text(
            'Uploaded Materials',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: tools.uploadedMaterials.isEmpty
                ? _buildEmptyState(
                    icon: Icons.folder_open_rounded,
                    title: 'No study materials uploaded',
                    subtitle: 'Upload your class notes or textbooks to ask questions directly from them.',
                  )
                : ListView.builder(
                    itemCount: tools.uploadedMaterials.length,
                    itemBuilder: (context, idx) {
                      final material = tools.uploadedMaterials[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: EduTheme.surface,
                          borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
                          border: Border.all(color: EduTheme.borderSubtle),
                          boxShadow: EduTheme.cardShadow,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: EduTheme.orangeLight,
                              borderRadius: BorderRadius.circular(EduTheme.radiusSmall),
                            ),
                            child: const Icon(Icons.description_rounded, color: EduTheme.highlightOrange, size: 22),
                          ),
                          title: Text(material.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Text(
                            '${material.fileName} • ${material.formattedSize}',
                            style: const TextStyle(fontSize: 12, color: EduTheme.textLight),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline_rounded, color: EduTheme.primaryIndigo),
                                tooltip: 'Ask AI About This Note',
                                onPressed: () {
                                  Provider.of<ChatProvider>(context, listen: false).attachMaterial(material);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Attached "${material.fileName}" to AI Chat'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: EduTheme.errorRed),
                                tooltip: 'Delete',
                                onPressed: () => tools.deleteMaterial(material.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: EduTheme.textLight),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EduTheme.textNavy)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: EduTheme.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
