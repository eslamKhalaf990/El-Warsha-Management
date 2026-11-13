import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

/// The other language's name, written in that language, so it can be found
/// whichever language is showing.
String get _otherLanguage => AppLocale.instance.isArabic ? 'English' : 'العربية';

/// Sidebar / menu row that switches between Arabic and English.
class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key, this.onSwitched});

  /// E.g. to close the menu the tile sits in.
  final VoidCallback? onSwitched;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Iconsax.language_square_copy, size: 20),
      title: Text(_otherLanguage),
      subtitle: Text(tr('Change the language')),
      onTap: () {
        onSwitched?.call();
        AppLocale.instance.toggle();
      },
    );
  }
}

/// Compact switch for the sign-in page and the tablet rail.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key, this.iconOnly = false});

  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    if (iconOnly) {
      return IconButton(
        tooltip: _otherLanguage,
        icon: const Icon(Iconsax.language_square_copy),
        onPressed: AppLocale.instance.toggle,
      );
    }
    return TextButton.icon(
      icon: const Icon(Iconsax.language_square_copy, size: 18),
      label: Text(_otherLanguage),
      onPressed: AppLocale.instance.toggle,
    );
  }
}
