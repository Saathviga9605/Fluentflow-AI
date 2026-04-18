import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: AppColors.ctaGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.record_voice_over_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  'FluentFlow AI',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your friendly conversation partner for smoother, more confident English.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                AppButton(
                  label: 'Get Started',
                  icon: Icons.rocket_launch_rounded,
                  onPressed: () async {
                    await context.read<AuthProvider>().markOnboardingSeen();
                    if (!context.mounted) return;
                    Navigator.pushNamed(context, AppRoutes.signup);
                  },
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Login',
                  style: AppButtonStyle.secondary,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
