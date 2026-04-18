import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF198FA3);
  static const Color secondary = Color(0xFFEAF3F6);
  static const Color accent = Color(0xFF35B39B);
  static const Color background = Color(0xFFF5FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF122530);
  static const Color textSecondary = Color(0xFF5F7583);
  static const Color stroke = Color(0xFFE1ECF1);
  static const Color success = Color(0xFF43A36C);
  static const Color successSoft = Color(0xFFDBF1E4);
  static const Color warningSoft = Color(0xFFFBE5E5);
  static const Color warning = Color(0xFFD86A6A);
  static const Color bubbleUser = Color(0xFFD8F0F4);
  static const Color bubbleAi = Color(0xFFFFFFFF);
  static const Color disabled = Color(0xFFB6C6CF);

  static const LinearGradient calmGradient = LinearGradient(
    colors: [Color(0xFFDDF3F8), Color(0xFFEAF8F4), Color(0xFFF5FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ctaGradient = LinearGradient(
    colors: [Color(0xFF26A3B7), Color(0xFF198FA3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
