import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../services/dummy_data_service.dart';
import '../widgets/fluency_chart.dart';
import '../widgets/premium_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final snapshots = auth.fluencySnapshots;
    final trend = snapshots.isEmpty
        ? DummyDataService.fluencyTrend()
        : snapshots
            .map((item) => (item['score'] as num?)?.toDouble() ?? 0)
            .toList();
    final corrections = DummyDataService.commonCorrections();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: SafeArea(
          child: trend.isEmpty
              ? const _ProgressEmptyState()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fluency score trend',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          FluencyChart(points: trend),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _MiniStats(
                      totalSessions: auth.user?.totalSessions ?? snapshots.length,
                      averageScore: auth.user?.averageFluencyScore ??
                          (trend.isEmpty
                              ? 0
                              : trend.reduce((a, b) => a + b) / trend.length),
                    ),
                    const SizedBox(height: 14),
                    PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Common corrections',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 10),
                          ...corrections.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
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

class _MiniStats extends StatelessWidget {
  const _MiniStats({required this.totalSessions, required this.averageScore});

  final int totalSessions;
  final double averageScore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SmallCard(
            title: 'Avg. Fluency',
            value: averageScore.toStringAsFixed(1),
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SmallCard(
            title: 'Sessions',
            value: '$totalSessions',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ProgressEmptyState extends StatelessWidget {
  const _ProgressEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 14),
            Text('No progress data yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Start talking daily and your trends will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
