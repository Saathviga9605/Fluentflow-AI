import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input_field.dart';
import '../../widgets/premium_card.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _focus = 'Fluency';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Text('Create your profile',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Set up your space for relaxed, real-time speaking practice.',
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
                      label: 'Name',
                      hint: 'Your name',
                      controller: _name,
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    AppInputField(
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      controller: _email,
                      prefixIcon: Icons.mail_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    AppInputField(
                      label: 'Password',
                      hint: 'Create a strong password',
                      obscureText: true,
                      controller: _password,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'What do you want to improve?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Fluency', 'Confidence', 'Vocabulary']
                          .map(
                            (item) => ChoiceChip(
                              selected: _focus == item,
                              label: Text(item),
                              onSelected: (_) => setState(() => _focus = item),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Create Account',
                      onPressed: () async {
                        await context.read<AuthProvider>().signInWithEmailFallback(
                              name: _name.text.trim(),
                              email: _email.text.trim().isEmpty
                                  ? 'learner@local.dev'
                                  : _email.text.trim(),
                            );
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.home,
                          (_) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
