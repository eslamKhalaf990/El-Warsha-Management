import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/core/theme/app_theme.dart';
import 'package:warsha_app/core/widgets/app_card.dart';
import 'package:warsha_app/core/widgets/app_text.dart';

/// An action on a row: edit, delete, archive...
class RowAction {
  const RowAction({required this.label, required this.icon, required this.onPressed, this.destructive = false});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool destructive;
}

/// Shows [actions] as icon buttons with tooltips on wide screens and as a
/// "more" menu on phones, where space is short.
class RowActions extends StatelessWidget {
  const RowActions(this.actions, {super.key, this.busy = false, this.forceMenu = false});

  final List<RowAction> actions;
  final bool busy;
  final bool forceMenu;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox.square(dimension: 40, child: Center(child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))));
    }
    if (actions.isEmpty) return const SizedBox.shrink();
    if (forceMenu || context.isCompact) {
      return PopupMenuButton<RowAction>(
        tooltip: 'More actions',
        icon: const Icon(Iconsax.more_copy, size: 20),
        onSelected: (a) => a.onPressed?.call(),
        itemBuilder: (_) => [
          for (final a in actions)
            PopupMenuItem(
              value: a,
              enabled: a.onPressed != null,
              child: Row(
                children: [
                  Icon(a.icon, size: 18, color: a.destructive ? AppStatusColors.errorText : AppColors.ink),
                  const SizedBox(width: AppSpacing.s12),
                  Text(a.label, style: TextStyle(color: a.destructive ? AppStatusColors.errorText : null)),
                ],
              ),
            ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final a in actions)
          IconButton(
            tooltip: a.label,
            onPressed: a.onPressed,
            icon: Icon(a.icon, size: 20, color: a.destructive ? AppStatusColors.errorText : AppColors.ink),
          ),
      ],
    );
  }
}

/// A list row card: leading visual, title, subtitle, a line of pills,
/// trailing value and actions. Used by every simple module list.
class EntityTile extends StatelessWidget {
  const EntityTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.meta = const [],
    this.trailing,
    this.actions = const [],
    this.busy = false,
    this.onTap,
    this.dimmed = false,
  });

  final Widget leading;
  final String title;
  final String? subtitle;

  /// Small pills / captions under the subtitle.
  final List<Widget> meta;
  final Widget? trailing;
  final List<RowAction> actions;
  final bool busy;
  final VoidCallback? onTap;

  /// Greys the row out (archived, inactive).
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleSmall(title, maxLines: 1),
                  if (subtitle != null && subtitle!.isNotEmpty) AppText.bodySmall(subtitle!, color: AppColors.muted, maxLines: 2),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(spacing: AppSpacing.s8, runSpacing: AppSpacing.s4, children: meta),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: AppSpacing.s12), trailing!],
            if (actions.isNotEmpty || busy) ...[const SizedBox(width: AppSpacing.s4), RowActions(actions, busy: busy)],
          ],
        ),
      ),
    );
  }
}

/// A vertical list of rows with even gaps and room for the floating button.
class TileList<T> extends StatelessWidget {
  const TileList({super.key, required this.items, required this.itemBuilder, this.onRefresh});

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView.separated(
      padding: EdgeInsets.only(bottom: context.isCompact ? 96 : AppSpacing.s32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s8),
      itemBuilder: (context, i) => itemBuilder(context, items[i]),
    );
    return onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}
