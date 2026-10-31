import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/core/theme/app_theme.dart';

/// Digits with one optional decimal point or comma, for money and prices.
final moneyInputFormatters = [FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}'))];

/// Whole numbers only, for stock and quantities.
final intInputFormatters = [FilteringTextInputFormatter.digitsOnly];

/// The input used by every form. [errorText] comes from the view model
/// (`vm.fieldError('name')`), so client and server errors look the same.
/// Pass a [controller] (forms) or an [initialValue] (filters), not both.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.icon,
    this.errorText,
    this.helperText,
    this.hintText,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.inputFormatters,
    this.textDirection,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.obscureText = false,
    this.autofocus = false,
    this.required = false,
    this.prefixText,
    this.suffixText,
    this.suffix,
    this.autofillHints,
  }) : _isMoney = false;

  /// A money field: decimal keyboard, at most 2 decimals, "EGP" suffix.
  const AppTextField.money({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.icon = Iconsax.money_2_copy,
    this.errorText,
    this.helperText,
    this.hintText = '0',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.required = false,
    this.autofocus = false,
    this.textInputAction,
  })  : maxLength = 12,
        maxLines = 1,
        minLines = null,
        keyboardType = const TextInputType.numberWithOptions(decimal: true),
        inputFormatters = null,
        textDirection = TextDirection.ltr,
        obscureText = false,
        prefixText = null,
        suffixText = 'EGP',
        suffix = null,
        autofillHints = null,
        _isMoney = true;

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final IconData? icon;
  final String? errorText;
  final String? helperText;
  final String? hintText;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextDirection? textDirection;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool obscureText;
  final bool autofocus;

  /// Adds " *" to the label.
  final bool required;
  final String? prefixText;
  final String? suffixText;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final bool _isMoney;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      maxLength: maxLength,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      keyboardType: keyboardType ?? (maxLines > 1 ? TextInputType.multiline : null),
      inputFormatters: inputFormatters ?? (_isMoney ? moneyInputFormatters : null),
      textDirection: textDirection,
      textInputAction: textInputAction ?? (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      enabled: enabled,
      obscureText: obscureText,
      autofocus: autofocus,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        counterText: '',
        alignLabelWithHint: maxLines > 1,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        prefixText: prefixText,
        suffixText: suffixText,
        suffixIcon: suffix,
      ),
    );
  }
}

/// A dropdown that looks like [AppTextField]. Rebuilds from [value], so it
/// follows changes made elsewhere (e.g. a category added from a dialog).
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.value,
    required this.onChanged,
    this.icon,
    this.errorText,
    this.helperText,
    this.hintText,
    this.required = false,
    this.isEnabled,
  });

  final String label;
  final List<T> items;
  final String Function(T item) itemLabel;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final IconData? icon;
  final String? errorText;
  final String? helperText;
  final String? hintText;
  final bool required;

  /// Items for which this returns false are shown greyed out.
  final bool Function(T item)? isEnabled;

  @override
  Widget build(BuildContext context) {
    final current = items.contains(value) ? value : null;
    return DropdownButtonFormField<T>(
      key: ValueKey(current),
      initialValue: current,
      isExpanded: true,
      borderRadius: AppRadius.cardBorderRadius,
      dropdownColor: AppColors.white,
      icon: const Icon(Iconsax.arrow_down_1_copy, size: 18),
      hint: hintText == null ? null : Text(hintText!),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item,
            enabled: isEnabled?.call(item) ?? true,
            child: Text(
              itemLabel(item),
              overflow: TextOverflow.ellipsis,
              style: (isEnabled?.call(item) ?? true) ? null : const TextStyle(color: AppColors.muted),
            ),
          ),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
      ),
    );
  }
}

/// The pill-shaped search box at the top of list pages.
class AppSearchField extends StatelessWidget {
  const AppSearchField({super.key, required this.hint, required this.onChanged, this.initialValue = ''});

  final String hint;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Iconsax.search_normal_1_copy, size: 20),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.pillBorderRadius,
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.pillBorderRadius,
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.pillBorderRadius,
          borderSide: BorderSide(color: AppColors.burgundy, width: 1.5),
        ),
      ),
    );
  }
}

/// A labelled switch row inside a form section.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({super.key, required this.title, required this.value, required this.onChanged, this.subtitle});

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: AppRadius.inputBorderRadius),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      ),
    );
  }
}

/// The message under a non-text input (image picker, item list...).
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8, left: AppSpacing.s12),
      child: Text(
        message!,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppStatusColors.errorText),
      ),
    );
  }
}

/// A date input that opens the date picker. [onChanged] gets null when the
/// user clears it (only offered when [clearable]).
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon = Iconsax.calendar_1_copy,
    this.errorText,
    this.helperText,
    this.hintText = 'Choose a date',
    this.required = false,
    this.clearable = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final IconData icon;
  final String? errorText;
  final String? helperText;
  final String hintText;
  final bool required;
  final bool clearable;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: AppRadius.inputBorderRadius,
      child: InputDecorator(
        isEmpty: v == null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: clearable && v != null
              ? IconButton(tooltip: 'Clear', icon: const Icon(Iconsax.close_circle_copy, size: 18), onPressed: () => onChanged(null))
              : null,
        ),
        child: v == null ? null : Text('${v.day}/${v.month}/${v.year}'),
      ),
    );
  }
}
