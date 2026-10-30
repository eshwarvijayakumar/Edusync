import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'auth/login_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'navigation/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkRouting();
  }

  Future<void> _checkRouting() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    if (auth.isAuthenticated && auth.userId != null) {
      await profile.fetchProfile(auth.userId!);
      if (!mounted) return;

      if (profile.hasProfile) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: EduTheme.primaryIndigo,
                borderRadius: BorderRadius.circular(24),
                boxShadow: EduTheme.buttonShadow,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 46,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: EduTheme.textNavy,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              AppConstants.appTagline,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: EduTheme.textMuted,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(EduTheme.primaryIndigo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
