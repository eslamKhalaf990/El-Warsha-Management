import 'package:flutter/material.dart';
import 'package:warsha_app/core/theme/app_theme.dart';

enum Tone { brand, success, warning, info, neutral, error }

extension ToneColors on Tone {
  Color get foreground => switch (this) {
        Tone.brand => AppColors.burgundy,
        Tone.success => AppStatusColors.successText,
        Tone.warning => AppStatusColors.warningText,
        Tone.info => AppStatusColors.infoText,
        Tone.neutral => AppStatusColors.neutralText,
        Tone.error => AppStatusColors.errorText,
      };

  Color get background => switch (this) {
        Tone.brand => AppColors.blush,
        Tone.success => AppStatusColors.successBackground,
        Tone.warning => AppStatusColors.warningBackground,
        Tone.info => AppStatusColors.infoBackground,
        Tone.neutral => AppStatusColors.neutralBackground,
        Tone.error => AppStatusColors.errorBackground,
      };
}

/// A small rounded label for a status, stock level, payment method...
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.tone = Tone.neutral, this.icon});

  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: tone.background, borderRadius: AppRadius.pillBorderRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: tone.foreground), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: tone.foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// An icon on a tinted rounded square, used as the leading visual of rows,
/// stat tiles and empty states.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.tone = Tone.brand, this.size = 40});

  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, size: size * 0.5, color: tone.foreground),
    );
  }
}

/// Initials on a blush circle, for people and companies.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.initials, {super.key, this.size = 40});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.blush,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.burgundy, fontSize: size * 0.36),
      ),
    );
  }
}
