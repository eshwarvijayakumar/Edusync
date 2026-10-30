import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edusync/models/student_profile.dart';
import 'package:edusync/models/chat_message.dart';
import 'package:edusync/constants/app_constants.dart';
import 'package:edusync/constants/theme.dart';
import 'package:edusync/widgets/quota_pill.dart';
import 'package:edusync/widgets/study_stat_card.dart';
import 'package:edusync/widgets/chat_bubble.dart';
import 'package:edusync/services/ai_service.dart';
import 'package:edusync/providers/chat_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  group('StudentProfile Model Tests', () {
    test('School Student badge generates correctly', () {
      final profile = StudentProfile(
        id: 'test_1',
        email: 'student@example.com',
        name: 'Aarav Sharma',
        isSchoolStudent: true,
        grade: 'Grade 10',
        board: 'CBSE',
        state: 'Tamil Nadu',
        medium: 'English',
        subjects: ['Mathematics', 'Science'],
        mainGoal: 'Prepare for exams',
      );

      expect(profile.studentBadge, equals('CBSE • Grade 10'));
      expect(profile.preferredLanguage, equals('English'));
      expect(profile.isSchoolStudent, isTrue);
    });

    test('Tamil Nadu State Board profile generates correctly', () {
      final profile = StudentProfile(
        id: 'test_tn',
        email: 'kavitha@example.com',
        name: 'Kavitha R',
        isSchoolStudent: true,
        grade: 'Grade 10',
        board: 'Tamil Nadu State Board',
        state: 'Tamil Nadu',
        medium: 'English',
        subjects: ['Science', 'Mathematics'],
        mainGoal: 'Prepare for exams',
      );

      expect(profile.studentBadge, equals('Tamil Nadu State Board • Grade 10'));
      expect(profile.isSchoolStudent, isTrue);
    });

    test('College Student badge generates correctly', () {
      final profile = StudentProfile(
        id: 'test_2',
        email: 'college@example.com',
        name: 'Priya Patel',
        isSchoolStudent: false,
        degree: 'B.Tech',
        department: 'Computer Science',
        yearOrSem: 'Semester 4',
        medium: 'English',
        subjects: ['Operating Systems', 'DSA'],
        mainGoal: 'Placements & coding practice',
      );

      expect(profile.studentBadge, equals('B.Tech • Computer Science • Semester 4'));
      expect(profile.isSchoolStudent, isFalse);
    });

    test('Serialization to and from JSON preserves all fields', () {
      final original = StudentProfile(
        id: 'uid_123',
        email: 'rahul@test.com',
        mobile: '9876543210',
        name: 'Rahul Varma',
        isSchoolStudent: true,
        grade: 'Grade 12',
        board: 'CBSE',
        subjects: ['Physics', 'Chemistry', 'Mathematics'],
        mainGoal: 'Improve marks',
      );

      final json = original.toJson();
      final reconstituted = StudentProfile.fromJson(json);

      expect(reconstituted.id, equals(original.id));
      expect(reconstituted.email, equals(original.email));
      expect(reconstituted.mobile, equals(original.mobile));
      expect(reconstituted.name, equals(original.name));
      expect(reconstituted.subjects.length, equals(3));
      expect(reconstituted.studentBadge, equals('CBSE • Grade 12'));
    });
  });

  group('Validation Tests', () {
    test('Email regex strictly validates genuine email patterns', () {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      
      expect(emailRegex.hasMatch('valid.student@domain.co.in'), isTrue);
      expect(emailRegex.hasMatch('aarav123@gmail.com'), isTrue);
      expect(emailRegex.hasMatch('invalid-email'), isFalse);
      expect(emailRegex.hasMatch('no_at_symbol.com'), isFalse);
      expect(emailRegex.hasMatch('@domain.com'), isFalse);
      expect(emailRegex.hasMatch('missing_tld@domain'), isFalse);
    });

    test('Mobile regex validates 10-digit Indian numbers starting with 6-9', () {
      final mobileRegex = RegExp(r'^[6-9]\d{9}$');

      expect(mobileRegex.hasMatch('9876543210'), isTrue);
      expect(mobileRegex.hasMatch('8123456789'), isTrue);
      expect(mobileRegex.hasMatch('7000123456'), isTrue);
      expect(mobileRegex.hasMatch('6398765432'), isTrue);
      
      // Invalid numbers
      expect(mobileRegex.hasMatch('1234567890'), isFalse); // Starts with 1
      expect(mobileRegex.hasMatch('987654321'), isFalse);  // 9 digits
      expect(mobileRegex.hasMatch('98765432100'), isFalse); // 11 digits
      expect(mobileRegex.hasMatch('abcdefghij'), isFalse); // letters
    });
  });

  group('App Configuration & Constants Tests', () {
    test('App name, free question limit, and size limits match requirements', () {
      expect(AppConstants.appName, equals('EduSync'));
      expect(AppConstants.dailyFreeQuestionLimit, equals(10));
      expect(AppConstants.maxUploadSizeBytes, equals(15 * 1024 * 1024));
    });

    test('School grades restricted strictly to Grades 9 to 12', () {
      expect(AppConstants.schoolGrades, equals(['Grade 9', 'Grade 10', 'Grade 11', 'Grade 12']));
    });

    test('School boards specifically support CBSE and Tamil Nadu State Board', () {
      expect(AppConstants.schoolBoards.contains('CBSE'), isTrue);
      expect(AppConstants.schoolBoards.contains('Tamil Nadu State Board'), isTrue);
    });

    test('Theme conforms to white background, navy text, indigo buttons', () {
      expect(EduTheme.background, equals(const Color(0xFFF8FAFC)));
      expect(EduTheme.textNavy, equals(const Color(0xFF0F172A)));
      expect(EduTheme.primaryIndigo, equals(const Color(0xFF4F46E5)));
      expect(EduTheme.highlightOrange, equals(const Color(0xFFF59E0B)));
    });
  });

  // =========================================================================
  // The 5 Mandatory Tutor & AI Study Verification Test Cases
  // =========================================================================

  group('EduSync AI Study Tutor - 5 Required Verification Test Cases', () {
    final aiService = AIService();

    // CASE 1: CBSE Grade 10 student asks "Explain photosynthesis"
    test('Case 1: CBSE Grade 10 student asks "Explain photosynthesis"', () async {
      final cbseStudent = StudentProfile(
        id: 'cbse_student_10',
        email: 'aarav.cbse@example.com',
        name: 'Aarav Sharma',
        isSchoolStudent: true,
        grade: 'Grade 10',
        board: 'CBSE',
        state: 'Tamil Nadu',
        medium: 'English',
        subjects: ['Science', 'Mathematics'],
        mainGoal: 'Prepare for exams',
      );

      final response = await aiService.askEduSync(
        question: 'Explain photosynthesis for CBSE Grade 10 in simple words.',
        profile: cbseStudent,
        conversationId: 'conv_cbse_10',
      );

      expect(response.isError, isFalse);
      expect(response.role, equals('assistant'));
      // Must contain chemical equation
      expect(response.content, contains('6CO₂ + 6H₂O'));
      expect(response.content, contains('C₆H₁₂O₆ + 6O₂'));
      // Must contain 3 sequential exam steps
      expect(response.content, contains('Absorption of light energy'));
      expect(response.content, contains('splitting of water molecules'));
      expect(response.content, contains('Reduction of carbon dioxide'));
      // Must contain raw materials
      expect(response.content.toLowerCase(), contains('stomata'));
      expect(response.content.toLowerCase(), contains('guard cells'));
      // Must contain practical/Indian context
      expect(response.content, contains('Starch Test'));
    });

    // CASE 1b: Tamil Nadu State Board Grade 10 student asks "Explain photosynthesis"
    test('Case 1b: Tamil Nadu State Board student asks "Explain photosynthesis"', () async {
      final tnStudent = StudentProfile(
        id: 'tn_student_10',
        email: 'selvi.tn@example.com',
        name: 'Selvi M',
        isSchoolStudent: true,
        grade: 'Grade 10',
        board: 'Tamil Nadu State Board',
        state: 'Tamil Nadu',
        medium: 'English',
        subjects: ['Science', 'Mathematics'],
        mainGoal: 'Prepare for exams',
      );

      final response = await aiService.askEduSync(
        question: 'Explain photosynthesis for Tamil Nadu State Board Grade 10.',
        profile: tnStudent,
        conversationId: 'conv_tn_10',
      );

      expect(response.isError, isFalse);
      expect(response.content, contains('Samacheer Kalvi'));
      expect(response.content, contains('Hill Reaction'));
      expect(response.content, contains('Calvin Cycle'));
      expect(response.content, contains('Thylakoid'));
      expect(response.content, contains('Stroma'));
    });

    // CASE 2: B.Tech CSE student asks "Explain waterfall model"
    test('Case 2: B.Tech CSE student asks "Explain waterfall model"', () async {
      final collegeStudent = StudentProfile(
        id: 'btech_cse_student',
        email: 'karthik.cse@example.com',
        name: 'Karthik Raja',
        isSchoolStudent: false,
        degree: 'B.Tech',
        department: 'Computer Science & Engg (CSE)',
        yearOrSem: 'Semester 4',
        medium: 'English',
        subjects: ['Software Engineering', 'DSA'],
        mainGoal: 'Exam preparation and placements',
      );

      final response = await aiService.askEduSync(
        question: 'Explain waterfall model for B.Tech CSE.',
        profile: collegeStudent,
        conversationId: 'conv_btech_cse',
      );

      expect(response.isError, isFalse);
      // Definition
      expect(response.content, contains('Winston W. Royce'));
      expect(response.content, contains('linear-sequential'));
      // 6 Phases
      expect(response.content, contains('Requirements Analysis'));
      expect(response.content, contains('System & Software Design'));
      expect(response.content, contains('Implementation'));
      expect(response.content, contains('Integration & System Testing'));
      expect(response.content, contains('Deployment'));
      expect(response.content, contains('Maintenance'));
      // Advantages and Limitations
      expect(response.content, contains('Advantages'));
      expect(response.content, contains('Limitations'));
      // Software engineering application example
      expect(response.content.contains('Banking Transaction Engine') || response.content.contains('Indian Railways'), isTrue);
    });

    // CASE 3: General question outside registered syllabus (e.g. "How does a microwave oven work?")
    test('Case 3: Student asks question outside syllabus ("How does a microwave oven work?")', () async {
      final student = StudentProfile(
        id: 'student_general',
        email: 'meera@example.com',
        name: 'Meera Nair',
        isSchoolStudent: true,
        grade: 'Grade 10',
        board: 'CBSE',
        state: 'Tamil Nadu',
        medium: 'English',
        subjects: ['Mathematics', 'Science'],
        mainGoal: 'Understand concepts',
      );

      final response = await aiService.askEduSync(
        question: 'How does a microwave oven work?',
        profile: student,
        conversationId: 'conv_microwave',
      );

      expect(response.isError, isFalse);
      // Does not claim official syllabus alignment
      expect(response.content, contains('No specific syllabus alignment'));
      // Explains magnetron and 2.45 GHz
      expect(response.content, contains('magnetron'));
      expect(response.content, contains('2.45 GHz'));
      // Explains dielectric heating of polar water molecules
      expect(response.content, contains('polar'));
      expect(response.content, contains('friction'));
    });

    // CASE 4: Follow-up: tap or ask "Give an example"
    test('Case 4: Follow-up question "Give an example" refers to previous conversation context', () async {
      final student = StudentProfile(
        id: 'student_followup',
        email: 'rohit@example.com',
        name: 'Rohit Kumar',
        isSchoolStudent: true,
        grade: 'Grade 10',
        board: 'CBSE',
        state: 'Tamil Nadu',
        medium: 'English',
        subjects: ['Science'],
        mainGoal: 'Prepare for exams',
      );

      // Previous message was about Photosynthesis
      final history = [
        ChatMessage(
          id: 'm1',
          conversationId: 'conv_followup',
          role: 'user',
          content: 'Explain photosynthesis for CBSE Grade 10.',
        ),
        ChatMessage(
          id: 'm2',
          conversationId: 'conv_followup',
          role: 'assistant',
          content: 'Photosynthesis is the autotrophic process where chlorophyll traps sunlight...',
        ),
      ];

      final followUpResponse = await aiService.askEduSync(
        question: 'Give an example',
        profile: student,
        conversationId: 'conv_followup',
        conversationHistory: history,
      );

      expect(followUpResponse.isError, isFalse);
      // Understood previous topic was photosynthesis
      expect(followUpResponse.content.contains('Variegated Leaf') || followUpResponse.content.contains('Croton') || followUpResponse.content.contains('Starch'), isTrue);
      expect(followUpResponse.content, contains('Iodine'));
    });

    // CASE 5: Network or API key failure shows error message & Retry button in chat bubble
    testWidgets('Case 5: Failure renders error card with Retry button in chat bubble', (WidgetTester tester) async {
      bool retryTapped = false;

      final errorMessage = ChatMessage(
        id: 'err_test',
        conversationId: 'conv_err',
        role: 'assistant',
        content: 'Failed to connect to AI study companion. Please check your internet connection or backend API key.',
        isError: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: errorMessage,
              onRetry: () {
                retryTapped = true;
              },
            ),
          ),
        ),
      );

      // Verify error notice heading is shown
      expect(find.text('EduSync Notice'), findsOneWidget);
      // Verify error explanation message is displayed
      expect(find.textContaining('Failed to connect to AI study companion'), findsOneWidget);
      // Verify Retry Question button exists
      expect(find.text('Retry Question'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Tap the retry button
      await tester.tap(find.text('Retry Question'));
      await tester.pump();

      expect(retryTapped, isTrue);
    });

    test('Case 5b: ChatProvider retryLastQuestion recovers successfully after failure', () async {
      SharedPreferences.setMockInitialValues({});
      final chatProvider = ChatProvider();
      final student = StudentProfile(
        id: 'retry_student',
        email: 'retry@example.com',
        name: 'Retry Student',
        isSchoolStudent: true,
        grade: 'Grade 10',
        board: 'CBSE',
        state: 'Tamil Nadu',
        medium: 'English',
        subjects: ['Science'],
        mainGoal: 'Prepare for exams',
      );

      // 1. Simulate failure on initial attempt
      aiService.simulateFailure = true;
      await chatProvider.sendMessage(text: 'Explain photosynthesis for CBSE Grade 10', profile: student);

      // Verify that the message in list is an error message
      expect(chatProvider.messages.isNotEmpty, isTrue);
      expect(chatProvider.messages.last.isError, isTrue);
      expect(chatProvider.lastFailedQuestion, equals('Explain photosynthesis for CBSE Grade 10'));

      // 2. Clear failure simulation and trigger retry
      aiService.simulateFailure = false;
      final retrySuccess = await chatProvider.retryLastQuestion(student);

      expect(retrySuccess, isTrue);
      expect(chatProvider.messages.last.isError, isFalse);
      expect(chatProvider.messages.last.content, contains('6CO₂ + 6H₂O'));
    });
  });

  group('Widget Tests', () {
    testWidgets('QuotaPill displays remaining free questions correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuotaPill(remaining: 8, total: 10),
          ),
        ),
      );

      expect(find.text('8 / 10 free questions today'), findsOneWidget);
    });

    testWidgets('StudyStatCard renders values and icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyStatCard(
              title: 'Study Streak',
              value: '5 Days',
              subtitle: 'Keep it going!',
              icon: Icons.bolt,
              iconColor: Colors.orange,
              iconBackgroundColor: Colors.orangeAccent,
            ),
          ),
        ),
      );

      expect(find.text('Study Streak'), findsOneWidget);
      expect(find.text('5 Days'), findsOneWidget);
      expect(find.text('Keep it going!'), findsOneWidget);
    });
  });
}
