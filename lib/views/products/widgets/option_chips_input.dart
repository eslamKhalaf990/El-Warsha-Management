import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/core/widgets/widgets.dart';

/// Type a value and press Enter (or +) to add it as a chip; tap a chip's ×
/// to remove it. Used for the sizes and colors of a new product.
class OptionChipsInput extends StatelessWidget {
  const OptionChipsInput({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  void _add() {
    final parts = controller.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    final next = [...values];
    for (final p in parts) {
      if (!next.any((v) => v.toLowerCase() == p.toLowerCase())) next.add(p);
    }
    controller.clear();
    if (next.length != values.length) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: label,
          hintText: hint,
          icon: icon,
          controller: controller,
          helperText: 'Press Enter to add. Separate several with commas.',
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _add(),
          suffix: IconButton(tooltip: 'Add', icon: const Icon(Iconsax.add_circle_copy, size: 20), onPressed: _add),
        ),
        if (values.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final v in values)
                InputChip(
                  label: Text(v),
                  deleteIcon: const Icon(Iconsax.close_circle_copy, size: 16),
                  onDeleted: () => onChanged(values.where((x) => x != v).toList()),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
