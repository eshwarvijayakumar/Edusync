import 'package:flutter/material.dart';
import '../../constants/theme.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: const Text('Terms of Use'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EduSync Terms of Use',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
            ),
            SizedBox(height: 6),
            Text(
              'Last Updated: October 2026',
              style: TextStyle(fontSize: 12, color: EduTheme.textLight),
            ),
            SizedBox(height: 18),
            Text(
              '1. Educational Purpose & Disclaimer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
            ),
            SizedBox(height: 6),
            Text(
              'EduSync is designed as an interactive AI study companion to supplement your learning. Artificial Intelligence models can occasionally produce inaccurate responses or hallucinations. Students must verify essential academic equations, historical dates, and examination answers with their prescribed textbooks (such as NCERT) or certified teachers.',
              style: TextStyle(fontSize: 14, color: EduTheme.textMuted, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '2. Responsible Academic Conduct',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
            ),
            SizedBox(height: 6),
            Text(
              'Students agree to use EduSync for personal learning, homework assistance, concept clarification, and test preparation. Users must not attempt to upload malicious software or bypass daily usage limits.',
              style: TextStyle(fontSize: 14, color: EduTheme.textMuted, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '3. Fair Use & Free Quota',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
            ),
            SizedBox(height: 6),
            Text(
              'Free accounts are allocated up to 10 AI companion queries every 24 hours. The quota resets automatically at midnight.',
              style: TextStyle(fontSize: 14, color: EduTheme.textMuted, height: 1.5),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
