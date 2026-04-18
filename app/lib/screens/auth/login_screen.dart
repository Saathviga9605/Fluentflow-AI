import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input_field.dart';
import '../../widgets/premium_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _emailError = _email.text.contains('@') ? null : 'Enter a valid email';
      _passwordError = _password.text.length >= 6 ? null : 'Minimum 6 characters';
    });
    if (_emailError == null && _passwordError == null) {
      await context.read<AuthProvider>().signInWithEmailFallback(
            name: 'FluentFlow Learner',
            email: _email.text.trim(),
          );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    }
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ?? 'Google Sign-In failed. Please check Firebase setup.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Continue your conversation journey.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              PremiumCard(
                child: Column(
                  children: [
                    AppInputField(
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      controller: _email,
                      errorText: _emailError,
                      prefixIcon: Icons.mail_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    AppInputField(
                      label: 'Password',
                      hint: 'Enter your password',
                      obscureText: true,
                      controller: _password,
                      errorText: _passwordError,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: auth.isBusy ? 'Signing in...' : 'Login',
                      onPressed: _submit,
                      enabled: !auth.isBusy,
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Continue with Google',
                      style: AppButtonStyle.secondary,
                      icon: Icons.g_mobiledata_rounded,
                      onPressed: _googleSignIn,
                      enabled: !auth.isBusy,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
                child: const Text('No account yet? Create one'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
