import 'package:flutter/material.dart';
import 'package:warsha_app/core/theme/app_theme.dart';

enum AppCardVariant { surface, blush, ivory, filled, outlined }

/// The one card / panel surface: white with a 1px line border by default,
/// like the store. Tappable when [onTap] is set (hover + ripple on web).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.surface,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
    this.borderColor,
    this.width,
    this.height,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final background = color ??
        switch (variant) {
          AppCardVariant.surface => AppColors.white,
          AppCardVariant.blush => AppColors.blush,
          AppCardVariant.ivory => AppColors.ivory,
          AppCardVariant.filled => AppColors.burgundy,
          AppCardVariant.outlined => AppColors.transparent,
        };
    final side = borderColor != null
        ? BorderSide(color: borderColor!)
        : switch (variant) {
            AppCardVariant.surface || AppCardVariant.outlined => const BorderSide(color: AppColors.line),
            _ => BorderSide.none,
          };
    final dark = variant == AppCardVariant.filled;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: side);

    return Padding(
      padding: margin,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: background,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: onTap == null
              ? Padding(padding: padding, child: child)
              : InkWell(
                  onTap: onTap,
                  mouseCursor: SystemMouseCursors.click,
                  hoverColor: (dark ? AppColors.white : AppColors.burgundy).withValues(alpha: 0.04),
                  splashColor: (dark ? AppColors.white : AppColors.burgundy).withValues(alpha: 0.10),
                  child: Padding(padding: padding, child: child),
                ),
        ),
      ),
    );
  }
}
