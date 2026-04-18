import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120A3340),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
