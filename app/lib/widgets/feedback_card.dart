import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    required this.tip,
    super.key,
  });

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Fluency Tip: $tip',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
