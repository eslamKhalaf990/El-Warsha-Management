import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:warsha_app/core/theme/app_theme.dart';
import 'package:warsha_app/core/widgets/app_button.dart';
import 'package:warsha_app/core/widgets/app_text.dart';
import 'package:warsha_app/core/widgets/status_pill.dart';

/// A centered icon, title, message and optional action, for empty lists
/// and searches with no match.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = Iconsax.box_1_copy,
    this.actionLabel,
    this.onAction,
  });

  /// "Nothing matches" for a search box.
  factory EmptyView.noMatch(String query, {Key? key}) => EmptyView(
        key: key,
        icon: Iconsax.search_normal_1_copy,
        title: 'No results',
        message: 'Nothing matches "${query.trim()}". Try another word.',
      );

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBadge(icon, size: 64),
              const SizedBox(height: AppSpacing.s16),
              AppText.titleSmall(title, align: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.s4),
                AppText.bodySmall(message!, color: AppColors.muted, align: TextAlign.center),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.s16),
                AppButton.primary(label: actionLabel!, onPressed: onAction, icon: Iconsax.add_copy),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown instead of content that could not be loaded.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry, this.retryLabel = 'Try again'});

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconBadge(Iconsax.cloud_cross_copy, tone: Tone.error, size: 64),
              const SizedBox(height: AppSpacing.s16),
              const AppText.titleSmall("Couldn't load this page", align: TextAlign.center),
              const SizedBox(height: AppSpacing.s4),
              AppText.bodySmall(message, color: AppColors.muted, align: TextAlign.center),
              const SizedBox(height: AppSpacing.s16),
              AppButton.secondary(label: retryLabel, icon: Iconsax.refresh_copy, onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

/// A spinner for short waits inside cards and dialogs.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(padding: EdgeInsets.all(AppSpacing.s24), child: CircularProgressIndicator()),
      );
}

/// Grey placeholder rows while a list loads, so the page doesn't jump.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 8, this.itemHeight = 72});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.blush,
      highlightColor: AppColors.ivory,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s8),
        itemBuilder: (_, __) => Container(
          height: itemHeight,
          decoration: const BoxDecoration(color: AppColors.white, borderRadius: AppRadius.cardBorderRadius),
        ),
      ),
    );
  }
}

/// A slim warning strip, e.g. "Some figures couldn't be loaded. Retry".
class InlineBanner extends StatelessWidget {
  const InlineBanner({super.key, required this.message, this.tone = Tone.warning, this.icon = Iconsax.info_circle_copy, this.actionLabel, this.onAction});

  final String message;
  final Tone tone;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
      decoration: BoxDecoration(color: tone.background, borderRadius: AppRadius.cardBorderRadius),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tone.foreground),
          const SizedBox(width: AppSpacing.s12),
          Expanded(child: AppText.bodySmall(message, color: tone.foreground)),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: tone.foreground, minimumSize: const Size(40, 36)),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
