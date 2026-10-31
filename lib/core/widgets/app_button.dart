import 'package:flutter/material.dart';
import 'package:warsha_app/core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, text, danger }

/// The pill button from the store. Shows a spinner and ignores taps while
/// [loading]; a null [onPressed] disables it.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  }) : variant = AppButtonVariant.text;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;

  /// Fill the available width (mobile primary actions).
  final bool expand;

  /// 40px tall, for toolbars and table rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final filled = variant == AppButtonVariant.primary || variant == AppButtonVariant.danger;
    final fg = filled ? AppColors.white : (variant == AppButtonVariant.danger ? AppStatusColors.errorText : AppColors.burgundy);
    final child = loading
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: filled ? AppColors.white : AppColors.burgundy),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: AppSpacing.s8)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final size = compact ? const Size(40, 40) : const Size(88, 48);
    final padding = EdgeInsets.symmetric(horizontal: compact ? AppSpacing.s16 : AppSpacing.s24);
    final action = loading ? null : onPressed;
    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: action,
          style: FilledButton.styleFrom(minimumSize: size, padding: padding),
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: action,
          style: FilledButton.styleFrom(
            minimumSize: size,
            padding: padding,
            backgroundColor: AppStatusColors.errorText,
            foregroundColor: fg,
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(minimumSize: size, padding: padding),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: action,
          style: TextButton.styleFrom(minimumSize: size, padding: padding),
          child: child,
        ),
    };
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
