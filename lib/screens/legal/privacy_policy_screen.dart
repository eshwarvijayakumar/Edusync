import 'package:flutter/material.dart';
import '../../constants/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EduSync Privacy Policy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
            ),
            SizedBox(height: 6),
            Text(
              'Last Updated: October 2026',
              style: TextStyle(fontSize: 12, color: EduTheme.textLight),
            ),
            SizedBox(height: 18),
            Text(
              '1. Data We Collect',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
            ),
            SizedBox(height: 6),
            Text(
              'EduSync collects minimal information required to tailor your personal academic study companion: your name, email, mobile number, educational level (grade or degree), subjects, and learning goals. Uploaded notes and documents are encrypted and kept strictly private to your account.',
              style: TextStyle(fontSize: 14, color: EduTheme.textMuted, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '2. How We Protect Student Privacy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
            ),
            SizedBox(height: 6),
            Text(
              'We implement Row Level Security (RLS) on our database servers. Only your authenticated session can access your notes, quizzes, flashcards, and conversation logs. We do not sell your personal data to third parties or advertisers.',
              style: TextStyle(fontSize: 14, color: EduTheme.textMuted, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '3. Artificial Intelligence & Academic Queries',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
            ),
            SizedBox(height: 6),
            Text(
              'Your questions are processed securely through server-side AI functions without exposing private API keys to the client. Responses are generated solely to assist learning and concept clarity.',
              style: TextStyle(fontSize: 14, color: EduTheme.textMuted, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '4. Your Rights & Account Deletion',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
            ),
            SizedBox(height: 6),
            Text(
              'You can update your academic profile at any time. You also have the right to permanently delete your account and all associated data directly from the Profile settings.',
              style: TextStyle(fontSize: 14, color: EduTheme.textMuted, height: 1.5),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
