import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import 'buttons.dart';

/// Centered illustration + copy + optional action. Used for empty, error and
/// no-results states so they all look like they belong together.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.compact = false,
  });

  factory MessageView.error({
    Key? key,
    required VoidCallback onRetry,
    String message = 'Something went wrong while reading your library.',
  }) => MessageView(
    key: key,
    icon: Icons.cloud_off_rounded,
    title: "Couldn't load",
    message: message,
    actionLabel: 'Try again',
    onAction: onRetry,
  );

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Insets.xxxl,
          vertical: compact ? Insets.xxl : Insets.huge,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: c.textSecondary),
              ),
              const SizedBox(height: Insets.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.text.titleLarge,
              ),
              const SizedBox(height: Insets.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: c.textSecondary,
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: Insets.xxl),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  expand: false,
                ),
              ],
              if (secondaryLabel != null) ...[
                const SizedBox(height: Insets.sm),
                AppTextButton(label: secondaryLabel!, onPressed: onSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
