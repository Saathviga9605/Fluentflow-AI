import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SuggestionPanel extends StatelessWidget {
  const SuggestionPanel({
    required this.words,
    required this.synonyms,
    required this.completions,
    super.key,
  });

  final List<String> words;
  final List<String> synonyms;
  final List<String> completions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD3DEE3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Need help with words?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            _Section(title: 'Suggested words', items: words),
            const SizedBox(height: 14),
            _Section(title: 'Synonyms', items: synonyms),
            const SizedBox(height: 14),
            _Section(title: 'Sentence completions', items: completions),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              item,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
