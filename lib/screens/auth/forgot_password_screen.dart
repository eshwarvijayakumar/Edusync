import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your registered email address';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.resetPassword(_emailController.text.trim());

    if (mounted) {
      if (success) {
        setState(() {
          _sent = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Unable to send reset email. Please try again.'),
            backgroundColor: EduTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: _sent
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: EduTheme.primaryIndigoLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          size: 48,
                          color: EduTheme.primaryIndigo,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Check Your Email',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: EduTheme.textNavy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We have sent password recovery instructions to ${_emailController.text.trim()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: EduTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Back to Sign In',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Forgot your password?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: EduTheme.textNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter the email associated with your EduSync account and we will send you a reset link.',
                        style: TextStyle(
                          fontSize: 14,
                          color: EduTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Registered Email',
                        hint: 'name@domain.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        text: 'Send Reset Link',
                        isLoading: auth.isLoading,
                        onPressed: _handleReset,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
