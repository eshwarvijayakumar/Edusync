import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/custom_button.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_use_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EduTheme.radiusLarge)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out from EduSync?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: EduTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: EduTheme.primaryIndigo),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _handleDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EduTheme.radiusLarge)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: EduTheme.errorRed),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'This will permanently delete your account, saved chats, notes, and progress. This action cannot be undone.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: EduTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: EduTheme.errorRed),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Provider.of<AuthProvider>(context, listen: false).deleteAccount();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;

    final name = profile?.name ?? 'Student';
    final email = profile?.email ?? 'student@example.com';
    final mobile = profile?.mobile ?? 'Not specified';
    final badge = profile?.studentBadge ?? 'Learner';
    final goal = profile?.mainGoal ?? 'Understand concepts';
    final medium = profile?.preferredLanguage ?? 'English';

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: const Text('Student Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            // User Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: EduTheme.surface,
                borderRadius: BorderRadius.circular(EduTheme.radiusLarge),
                border: Border.all(color: EduTheme.borderSubtle),
                boxShadow: EduTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: EduTheme.primaryIndigoLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: EduTheme.primaryIndigo,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 13, color: EduTheme.textLight),
                  ),
                  if (mobile.isNotEmpty && mobile != 'Not specified') ...[
                    const SizedBox(height: 2),
                    Text(
                      '📱 +91 $mobile',
                      style: const TextStyle(fontSize: 12, color: EduTheme.textLight, fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: EduTheme.primaryIndigoLight,
                      borderRadius: BorderRadius.circular(EduTheme.radiusFull),
                    ),
                    child: Text(
                      badge,
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
            const SizedBox(height: 20),

            // Academic Profile Details Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: EduTheme.surface,
                borderRadius: BorderRadius.circular(EduTheme.radiusLarge),
                border: Border.all(color: EduTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Academic Details',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EduTheme.textNavy),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 16, color: EduTheme.primaryIndigo),
                        label: const Text('Edit', style: TextStyle(color: EduTheme.primaryIndigo, fontWeight: FontWeight.w600)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OnboardingScreen(
                                prefilledName: profile?.name,
                                prefilledEmail: profile?.email,
                                prefilledMobile: profile?.mobile,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 6),
                  _buildProfileRow('Category', profile?.isSchoolStudent == true ? 'School Student' : 'College Student'),
                  if (profile?.isSchoolStudent == true) ...[
                    _buildProfileRow('Grade', profile?.grade ?? '-'),
                    _buildProfileRow('Board', profile?.board ?? '-'),
                    _buildProfileRow('State', profile?.state ?? '-'),
                    if (profile?.schoolName?.isNotEmpty == true)
                      _buildProfileRow('School', profile!.schoolName!),
                  ] else ...[
                    _buildProfileRow('Degree', profile?.degree ?? '-'),
                    _buildProfileRow('Department', profile?.department ?? '-'),
                    _buildProfileRow('Semester', profile?.yearOrSem ?? '-'),
                    if (profile?.collegeName?.isNotEmpty == true)
                      _buildProfileRow('College', profile!.collegeName!),
                  ],
                  _buildProfileRow('Medium', medium),
                  _buildProfileRow('Main Goal', goal),
                  const SizedBox(height: 6),
                  const Text('Subjects:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EduTheme.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (profile?.subjects ?? []).map((sub) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: EduTheme.background,
                          borderRadius: BorderRadius.circular(EduTheme.radiusSmall),
                          border: Border.all(color: EduTheme.borderSubtle),
                        ),
                        child: Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduTheme.textNavy)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings & Legal List
            Container(
              decoration: BoxDecoration(
                color: EduTheme.surface,
                borderRadius: BorderRadius.circular(EduTheme.radiusLarge),
                border: Border.all(color: EduTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: EduTheme.textNavy),
                    title: const Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: EduTheme.textLight),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: EduTheme.textNavy),
                    title: const Text('Terms of Use', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: EduTheme.textLight),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsOfUseScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent_rounded, color: EduTheme.textNavy),
                    title: const Text('Support & Feedback', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: EduTheme.textLight),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contact EduSync Support at: support@edusync.app'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            CustomButton(
              text: 'Sign Out',
              isOutlined: true,
              icon: Icons.logout_rounded,
              onPressed: () => _handleSignOut(context),
            ),
            const SizedBox(height: 12),

            // Delete Account Button
            TextButton.icon(
              icon: const Icon(Icons.delete_forever_rounded, color: EduTheme.errorRed, size: 18),
              label: const Text(
                'Delete Account Option',
                style: TextStyle(color: EduTheme.errorRed, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              onPressed: () => _handleDeleteAccount(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: EduTheme.textMuted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EduTheme.textNavy)),
        ],
      ),
    );
  }
}
