import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/quota_pill.dart';
import '../study_tools/quiz_generator_sheet.dart';
import '../study_tools/flashcard_generator_sheet.dart';

class StudyChatScreen extends StatefulWidget {
  const StudyChatScreen({super.key});

  @override
  State<StudyChatScreen> createState() => _StudyChatScreenState();
}

class _StudyChatScreenState extends State<StudyChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<String> _getDynamicSuggestedPrompts(profile) {
    if (profile == null) return [];
    if (profile.isSchoolStudent) {
      final grade = profile.grade ?? 'Grade 10';
      final board = profile.board ?? 'CBSE';
      return [
        'Explain photosynthesis for $board $grade.',
        'Explain laws of reflection and refraction.',
        'Explain plant anatomy and plastids.',
        'Solve a quadratic equation step by step.',
        'Explain this in Hindi.',
      ];
    } else {
      final deg = profile.degree ?? 'B.Tech';
      final dept = profile.department ?? 'CSE';
      return [
        'Explain waterfall model for $deg $dept.',
        'Help me understand Data Structures for $deg $dept.',
        'Explain Dijkstra\'s algorithm with time complexity.',
        'How is this concept asked in placement interviews?',
        'How does a microwave oven work?',
      ];
    }
  }

  Future<void> _handleSend([String? presetText]) async {
    final query = presetText ?? _textController.text.trim();
    if (query.isEmpty) return;

    final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
    final chat = Provider.of<ChatProvider>(context, listen: false);

    if (profile == null) return;

    if (presetText == null) {
      _textController.clear();
    }

    _scrollToBottom();
    final sent = await chat.sendMessage(text: query, profile: profile);
    _scrollToBottom();

    if (!sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Free daily question limit reached (10/10). Resets at midnight!'),
          backgroundColor: EduTheme.highlightOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final profile = profileProvider.profile;

    final suggestedPrompts = _getDynamicSuggestedPrompts(profile);

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EduSync AI Chat'),
            if (profile != null)
              Text(
                '${profile.studentBadge} • ${profile.preferredLanguage}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: EduTheme.textMuted,
                ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: QuotaPill(remaining: chatProvider.remainingQuestions),
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_rounded, color: EduTheme.primaryIndigo),
            tooltip: 'New Chat',
            onPressed: () => chatProvider.startNewChat(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Attached Study Material Pill if any
          if (chatProvider.attachedMaterial != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: EduTheme.orangeLight,
              child: Row(
                children: [
                  const Icon(Icons.description_rounded, size: 16, color: EduTheme.highlightOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Asking questions about: ${chatProvider.attachedMaterial!.fileName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFB45309)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => chatProvider.attachMaterial(null),
                  ),
                ],
              ),
            ),
          ],

          // Chat Messages List
          Expanded(
            child: chatProvider.messages.isEmpty
                ? _buildEmptyChatState(suggestedPrompts)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    itemCount: chatProvider.messages.length + (chatProvider.isGenerating ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatProvider.messages.length && chatProvider.isGenerating) {
                        return _buildTypingIndicator();
                      }
                      final msg = chatProvider.messages[index];
                      return ChatBubble(
                        message: msg,
                        onRetry: () {
                          if (profile != null) {
                            chatProvider.retryLastQuestion(profile);
                            _scrollToBottom();
                          }
                        },
                        onActionSelected: (action) {
                          if (profile != null) {
                            chatProvider.handleActionChip(
                              action: action,
                              targetMessage: msg,
                              profile: profile,
                            );
                            _scrollToBottom();
                          }
                        },
                      );
                    },
                  ),
          ),

          // Suggested Prompts Row if not empty and not generating
          if (chatProvider.messages.isNotEmpty && !chatProvider.isGenerating) ...[
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: suggestedPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  return ActionChip(
                    label: Text(
                      suggestedPrompts[idx],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: EduTheme.textNavy),
                    ),
                    backgroundColor: EduTheme.surface,
                    side: const BorderSide(color: EduTheme.borderSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EduTheme.radiusFull)),
                    onPressed: () => _handleSend(suggestedPrompts[idx]),
                  );
                },
              ),
            ),
          ],

          // Message Input Field
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyChatState(List<String> suggestedPrompts) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: EduTheme.primaryIndigoLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 42,
                color: EduTheme.primaryIndigo,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How can EduSync help you today?',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: EduTheme.textNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ask any concept, numerical, exam strategy, or question from your notes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: EduTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // Prompt suggestions cards
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Suggested for your level:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: EduTheme.textLight,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...suggestedPrompts.map((prompt) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _handleSend(prompt),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: EduTheme.surface,
                    side: const BorderSide(color: EduTheme.borderSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 16, color: EduTheme.highlightOrange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prompt,
                          style: const TextStyle(
                            fontSize: 13,
                            color: EduTheme.textNavy,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: EduTheme.textLight),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: EduTheme.surface,
              borderRadius: BorderRadius.circular(EduTheme.radiusLarge),
              border: Border.all(color: EduTheme.borderSubtle),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(EduTheme.primaryIndigo),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'EduSync is thinking…',
                  style: TextStyle(fontSize: 12, color: EduTheme.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: EduTheme.surface,
        border: const Border(
          top: BorderSide(color: EduTheme.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 15, color: EduTheme.textNavy),
                decoration: const InputDecoration(
                  hintText: 'Ask EduSync a study question...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (val) => _handleSend(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: EduTheme.primaryIndigo,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: () => _handleSend(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
