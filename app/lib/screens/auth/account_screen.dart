import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/auth_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const List<String> _emojiAvatars = <String>[
    '🗣️',
    '🎧',
    '📚',
    '🚀',
    '💬',
    '🌟',
    '🎯',
    '🧠',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: const Center(child: Text('No active account found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.avatarEmoji,
                          style: const TextStyle(fontSize: 34),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your avatar',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _emojiAvatars
                          .map(
                            (emoji) => InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => context.read<AuthProvider>().updateAvatarEmoji(emoji),
                              child: Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: user.avatarEmoji == emoji
                                      ? AppColors.secondary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: user.avatarEmoji == emoji
                                        ? AppColors.primary
                                        : AppColors.stroke,
                                  ),
                                ),
                                child: Text(emoji, style: const TextStyle(fontSize: 22)),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  children: [
                    _StatRow(label: 'Average Fluency', value: user.averageFluencyScore.toStringAsFixed(1)),
                    const SizedBox(height: 8),
                    _StatRow(label: 'Total Sessions', value: '${user.totalSessions}'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: child,
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
