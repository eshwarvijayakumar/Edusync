import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../constants/app_constants.dart';
import '../../models/student_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../navigation/main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String? prefilledName;
  final String? prefilledEmail;
  final String? prefilledMobile;

  const OnboardingScreen({
    super.key,
    this.prefilledName,
    this.prefilledEmail,
    this.prefilledMobile,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0: Select Role, 1: Fill Details

  // Student Type
  bool _isSchoolStudent = true;

  // Controllers
  late TextEditingController _nameController;
  final _institutionController = TextEditingController();
  final _customSubjectController = TextEditingController();

  // School Selection States (Supporting Grades 9-12, CBSE and Tamil Nadu State Board)
  String _selectedGrade = AppConstants.schoolGrades[1]; // Grade 10 default
  String _selectedBoard = AppConstants.schoolBoards[0]; // CBSE
  String _selectedState = AppConstants.indianStates[0]; // Tamil Nadu default
  String _selectedMedium = AppConstants.mediums[0]; // English
  String _selectedSchoolGoal = AppConstants.schoolGoals[0]; // Understand concepts
  final List<String> _selectedSubjects = ['Mathematics', 'Science', 'English'];

  // College Selection States
  String _selectedDegree = AppConstants.collegeDegrees[0]; // B.Tech
  String _selectedDepartment = AppConstants.collegeDepartments[0]; // CSE
  String _selectedSemester = AppConstants.collegeSemesters[2]; // Sem 3
  String _selectedCollegeGoal = AppConstants.collegeGoals[0]; // Exam prep

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefilledName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _customSubjectController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name'),
          backgroundColor: EduTheme.errorRed,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    final userId = auth.userId ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final userEmail = auth.userEmail ?? widget.prefilledEmail ?? '';
    final userMobile = widget.prefilledMobile;

    final profile = StudentProfile(
      id: userId,
      email: userEmail,
      mobile: userMobile,
      name: _nameController.text.trim(),
      isSchoolStudent: _isSchoolStudent,
      grade: _isSchoolStudent ? _selectedGrade : null,
      board: _isSchoolStudent ? _selectedBoard : null,
      state: _isSchoolStudent ? _selectedState : null,
      medium: _selectedMedium,
      schoolName: _isSchoolStudent ? _institutionController.text.trim() : null,
      degree: !_isSchoolStudent ? _selectedDegree : null,
      collegeName: !_isSchoolStudent ? _institutionController.text.trim() : null,
      department: !_isSchoolStudent ? _selectedDepartment : null,
      yearOrSem: !_isSchoolStudent ? _selectedSemester : null,
      subjects: _selectedSubjects,
      mainGoal: _isSchoolStudent ? _selectedSchoolGoal : _selectedCollegeGoal,
    );

    final success = await profileProvider.saveProfile(profile);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.errorMessage ?? 'Failed to save profile. Please try again.'),
          backgroundColor: EduTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: Text(_step == 0 ? 'Getting Started' : 'Personalise Your Learning'),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _step = 0),
              )
            : null,
      ),
      body: SafeArea(
        child: _step == 0 ? _buildRoleSelectionStep() : _buildProfileFormStep(),
      ),
    );
  }

  Widget _buildRoleSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are you studying?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: EduTheme.textNavy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'EduSync personalises every explanation, quiz, and study plan to your curriculum.',
            style: TextStyle(
              fontSize: 14,
              color: EduTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 36),

          // Option 1: School Student
          _buildRoleCard(
            title: 'School Student',
            subtitle: 'Grades 9–12 (CBSE, Tamil Nadu State Board)',
            icon: Icons.backpack_rounded,
            isSelected: _isSchoolStudent,
            onTap: () {
              setState(() {
                _isSchoolStudent = true;
                _selectedSubjects.clear();
                _selectedSubjects.addAll(['Mathematics', 'Science', 'English']);
              });
            },
          ),
          const SizedBox(height: 16),

          // Option 2: College Student
          _buildRoleCard(
            title: 'College Student',
            subtitle: 'B.Tech, B.Sc, B.Com, BA, MBBS, BBA, Law & more',
            icon: Icons.account_balance_rounded,
            isSelected: !_isSchoolStudent,
            onTap: () {
              setState(() {
                _isSchoolStudent = false;
                _selectedSubjects.clear();
                _selectedSubjects.addAll(['Data Structures', 'Operating Systems', 'DBMS']);
              });
            },
          ),

          const Spacer(),

          CustomButton(
            text: 'Continue',
            onPressed: () => setState(() => _step = 1),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: EduTheme.surface,
          borderRadius: BorderRadius.circular(EduTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? EduTheme.primaryIndigo : EduTheme.borderSubtle,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected ? EduTheme.buttonShadow : EduTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? EduTheme.primaryIndigoLight : EduTheme.background,
                borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
              ),
              child: Icon(
                icon,
                color: isSelected ? EduTheme.primaryIndigo : EduTheme.textMuted,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? EduTheme.primaryIndigo : EduTheme.textNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: EduTheme.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: EduTheme.primaryIndigo,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileFormStep() {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Your Full Name',
            hint: 'What should EduSync call you?',
            prefixIcon: Icons.badge_outlined,
          ),
          const SizedBox(height: 20),

          if (_isSchoolStudent) ...[
            // Grade
            _buildDropdown(
              label: 'Grade / Class',
              value: _selectedGrade,
              items: AppConstants.schoolGrades,
              onChanged: (val) => setState(() => _selectedGrade = val!),
            ),
            const SizedBox(height: 20),

            // Board (CBSE & Tamil Nadu State Board)
            _buildDropdown(
              label: 'Educational Board',
              value: _selectedBoard,
              items: AppConstants.schoolBoards,
              onChanged: (val) {
                setState(() {
                  _selectedBoard = val!;
                  if (val == 'Tamil Nadu State Board') {
                    _selectedState = 'Tamil Nadu';
                  }
                });
              },
            ),
            const SizedBox(height: 20),

            // State
            _buildDropdown(
              label: 'State / UT',
              value: _selectedState,
              items: AppConstants.indianStates,
              onChanged: (val) => setState(() => _selectedState = val!),
            ),
            const SizedBox(height: 20),

            // Medium
            _buildDropdown(
              label: 'Preferred Medium of Instruction',
              value: _selectedMedium,
              items: AppConstants.mediums,
              onChanged: (val) => setState(() => _selectedMedium = val!),
            ),
            const SizedBox(height: 20),

            // School Name
            CustomTextField(
              controller: _institutionController,
              label: 'School Name (Optional)',
              hint: 'e.g. Kendriya Vidyalaya, Delhi Public School',
              prefixIcon: Icons.apartment_rounded,
            ),
            const SizedBox(height: 20),

            // Goal
            _buildDropdown(
              label: 'Main Learning Goal',
              value: _selectedSchoolGoal,
              items: AppConstants.schoolGoals,
              onChanged: (val) => setState(() => _selectedSchoolGoal = val!),
            ),
          ] else ...[
            // College Degree
            _buildDropdown(
              label: 'Degree Programme',
              value: _selectedDegree,
              items: AppConstants.collegeDegrees,
              onChanged: (val) => setState(() => _selectedDegree = val!),
            ),
            const SizedBox(height: 20),

            // Department
            _buildDropdown(
              label: 'Department / Branch',
              value: _selectedDepartment,
              items: AppConstants.collegeDepartments,
              onChanged: (val) => setState(() => _selectedDepartment = val!),
            ),
            const SizedBox(height: 20),

            // Semester
            _buildDropdown(
              label: 'Year or Semester',
              value: _selectedSemester,
              items: AppConstants.collegeSemesters,
              onChanged: (val) => setState(() => _selectedSemester = val!),
            ),
            const SizedBox(height: 20),

            // Medium
            _buildDropdown(
              label: 'Preferred Explanation Language',
              value: _selectedMedium,
              items: AppConstants.mediums,
              onChanged: (val) => setState(() => _selectedMedium = val!),
            ),
            const SizedBox(height: 20),

            // College Name
            CustomTextField(
              controller: _institutionController,
              label: 'College / University (Optional)',
              hint: 'e.g. IIT Madras, Anna University, Delhi University',
              prefixIcon: Icons.account_balance_rounded,
            ),
            const SizedBox(height: 20),

            // College Goal
            _buildDropdown(
              label: 'Primary Academic Goal',
              value: _selectedCollegeGoal,
              items: AppConstants.collegeGoals,
              onChanged: (val) => setState(() => _selectedCollegeGoal = val!),
            ),
          ],

          const SizedBox(height: 20),

          // Subjects Section
          const Text(
            'Your Subjects',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EduTheme.textNavy),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSubjects.map((subject) {
              return Chip(
                label: Text(subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                backgroundColor: EduTheme.primaryIndigoLight,
                deleteIconColor: EduTheme.primaryIndigo,
                onDeleted: () {
                  if (_selectedSubjects.length > 1) {
                    setState(() => _selectedSubjects.remove(subject));
                  }
                },
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EduTheme.radiusFull)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customSubjectController,
                  decoration: const InputDecoration(
                    hintText: 'Add another subject...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final text = _customSubjectController.text.trim();
                  if (text.isNotEmpty && !_selectedSubjects.contains(text)) {
                    setState(() {
                      _selectedSubjects.add(text);
                      _customSubjectController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Add'),
              ),
            ],
          ),

          const SizedBox(height: 36),

          CustomButton(
            text: 'Save Profile & Start Learning',
            isLoading: profileProvider.isLoading,
            onPressed: _completeOnboarding,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: EduTheme.textNavy,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: EduTheme.surface,
            borderRadius: BorderRadius.circular(EduTheme.radiusMedium),
            border: Border.all(color: EduTheme.borderSubtle, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: EduTheme.textNavy),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14.5, color: EduTheme.textNavy, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
