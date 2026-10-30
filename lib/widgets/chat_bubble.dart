import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../constants/theme.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String action)? onActionSelected;
  final VoidCallback? onRetry;

  const ChatBubble({
    super.key,
    required this.message,
    this.onActionSelected,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: EduTheme.primaryIndigo,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(EduTheme.radiusLarge),
                    topRight: Radius.circular(EduTheme.radiusLarge),
                    bottomLeft: Radius.circular(EduTheme.radiusLarge),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: EduTheme.buttonShadow,
                ),
                child: Text(
                  message.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI Companion Message or Error Bubble
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: message.isError ? const Color(0xFFFEE2E2) : EduTheme.primaryIndigoLight,
                  borderRadius: BorderRadius.circular(EduTheme.radiusSmall),
                ),
                child: Icon(
                  message.isError ? Icons.warning_rounded : Icons.school_rounded,
                  size: 16,
                  color: message.isError ? const Color(0xFFDC2626) : EduTheme.primaryIndigo,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message.isError ? 'EduSync Notice' : 'EduSync AI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: message.isError ? const Color(0xFFDC2626) : EduTheme.textNavy,
                ),
              ),
              const Spacer(),
              if (!message.isError)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16, color: EduTheme.textMuted),
                  tooltip: 'Copy Answer',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Answer copied to clipboard'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Message Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: message.isError ? const Color(0xFFFEF2F2) : EduTheme.surface,
              borderRadius: BorderRadius.circular(EduTheme.radiusLarge),
              border: Border.all(
                color: message.isError ? const Color(0xFFFCA5A5) : EduTheme.borderSubtle,
                width: 1,
              ),
              boxShadow: EduTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isError) ...[
                  // Error layout with Retry button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message.content,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry Question'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else ...[
                  // Normal AI Response layout
                  if (message.sourceCitations.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      children: message.sourceCitations.map((citation) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: EduTheme.orangeLight,
                            borderRadius: BorderRadius.circular(EduTheme.radiusSmall),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_book_rounded, size: 13, color: EduTheme.highlightOrange),
                              const SizedBox(width: 4),
                              Text(
                                citation,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Markdown Body
                  MarkdownBody(
                    data: message.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 14.5,
                        height: 1.55,
                        color: EduTheme.textNavy,
                        fontWeight: FontWeight.w400,
                      ),
                      h1: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
                      h2: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
                      h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EduTheme.primaryIndigo),
                      h4: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EduTheme.textNavy),
                      blockquote: const TextStyle(fontSize: 13, color: EduTheme.textMuted, fontStyle: FontStyle.italic),
                      code: TextStyle(
                        backgroundColor: EduTheme.background,
                        color: EduTheme.primaryIndigoDark,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Disclaimer
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 13, color: EduTheme.textMuted),
                      const SizedBox(width: 5),
                      const Expanded(
                        child: Text(
                          'AI can make mistakes. Verify important academic answers with your textbook or teacher.',
                          style: TextStyle(
                            fontSize: 11,
                            color: EduTheme.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Follow-up Action Chips (Only when not in error state)
          if (!message.isError) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionChip('Explain Simpler', Icons.lightbulb_outline),
                  _buildActionChip('Give an Example', Icons.auto_stories_outlined),
                  _buildActionChip('Create Quiz', Icons.quiz_outlined),
                  _buildActionChip('Make Flashcards', Icons.style_outlined),
                  _buildActionChip('Translate', Icons.translate_rounded),
                  _buildActionChip('Report Answer', Icons.flag_outlined),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: EduTheme.primaryIndigo),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: EduTheme.textNavy,
          ),
        ),
        backgroundColor: EduTheme.surface,
        side: const BorderSide(color: EduTheme.borderSubtle, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EduTheme.radiusFull),
        ),
        onPressed: () => onActionSelected?.call(label),
      ),
    );
  }
}
