import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/core/theme/app_theme.dart';
import 'package:warsha_app/core/widgets/app_button.dart';
import 'package:warsha_app/core/widgets/feedback.dart';

/// A small add/edit form in a dialog, for entities with a few fields
/// (category, shipping zone, transaction). Ctrl/⌘+S saves.
class FormDialog extends StatelessWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
    required this.saving,
    required this.saveLabel,
    this.icon,
    this.maxWidth = 480,
    this.danger = false,
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;
  final VoidCallback onSave;
  final bool saving;
  final String saveLabel;
  final double maxWidth;

  /// Red save button, for destructive confirmations that need input.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => saving ? null : onSave(),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () => saving ? null : onSave(),
      },
      child: AppDialog(
        title: title,
        icon: icon,
        maxWidth: maxWidth,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.s16),
              children[i],
            ],
          ],
        ),
        actions: [
          AppButton.text(label: 'Cancel', onPressed: () => Navigator.pop(context)),
          danger
              ? AppButton.danger(label: saveLabel, onPressed: onSave, loading: saving)
              : AppButton.primary(label: saveLabel, onPressed: onSave, loading: saving, icon: Iconsax.tick_circle_copy),
        ],
      ),
    );
  }
}
