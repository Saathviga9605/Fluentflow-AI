import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum AppButtonStyle { primary, secondary }

class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final AppButtonStyle style;
  final bool enabled;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.style == AppButtonStyle.primary;
    final background = isPrimary ? AppColors.primary : AppColors.secondary;
    final foreground = isPrimary ? Colors.white : AppColors.textPrimary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.985 : 1,
        child: SizedBox(
          width: double.infinity,
          child: widget.icon == null
              ? ElevatedButton(
                  onPressed: widget.enabled ? widget.onPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.enabled ? background : AppColors.disabled,
                    foregroundColor: widget.enabled ? foreground : Colors.white,
                    shadowColor:
                        isPrimary ? const Color(0x3330A6B8) : Colors.transparent,
                    elevation: isPrimary ? 10 : 0,
                  ),
                  child: Text(widget.label),
                )
              : ElevatedButton.icon(
                  onPressed: widget.enabled ? widget.onPressed : null,
                  icon: Icon(widget.icon, size: 20),
                  label: Text(widget.label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.enabled ? background : AppColors.disabled,
                    foregroundColor: widget.enabled ? foreground : Colors.white,
                    shadowColor:
                        isPrimary ? const Color(0x3330A6B8) : Colors.transparent,
                    elevation: isPrimary ? 10 : 0,
                  ),
                ),
        ),
      ),
    );
  }
}
