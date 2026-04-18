import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class MicButton extends StatefulWidget {
  const MicButton({
    required this.isRecording,
    required this.onTap,
    super.key,
  });

  final bool isRecording;
  final VoidCallback onTap;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isRecording) {
      _controller.stop();
      _controller.value = 0;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = widget.isRecording ? (1 + (_controller.value * 0.08)) : 1.0;
          return Transform.scale(
            scale: pulse,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.isRecording
                      ? const [Color(0xFFE35D6A), Color(0xFFC53D4C)]
                      : const [AppColors.secondary, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isRecording
                            ? const Color(0xFFC53D4C)
                            : AppColors.primary)
                        .withValues(alpha: 0.34),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 34),
            ),
          );
        },
      ),
    );
  }
}
