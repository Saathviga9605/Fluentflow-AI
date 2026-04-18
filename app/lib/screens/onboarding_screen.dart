import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _slides = [
    _SlideData(
      title: 'Speak naturally without hesitation',
      subtitle: 'Practice in a calm, judgment-free conversation space.',
      icon: Icons.forum_rounded,
    ),
    _SlideData(
      title: 'Get gentle corrections while you talk',
      subtitle: 'Learn in-context without losing conversational flow.',
      icon: Icons.waving_hand_rounded,
    ),
    _SlideData(
      title: 'Build confidence through real conversations',
      subtitle: 'Small daily talks that make speaking feel effortless.',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index == _slides.length - 1) {
      await context.read<AuthProvider>().markOnboardingSeen();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await context.read<AuthProvider>().markOnboardingSeen();
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
                    },
                    child: const Text('Skip'),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => _SlideCard(data: _slides[i]),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.primary : AppColors.stroke,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AppButton(
                  label: _index == _slides.length - 1 ? 'Start Now' : 'Next',
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.data});

  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(data.title),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: BorderRadius.circular(36),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3326A3B6),
                  blurRadius: 26,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Icon(data.icon, color: Colors.white, size: 58),
          ),
          const SizedBox(height: 28),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
