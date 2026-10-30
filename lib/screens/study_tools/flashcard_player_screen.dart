import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../models/flashcard_model.dart';
import '../../providers/study_tools_provider.dart';

class FlashcardPlayerScreen extends StatefulWidget {
  final FlashcardDeck deck;
  const FlashcardPlayerScreen({super.key, required this.deck});

  @override
  State<FlashcardPlayerScreen> createState() => _FlashcardPlayerScreenState();
}

class _FlashcardPlayerScreenState extends State<FlashcardPlayerScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _nextCard(bool mastered) {
    final tools = Provider.of<StudyToolsProvider>(context, listen: false);
    final card = widget.deck.cards[_currentIndex];

    if (mastered != card.isMastered) {
      tools.toggleCardMastery(widget.deck.id, card.id);
    }

    if (_isFlipped) {
      _controller.reverse();
      _isFlipped = false;
    }

    if (_currentIndex < widget.deck.cards.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Deck completed! You revised all cards.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.deck.cards[_currentIndex];
    final total = widget.deck.cards.length;

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: Text(widget.deck.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Progress header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Card ${_currentIndex + 1} of $total',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EduTheme.textMuted),
                  ),
                  Text(
                    'Tap card to flip',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: EduTheme.textLight),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentIndex + 1) / total,
                backgroundColor: EduTheme.borderSubtle,
                valueColor: const AlwaysStoppedAnimation<Color>(EduTheme.successGreen),
                borderRadius: BorderRadius.circular(EduTheme.radiusFull),
              ),
              const SizedBox(height: 32),

              // Interactive 3D Flip Card
              Expanded(
                child: GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final angle = _animation.value * pi;
                      final isFront = angle < pi / 2;

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // perspective
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: isFront
                            ? _buildFrontCard(card)
                            : Transform(
                                transform: Matrix4.identity()..rotateY(pi),
                                alignment: Alignment.center,
                                child: _buildBackCard(card),
                              ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Action buttons (Review Again vs Got It)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.styleFrom(
                      side: const BorderSide(color: EduTheme.highlightOrange, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EduTheme.radiusMedium)),
                    ).buildOutlinedButton(
                      onPressed: () => _nextCard(false),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.replay_rounded, color: EduTheme.highlightOrange, size: 18),
                          SizedBox(width: 8),
                          Text('Review Again', style: TextStyle(color: EduTheme.highlightOrange, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _nextCard(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EduTheme.successGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EduTheme.radiusMedium)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Got It!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(Flashcard card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: EduTheme.surface,
        borderRadius: BorderRadius.circular(EduTheme.radiusLarge),
        border: Border.all(color: EduTheme.borderSubtle, width: 1.5),
        boxShadow: EduTheme.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: EduTheme.primaryIndigoLight,
              borderRadius: BorderRadius.circular(EduTheme.radiusFull),
            ),
            child: Text(
              card.keyConcept ?? 'Question / Concept',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EduTheme.primaryIndigoDark),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            card.front,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: EduTheme.textNavy,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tap anywhere to reveal answer 🔄',
            style: TextStyle(fontSize: 12, color: EduTheme.textLight, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(Flashcard card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(EduTheme.radiusLarge),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
        boxShadow: EduTheme.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: EduTheme.successGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(EduTheme.radiusFull),
            ),
            child: const Text(
              'Answer & Core Explanation',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            card.back,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w600,
              color: EduTheme.textNavy,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

extension OutlinedButtonExt on ButtonStyle {
  Widget buildOutlinedButton({required VoidCallback onPressed, required Widget child}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: this,
      child: child,
    );
  }
}
