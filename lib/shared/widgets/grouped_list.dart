import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';

/// Row in a grouped list with a small cover/icon, label, count and chevron.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.count,
    this.value,
    this.showDivider = true,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final int? count;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: [
        label,
        if (count != null) Formatters.plural(count!, 'item'),
        ?value,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: c.divider, width: 0.6))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: c.textPrimary, size: IconSizes.md),
              const SizedBox(width: Insets.md),
              Expanded(child: Text(label, style: context.text.bodyLarge)),
              const SizedBox(width: Insets.sm),
              if (count != null || value != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                  ),
                  child: Text(
                    value ?? Formatters.count(count!),
                    textAlign: TextAlign.end,
                    style: context.text.bodyMedium?.copyWith(
                      color: valueColor ?? c.textTertiary,
                    ),
                  ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: Insets.xs),
                Icon(Icons.chevron_right_rounded, color: c.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded card that groups [CollectionRow]s.
class GroupedCard extends StatelessWidget {
  const GroupedCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.divider, width: 0.6),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: children),
      ),
    );
  }
}
