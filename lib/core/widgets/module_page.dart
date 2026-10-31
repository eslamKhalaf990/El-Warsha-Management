import 'package:flutter/material.dart';
import 'package:warsha_app/core/theme/app_theme.dart';
import 'package:warsha_app/core/widgets/app_button.dart';
import 'package:warsha_app/core/widgets/app_text.dart';

/// The main action of a list page ("Add product").
class PageAction {
  const PageAction({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

/// The layout every module's main page shares: title and actions on top, an
/// optional toolbar (search, filters), then the content filling the rest.
///
/// On phones the [primaryAction] becomes a floating button so it stays in
/// reach while scrolling; on larger screens it sits in the header.
class ModulePage extends StatelessWidget {
  const ModulePage({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.primaryAction,
    this.actions = const [],
    this.toolbar,
    this.scrollable = false,
  });

  final String title;
  final String? subtitle;
  final PageAction? primaryAction;

  /// Secondary header buttons (icon buttons with tooltips work best).
  final List<Widget> actions;
  final Widget? toolbar;
  final Widget body;

  /// When true the whole page scrolls (dashboards); otherwise [body] gets the
  /// remaining height and scrolls itself (lists).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final padding = context.pagePadding;

    final header = Padding(
      padding: EdgeInsets.fromLTRB(padding, compact ? AppSpacing.s16 : AppSpacing.s24, padding, AppSpacing.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                compact ? AppText.title(title, color: AppColors.deepWine) : AppText.headline(title),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  AppText.bodySmall(subtitle!, color: AppColors.muted),
                ],
              ],
            ),
          ),
          ...actions,
          if (primaryAction != null && !compact) ...[
            const SizedBox(width: AppSpacing.s8),
            AppButton.primary(
              label: primaryAction!.label,
              icon: primaryAction!.icon,
              onPressed: primaryAction!.onPressed,
            ),
          ],
        ],
      ),
    );

    final toolbarBox = toolbar == null
        ? null
        : Padding(padding: EdgeInsets.fromLTRB(padding, 0, padding, AppSpacing.s16), child: toolbar);

    final content = Padding(padding: EdgeInsets.symmetric(horizontal: padding), child: body);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      floatingActionButton: primaryAction != null && compact
          ? FloatingActionButton.extended(
              onPressed: primaryAction!.onPressed,
              icon: Icon(primaryAction!.icon),
              label: Text(primaryAction!.label),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: scrollable
                ? SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [header, if (toolbarBox != null) toolbarBox, content],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [header, if (toolbarBox != null) toolbarBox, Expanded(child: content)],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Bottom padding for lists on pages with a floating button, so the last
/// row can scroll clear of it.
EdgeInsets listPadding(BuildContext context) =>
    EdgeInsets.only(bottom: context.isCompact ? 96 : AppSpacing.s32);
