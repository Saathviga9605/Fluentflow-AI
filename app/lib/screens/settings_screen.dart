import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SettingCard(
                title: 'Language support',
                child: DropdownButtonFormField<String>(
                  initialValue: settings.language,
                  decoration: _decoration(),
                  borderRadius: BorderRadius.circular(16),
                  items: const [
                    DropdownMenuItem(
                      value: 'Tamil + English',
                      child: Text('Tamil + English'),
                    ),
                    DropdownMenuItem(
                      value: 'English only',
                      child: Text('English only'),
                    ),
                  ],
                  onChanged: (v) =>
                      settings.updateLanguage(v ?? settings.language),
                ),
              ),
              _SettingCard(
                title: 'Speech speed',
                subtitle: settings.speechSpeed.toStringAsFixed(1),
                child: Slider(
                  value: settings.speechSpeed,
                  min: 0.7,
                  max: 1.3,
                  divisions: 6,
                  label: settings.speechSpeed.toStringAsFixed(1),
                  onChanged: settings.updateSpeechSpeed,
                ),
              ),
              _SettingCard(
                title: 'AI Voice',
                subtitle: 'Choose your preferred playback voice',
                child: DropdownButtonFormField<String>(
                  initialValue: settings.voiceProfile,
                  decoration: _decoration(),
                  borderRadius: BorderRadius.circular(16),
                  items: const [
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                  ],
                  onChanged: (v) =>
                      settings.updateVoiceProfile(v ?? settings.voiceProfile),
                ),
              ),
              _SettingCard(
                title: 'Auto voice replies',
                subtitle: 'Play assistant responses automatically',
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: settings.autoSpeakReplies,
                  onChanged: settings.updateAutoSpeakReplies,
                  title: const Text('Speak every AI reply'),
                ),
              ),
              _SettingCard(
                title: 'Difficulty level',
                subtitle: settings.difficultyLabel(settings.difficulty),
                child: Slider(
                  value: settings.difficulty,
                  min: 0,
                  max: 1,
                  divisions: 4,
                  onChanged: settings.updateDifficulty,
                ),
              ),
              _SettingCard(
                title: 'Safe Mode',
                subtitle: 'Extra gentle corrections and supportive tone',
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: settings.safeMode,
                  onChanged: settings.updateSafeMode,
                  title: const Text('Enable Safe Mode'),
                ),
              ),
              _SettingCard(
                title: 'Account',
                subtitle: 'Manage your profile and avatar',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.account),
                    icon: const Icon(Icons.person_outline_rounded),
                    label: const Text('Open account'),
                  ),
                ),
              ),
              const SizedBox(height: 6),
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
                label: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
          if (index == 1) {
            Navigator.pushReplacementNamed(context, AppRoutes.progress);
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

  InputDecoration _decoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF4F8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
