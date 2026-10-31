import 'package:flutter/material.dart';
import 'package:warsha_app/core/widgets/widgets.dart';

/// One row of a [RankedBars] list.
class RankedItem {
  const RankedItem({required this.label, required this.value, required this.valueLabel, this.caption});

  final String label;
  final double value;
  final String valueLabel;
  final String? caption;
}

/// A ranked horizontal bar list with every value written out, so it reads
/// without colour or hovering. Bars share one scale (the largest value).
class RankedBars extends StatelessWidget {
  const RankedBars({super.key, required this.items, this.color = AppChartColors.single, this.emptyText = 'No data yet.'});

  final List<RankedItem> items;
  final Color color;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
        child: Center(child: AppText.bodySmall(emptyText, color: AppColors.muted)),
      );
    }
    final max = items.map((i) => i.value).fold<double>(0, (a, b) => b > a ? b : a);
    return Column(
      children: [
        for (final item in items)
          Tooltip(
            message: '${item.label}: ${item.valueLabel}${item.caption == null ? '' : ' · ${item.caption}'}',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: AppText.bodySmall(item.label, maxLines: 1)),
                      AppText.label(item.valueLabel),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder: (context, c) => Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.all(Radius.circular(4))),
                        ),
                        Container(
                          height: 8,
                          width: max <= 0 ? 0 : (c.maxWidth * item.value / max).clamp(4, c.maxWidth),
                          decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.all(Radius.circular(4))),
                        ),
                      ],
                    ),
                  ),
                  if (item.caption != null) ...[const SizedBox(height: 2), AppText.caption(item.caption!)],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A titled dashboard panel.
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({super.key, required this.title, required this.child, this.subtitle, this.icon});

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            if (icon != null) ...[IconBadge(icon!, size: 32), const SizedBox(width: AppSpacing.s12)],
            Expanded(child: SectionHeader(title, subtitle: subtitle)),
          ]),
          child,
        ],
      ),
    );
  }
}
