import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/chat_message.dart';
import 'feedback_card.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    this.onReplayTap,
    super.key,
  });

  final ChatMessage message;
  final VoidCallback? onReplayTap;

  static const _fillers = [' um ', ' uh ', 'umm', 'uhh'];

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 328),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppColors.bubbleUser : AppColors.bubbleAi,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.stroke),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120B3743),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isTyping)
              const _TypingIndicator()
            else if (isUser)
              _buildUserText(context, message.text)
            else
              Text(
                message.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
              ),
            if (message.correction != null) ...[
              const SizedBox(height: 12),
              Text(
                message.correction!.original,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8EA0AA),
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message.correction!.improved,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
            if (message.continuationQuestion != null) ...[
              const SizedBox(height: 8),
              Text(
                message.continuationQuestion!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (message.correction?.tip != null) ...[
              const SizedBox(height: 10),
              FeedbackCard(tip: message.correction!.tip!),
            ],
            if (message.timestamp != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _formatTime(message.timestamp!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (!isUser && !message.isTyping)
                    InkWell(
                      onTap: onReplayTap,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 17,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserText(BuildContext context, String text) {
    final spans = <TextSpan>[];
    final cleanText = ' ${text.toLowerCase()} ';
    var cursor = 0;

    while (cursor < text.length) {
      var nextStart = text.length;
      var nextEnd = text.length;

      for (final filler in _fillers) {
        final index = cleanText.indexOf(filler, cursor);
        if (index != -1 && index < nextStart) {
          nextStart = index;
          nextEnd = (index + filler.length).clamp(0, text.length);
        }
      }

      if (nextStart >= text.length) {
        spans.add(TextSpan(text: text.substring(cursor)));
        break;
      }

      if (nextStart > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, nextStart)));
      }

      spans.add(
        TextSpan(
          text: text.substring(nextStart, nextEnd).trim(),
          style: const TextStyle(
            color: AppColors.warning,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

      if (nextEnd < text.length) {
        spans.add(const TextSpan(text: ' '));
      }
      cursor = nextEnd;
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge,
        children: spans,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final h = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final m = dateTime.minute.toString().padLeft(2, '0');
    final ap = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          children: List.generate(3, (index) {
            final v = ((_controller.value + index * 0.2) % 1);
            final opacity = 0.3 + (0.7 * (1 - (v - 0.5).abs() * 2));
            return Container(
              width: 7,
              height: 7,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
