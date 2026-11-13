import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warsha_app/core/l10n/ar.dart';

/// The ERP's language: Arabic (Egyptian, the default) or English, chosen per
/// browser and saved there.
///
/// Text goes through [tr]. English is the key, so anything without an Arabic
/// entry simply shows in English. Switching languages redraws every widget in
/// place, so open pages, dialogs and typed text stay as they are.
class AppLocale extends ChangeNotifier {
  AppLocale._();

  static final instance = AppLocale._();

  static const supported = [Locale('ar'), Locale('en')];
  static const _prefsKey = 'app_locale';

  // English until [load] runs, so tests and anything before startup read English.
  String _code = 'en';

  String get code => _code;
  bool get isArabic => _code == 'ar';
  Locale get locale => Locale(_code);

  /// Reads the saved choice (Arabic when there is none) and prepares Arabic dates.
  Future<void> load() async {
    await initializeDateFormatting('ar');
    // Western digits in Arabic dates too, to match prices and phone numbers.
    DateFormat.useNativeDigitsByDefaultFor('ar', false);
    try {
      final prefs = await SharedPreferences.getInstance();
      _code = prefs.getString(_prefsKey) == 'en' ? 'en' : 'ar';
    } catch (_) {
      _code = 'ar';
    }
  }

  Future<void> set(String code) async {
    if (code == _code || !supported.any((l) => l.languageCode == code)) return;
    _code = code;
    _rebuildEverything();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, code);
    } catch (_) {
      // Not saved; the switch still applies until the page reloads.
    }
  }

  void toggle() => set(isArabic ? 'en' : 'ar');

  /// For tests.
  @visibleForTesting
  void debugSet(String code) => _code = code;

  static void _rebuildEverything() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
  }
}

/// [en] in the current language. `{0}`, `{1}`… are filled from [args]:
/// `tr('{0} pieces', [n])`.
String tr(String en, [List<Object?> args = const []]) {
  var text = AppLocale.instance.isArabic ? (arStrings[en] ?? en) : en;
  for (var i = 0; i < args.length; i++) {
    text = text.replaceAll('{$i}', '${args[i]}');
  }
  return text;
}
