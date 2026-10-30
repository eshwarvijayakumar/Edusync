import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/study_tools_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'flashcard_player_screen.dart';

class FlashcardGeneratorSheet extends StatefulWidget {
  const FlashcardGeneratorSheet({super.key});

  @override
  State<FlashcardGeneratorSheet> createState() => _FlashcardGeneratorSheetState();
}

class _FlashcardGeneratorSheetState extends State<FlashcardGeneratorSheet> {
  final _topicController = TextEditingController();
  String _selectedSubject = 'Mathematics';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
    if (profile != null && profile.subjects.isNotEmpty) {
      _selectedSubject = profile.subjects.first;
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generateDeck() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a topic name'),
          backgroundColor: EduTheme.errorRed,
        ),
      );
      return;
    }

    final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
    final tools = Provider.of<StudyToolsProvider>(context, listen: false);

    if (profile == null) return;

    setState(() => _isLoading = true);
    try {
      final deck = await tools.createFlashcards(
        profile: profile,
        topic: topic,
        subject: _selectedSubject,
      );

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlashcardPlayerScreen(deck: deck),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating flashcards: $e'), backgroundColor: EduTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context).profile;
    final subjects = profile?.subjects.isNotEmpty == true ? profile!.subjects : ['Mathematics', 'Science', 'English'];

    return Container(
      decoration: const BoxDecoration(
        color: EduTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(EduTheme.radiusLarge)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EduTheme.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Icon(Icons.style_rounded, color: EduTheme.successGreen),
              SizedBox(width: 8),
              Text(
                'Create AI Flashcards',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Generate active recall cards with key definitions, formulas, and common exam traps.',
            style: TextStyle(fontSize: 13, color: EduTheme.textMuted),
          ),
          const SizedBox(height: 20),

          // Topic Input
          CustomTextField(
            controller: _topicController,
            label: 'Topic or Unit',
            hint: 'e.g. Newton\'s Laws, Dynamic Programming, Periodic Table',
            prefixIcon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 16),

          // Subject Selector
          const Text(
            'Subject',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EduTheme.textNavy),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: EduTheme.surface,
              borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
              border: Border.all(color: EduTheme.borderSubtle, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: subjects.contains(_selectedSubject) ? _selectedSubject : subjects.first,
                isExpanded: true,
                items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedSubject = val!),
              ),
            ),
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'Generate Deck',
            isLoading: _isLoading,
            onPressed: _generateDeck,
          ),
        ],
      ),
    );
  }
}
