import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../models/conversation_mode.dart';
import '../models/progress_metric.dart';
import '../providers/auth_provider.dart';
import '../services/dummy_data_service.dart';
import '../widgets/app_button.dart';
import '../widgets/mode_card.dart';
import '../widgets/premium_card.dart';
import '../widgets/stat_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final List<ConversationMode> modes = DummyDataService.modes();
    final List<ProgressMetric> stats = DummyDataService.quickStats();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              Text(_greeting(), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                auth.user == null
                    ? 'Let\'s have a conversation'
                    : '${auth.user!.name} • ${auth.user!.email}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              if (auth.user != null) ...[
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.account),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        backgroundImage: auth.user!.photoUrl != null
                            ? NetworkImage(auth.user!.photoUrl!)
                            : null,
                        child: auth.user!.photoUrl == null
                            ? Text(auth.user!.avatarEmoji)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'View account',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready when you are',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a natural conversation and receive subtle guidance in context.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'Start Talking',
                      icon: Icons.mic_rounded,
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.conversation),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Conversation modes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SizedBox(
                height: 152,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: modes.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (_, index) => ModeCard(
                    mode: modes[index],
                    onTap: () => Navigator.pushNamed(context, AppRoutes.conversation),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quick stats', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.progress),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const Divider(height: 8),
              const SizedBox(height: 12),
              SizedBox(
                height: 142,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stats.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (_, index) => StatWidget(
                    title: stats[index].title,
                    value: stats[index].value,
                    subtitle: stats[index].subtitle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(context, AppRoutes.progress);
          }
          if (index == 2) {
            Navigator.pushReplacementNamed(context, AppRoutes.settings);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            selectedIcon: Icon(Icons.show_chart_rounded),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
