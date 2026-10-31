import 'package:flutter/material.dart';
import 'package:warsha_app/core/theme/app_theme.dart';
import 'package:warsha_app/core/widgets/app_card.dart';
import 'package:warsha_app/core/widgets/app_text.dart';
import 'package:warsha_app/core/widgets/status_pill.dart';

/// A KPI tile: icon, label, big value and an optional caption.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.tone = Tone.brand,
    this.onTap,
    this.highlighted = false,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? caption;
  final Tone tone;
  final VoidCallback? onTap;

  /// Burgundy card with white text, for the one figure that matters most.
  final bool highlighted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? AppColors.white : null;
    return AppCard(
      variant: highlighted ? AppCardVariant.filled : AppCardVariant.surface,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              highlighted
                  ? Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: AppColors.champagne),
                    )
                  : IconBadge(icon, tone: tone, size: 36),
              const SizedBox(width: AppSpacing.s12),
              Expanded(child: AppText.label(label, color: highlighted ? AppColors.white.withValues(alpha: 0.85) : AppColors.muted, maxLines: 1)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: AppText.headline(value, color: fg ?? AppColors.ink),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            AppText.caption(caption!, color: highlighted ? AppColors.white.withValues(alpha: 0.7) : null, maxLines: 1),
          ],
        ],
      ),
    );
  }
}

/// Lays tiles out in as many equal columns as fit ([minTileWidth] each).
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children, this.minTileWidth = 220, this.spacing = AppSpacing.s16, this.maxColumns = 6});

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.maxWidth + spacing) / (minTileWidth + spacing)).floor().clamp(1, maxColumns);
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final c in children) SizedBox(width: width, child: c)],
        );
      },
    );
  }
}

/// A heading above a dashboard / details block.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleSmall(title),
                if (subtitle != null) AppText.caption(subtitle!),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// "Label ........ value" line for summaries and details.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.bold = false, this.valueColor, this.icon});

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final style = (bold ? t.titleSmall : t.bodyLarge)?.copyWith(color: valueColor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: AppColors.muted), const SizedBox(width: AppSpacing.s8)],
          Expanded(child: Text(label, style: bold ? t.titleSmall : t.bodyLarge?.copyWith(color: AppColors.muted))),
          const SizedBox(width: AppSpacing.s12),
          Flexible(child: Text(value, style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
