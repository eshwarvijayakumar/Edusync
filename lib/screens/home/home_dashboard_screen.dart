import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/study_tools_provider.dart';
import '../../widgets/study_stat_card.dart';
import '../../widgets/quota_pill.dart';
import '../study_tools/quiz_generator_sheet.dart';
import '../study_tools/flashcard_generator_sheet.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;
  const HomeDashboardScreen({super.key, required this.onNavigateToTab});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final List<Map<String, dynamic>> _dailyTasks = [
    {'title': 'Revise Science / Engineering Unit 2', 'done': true},
    {'title': 'Complete 5 AI practice quiz questions', 'done': false},
    {'title': 'Review 10 flashcards before bed', 'done': false},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      final chat = Provider.of<ChatProvider>(context, listen: false);
      final tools = Provider.of<StudyToolsProvider>(context, listen: false);

      if (auth.userId != null) {
        if (!profile.hasProfile) {
          profile.fetchProfile(auth.userId!);
        }
        chat.refreshQuota(auth.userId!);
        tools.loadAll(auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final toolsProvider = Provider.of<StudyToolsProvider>(context);
    final profile = profileProvider.profile;

    final studentName = profile?.name ?? 'Student';
    final studentBadge = profile?.studentBadge ?? 'Learner';

    return Scaffold(
      backgroundColor: EduTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (auth.userId != null) {
              await profileProvider.fetchProfile(auth.userId!);
              await chatProvider.refreshQuota(auth.userId!);
              await toolsProvider.loadAll(auth.userId!);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $studentName 👋',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: EduTheme.textNavy,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: EduTheme.primaryIndigoLight,
                              borderRadius: BorderRadius.circular(EduTheme.radiusFull),
                            ),
                            child: Text(
                              studentBadge,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: EduTheme.primaryIndigoDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    QuotaPill(remaining: chatProvider.remainingQuestions),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Action Shortcuts (Ask EduSync, Upload Notes, Generate Quiz, Create Flashcards, Study Progress)
                _buildQuickActionGrid(context),
                const SizedBox(height: 24),

                // Daily Study Plan Card
                _buildDailyStudyPlanCard(),
                const SizedBox(height: 20),

                // Weekly Progress Card
                _buildWeeklyProgressCard(toolsProvider),
                const SizedBox(height: 20),

                // Recent Chats Section
                _buildRecentChatsSection(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: EduTheme.textNavy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                title: 'Ask EduSync',
                subtitle: 'Personalised AI help',
                icon: Icons.chat_bubble_rounded,
                bgColor: EduTheme.primaryIndigo,
                textColor: Colors.white,
                iconColor: Colors.white,
                onTap: () => widget.onNavigateToTab(1), // Chat tab
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                title: 'Upload Notes',
                subtitle: 'Ask PDF questions',
                icon: Icons.upload_file_rounded,
                bgColor: EduTheme.surface,
                textColor: EduTheme.textNavy,
                iconColor: EduTheme.highlightOrange,
                onTap: () => _handleUploadNotes(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                title: 'Generate Quiz',
                subtitle: 'MCQ & Short answer',
                icon: Icons.quiz_rounded,
                bgColor: EduTheme.surface,
                textColor: EduTheme.textNavy,
                iconColor: EduTheme.primaryIndigo,
                onTap: () => _handleGenerateQuiz(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                title: 'Flashcards',
                subtitle: 'Interactive revision',
                icon: Icons.style_rounded,
                bgColor: EduTheme.surface,
                textColor: EduTheme.textNavy,
                iconColor: EduTheme.successGreen,
                onTap: () => _handleCreateFlashcards(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(EduTheme.radiusLarge),
          border: Border.all(
            color: bgColor == EduTheme.surface ? EduTheme.borderSubtle : Colors.transparent,
          ),
          boxShadow: bgColor == EduTheme.primaryIndigo ? EduTheme.buttonShadow : EduTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor == EduTheme.primaryIndigo
                    ? Colors.white.withOpacity(0.2)
                    : EduTheme.background,
                borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: bgColor == EduTheme.primaryIndigo ? Colors.white70 : EduTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyStudyPlanCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EduTheme.surface,
        borderRadius: BorderRadius.circular(EduTheme.radiusLarge),
        border: Border.all(color: EduTheme.borderSubtle, width: 1),
        boxShadow: EduTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: EduTheme.primaryIndigo),
                  SizedBox(width: 8),
                  Text(
                    'Daily Study Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: EduTheme.textNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EduTheme.orangeLight,
                  borderRadius: BorderRadius.circular(EduTheme.radiusSmall),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: EduTheme.highlightOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 6),
          ..._dailyTasks.asMap().entries.map((entry) {
            final idx = entry.key;
            final task = entry.value;
            final isDone = task['done'] as bool;
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              activeColor: EduTheme.primaryIndigo,
              title: Text(
                task['title'] as String,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDone ? EduTheme.textLight : EduTheme.textNavy,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: isDone,
              onChanged: (val) {
                setState(() {
                  _dailyTasks[idx]['done'] = val ?? false;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressCard(StudyToolsProvider tools) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EduTheme.surface,
        borderRadius: BorderRadius.circular(EduTheme.radiusLarge),
        border: Border.all(color: EduTheme.borderSubtle, width: 1),
        boxShadow: EduTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, size: 20, color: EduTheme.successGreen),
                  SizedBox(width: 8),
                  Text(
                    'Weekly Learning Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: EduTheme.textNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Study Streak', style: TextStyle(fontSize: 12, color: EduTheme.textLight)),
                    const SizedBox(height: 2),
                    Text('${tools.studyStreakDays} Days 🔥', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: EduTheme.textNavy)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hours Studied', style: TextStyle(fontSize: 12, color: EduTheme.textLight)),
                    const SizedBox(height: 2),
                    Text('${(tools.minutesStudiedThisWeek / 60).toStringAsFixed(1)} hrs', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: EduTheme.textNavy)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quizzes Passed', style: TextStyle(fontSize: 12, color: EduTheme.textLight)),
                    const SizedBox(height: 2),
                    Text('${tools.quizzesCompletedCount} Completed', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: EduTheme.textNavy)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: 0.75,
            progressColor: EduTheme.primaryIndigo,
            backgroundColor: EduTheme.background,
            barRadius: const Radius.circular(EduTheme.radiusFull),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '75% of weekly academic target completed',
              style: TextStyle(fontSize: 11, color: EduTheme.textLight, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentChatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Chats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: EduTheme.textNavy,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateToTab(1),
              child: const Text('Open Chat', style: TextStyle(color: EduTheme.primaryIndigo, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: EduTheme.surface,
            borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
            border: Border.all(color: EduTheme.borderSubtle),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EduTheme.primaryIndigoLight,
                borderRadius: BorderRadius.circular(EduTheme.radiusSmall),
              ),
              child: const Icon(Icons.forum_rounded, color: EduTheme.primaryIndigo, size: 20),
            ),
            title: const Text('Concept breakdown & exam strategy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Personalised study session with EduSync AI', style: TextStyle(fontSize: 12, color: EduTheme.textLight)),
            trailing: const Icon(Icons.chevron_right_rounded, color: EduTheme.textLight),
            onTap: () => widget.onNavigateToTab(1),
          ),
        ),
      ],
    );
  }

  void _handleUploadNotes(BuildContext context) async {
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
              content: Text('Uploaded "${mat.fileName}" successfully! Attached to EduSync Chat.'),
              backgroundColor: EduTheme.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onNavigateToTab(1); // Jump to chat
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

  void _handleGenerateQuiz(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuizGeneratorSheet(),
    );
  }

  void _handleCreateFlashcards(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FlashcardGeneratorSheet(),
    );
  }
}
