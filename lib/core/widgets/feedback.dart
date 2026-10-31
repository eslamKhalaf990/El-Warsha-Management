import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/core/theme/app_theme.dart';
import 'package:warsha_app/core/widgets/app_button.dart';
import 'package:warsha_app/core/widgets/status_pill.dart';

/// One look for every success and error message in the app.
void showSuccess(BuildContext context, String message) => _show(context, message, Tone.success);

void showError(BuildContext context, String message) => _show(context, message, Tone.error);

void showInfo(BuildContext context, String message) => _show(context, message, Tone.info);

/// After a view-model action: pops [pop] routes and shows [success] when it
/// worked; otherwise shows the error, unless every failing field is one of
/// [fields] (those are already shown under the field).
void reportResult(
  BuildContext context, {
  required bool ok,
  required String? errorMessage,
  required String success,
  String? Function(String field)? fieldError,
  List<String> fields = const [],
  bool pop = false,
}) {
  if (!context.mounted) return;
  if (ok) {
    if (pop) Navigator.pop(context);
    showSuccess(context, success);
  } else if (fieldError == null || fields.every((f) => fieldError(f) == null)) {
    showError(context, errorMessage ?? 'Something went wrong. Please try again.');
  }
}

void _show(BuildContext context, String message, Tone tone) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final icon = switch (tone) {
    Tone.success => Iconsax.tick_circle_copy,
    Tone.error => Iconsax.warning_2_copy,
    _ => Iconsax.info_circle_copy,
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: Duration(seconds: tone == Tone.error ? 6 : 3),
      backgroundColor: tone == Tone.error ? AppStatusColors.errorText : AppColors.deepWine,
      showCloseIcon: tone == Tone.error,
      closeIconColor: AppColors.white,
      content: Row(
        children: [
          Icon(icon, color: tone == Tone.success ? AppColors.champagne : AppColors.white, size: 20),
          const SizedBox(width: AppSpacing.s12),
          Expanded(child: Text(message)),
        ],
      ),
    ));
}

/// A dialog in the app's style: optional icon, title, content, actions;
/// never wider than [maxWidth].
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.icon,
    this.tone = Tone.brand,
    this.maxWidth = 460,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
  final IconData? icon;
  final Tone tone;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      icon: icon == null ? null : IconBadge(icon!, tone: tone, size: 48),
      title: Text(title, textAlign: icon == null ? TextAlign.start : TextAlign.center),
      content: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth, minWidth: 280), child: content),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.s24, 0, AppSpacing.s24, AppSpacing.s24),
      actions: actions,
    );
  }
}

/// Asks before an action. Resolves to true only on confirm.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
  IconData icon = Iconsax.trash_copy,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AppDialog(
      title: title,
      icon: icon,
      tone: destructive ? Tone.error : Tone.brand,
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        AppButton.text(label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
        destructive
            ? AppButton.danger(label: confirmLabel, onPressed: () => Navigator.pop(context, true))
            : AppButton.primary(label: confirmLabel, onPressed: () => Navigator.pop(context, true)),
      ],
    ),
  );
  return result == true;
}
