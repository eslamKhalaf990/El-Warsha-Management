import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// One look for every success and error message in the app.
void showSuccess(BuildContext context, String message) => _show(context, message, error: false);

void showError(BuildContext context, String message) => _show(context, message, error: true);

/// After a view-model action: pops [pop] routes and shows [success] when it
/// worked; otherwise shows the error, unless it belongs to one of [fields]
/// (those are already shown under the field).
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

/// Asks before a destructive action. Resolves to true only on confirm.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel, style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  return result == true;
}

void _show(BuildContext context, String message, {required bool error}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      duration: Duration(seconds: error ? 5 : 3),
      content: Row(
        children: [
          Icon(error ? Iconsax.warning_2 : Iconsax.tick_circle, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
    ));
}

/// Shown instead of a list when it could not be loaded.
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.cloud_cross, size: 40, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
