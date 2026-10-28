import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The rounded, icon-prefixed input used across the ERP forms. [errorText]
/// comes from the view model (`vm.fieldError('name')`), so client and server
/// errors show the same way.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.errorText,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.textDirection,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? errorText;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextDirection? textDirection;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(maxLines > 1 ? 15 : 25);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(borderSide: BorderSide(color: color, width: width), borderRadius: radius);

    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textDirection: textDirection,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      enabled: enabled,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        errorText: errorText,
        errorMaxLines: 2,
        counterText: '',
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        enabledBorder: border(Colors.grey.shade200),
        disabledBorder: border(Colors.grey.shade100),
        focusedBorder: border(scheme.tertiary, 1.5),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.5),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Icon(icon, color: scheme.tertiary),
        ),
      ),
    );
  }
}

/// Cancel + primary save buttons at the bottom of every add/edit form.
class FormActions extends StatelessWidget {
  const FormActions({super.key, required this.onSave, required this.saving, required this.saveLabel});

  final VoidCallback onSave;
  final bool saving;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 55,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 55,
            child: FilledButton(
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.tertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(saveLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}
