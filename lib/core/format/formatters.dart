import 'package:intl/intl.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

/// One way to print money, numbers and dates across the ERP.
abstract final class Fmt {
  static final _money = NumberFormat('#,##0.00');
  static final _moneyWhole = NumberFormat('#,##0');
  static final _number = NumberFormat('#,##0.##');
  static final _compact = NumberFormat.compact();

  /// `1,250.50 EGP`; whole amounts drop the decimals (`1,250 EGP`).
  static String money(num? value, {bool currency = true}) {
    final v = (value ?? 0).toDouble();
    final text = v == v.roundToDouble() ? _moneyWhole.format(v) : _money.format(v);
    return _ltr(currency ? '$text $currencyLabel' : text);
  }

  /// In Arabic, keeps a leading minus/plus on the left of its number.
  static String _ltr(String s) =>
      AppLocale.instance.isArabic && (s.startsWith('-') || s.startsWith('+') || s.startsWith('−')) ? '\u200E$s' : s;

  /// "EGP", or "ج.م" in Arabic.
  static String get currencyLabel => AppLocale.instance.isArabic ? 'ج.م' : 'EGP';

  /// `12.5K EGP`, for KPI tiles and chart axes.
  static String moneyCompact(num? value) => '${_compact.format(value ?? 0)} $currencyLabel';

  static String number(num? value) => _number.format(value ?? 0);

  /// A fraction as a percentage: `0.256` → `26%` (`25.6%` with one decimal).
  static String percent(num? fraction, {int decimals = 0}) {
    final text = '${((fraction ?? 0) * 100).toStringAsFixed(decimals)}%';
    // Keeps "62%" from showing as "%62" inside Arabic text.
    return AppLocale.instance.isArabic ? '\u200E$text\u200E' : text;
  }

  /// A change as `+12%` / `−4%`.
  static String change(num fraction) {
    final p = (fraction * 100).round();
    return _ltr(p > 0 ? '+$p%' : (p < 0 ? '−${-p}%' : '0%'));
  }

  /// `3 products`, `1 product`, `No products`. In Arabic: `منتج واحد`,
  /// `منتجين`, `3 منتجات`, `15 منتج` ([singular] is the English noun).
  static String count(int n, String singular, {String? plural, String? none}) {
    if (n == 0 && none != null) return none;
    final forms = AppLocale.instance.isArabic ? _arabicNouns[singular] : null;
    if (forms != null) {
      final (one, two, few, many) = forms;
      if (n == 1) return one;
      if (n == 2) return two;
      return '${_moneyWhole.format(n)} ${n >= 3 && n <= 10 ? few : many}';
    }
    return '${_moneyWhole.format(n)} ${n == 1 ? singular : (plural ?? '${singular}s')}';
  }

  /// English noun → (one, two, 3–10, 0 and 11+) in Egyptian Arabic.
  static const _arabicNouns = <String, (String, String, String, String)>{
    'account': ('حساب واحد', 'حسابين', 'حسابات', 'حساب'),
    'active vendor': ('مورد واحد', 'موردين اتنين', 'موردين', 'مورد'),
    'cart': ('سلة واحدة', 'سلتين', 'سلال', 'سلة'),
    'cart add': ('إضافة واحدة للسلة', 'إضافتين للسلة', 'إضافات للسلة', 'إضافة للسلة'),
    'category': ('قسم واحد', 'قسمين', 'أقسام', 'قسم'),
    'code': ('كود واحد', 'كودين', 'أكواد', 'كود'),
    'customer': ('عميل واحد', 'عميلين', 'عملاء', 'عميل'),
    'day': ('يوم واحد', 'يومين', 'أيام', 'يوم'),
    'governorate': ('محافظة واحدة', 'محافظتين', 'محافظات', 'محافظة'),
    'image': ('صورة واحدة', 'صورتين', 'صور', 'صورة'),
    'line': ('صنف واحد', 'صنفين', 'أصناف', 'صنف'),
    'option': ('اختيار واحد', 'اختيارين', 'اختيارات', 'اختيار'),
    'order': ('طلب واحد', 'طلبين', 'طلبات', 'طلب'),
    'page view': ('مشاهدة واحدة', 'مشاهدتين', 'مشاهدات', 'مشاهدة'),
    'piece': ('قطعة واحدة', 'قطعتين', 'قطع', 'قطعة'),
    'product': ('منتج واحد', 'منتجين', 'منتجات', 'منتج'),
    'search': ('بحث واحد', 'بحثين', 'عمليات بحث', 'عملية بحث'),
    'time': ('مرة واحدة', 'مرتين', 'مرات', 'مرة'),
    'transaction': ('حركة واحدة', 'حركتين', 'حركات', 'حركة'),
    'vendor': ('مورد واحد', 'موردين اتنين', 'موردين', 'مورد'),
    'visit': ('زيارة واحدة', 'زيارتين', 'زيارات', 'زيارة'),
    'visitor': ('زائر واحد', 'زائرين', 'زوار', 'زائر'),
  };

  /// [pattern] with month and day names in the current language.
  static DateFormat dateFormat(String pattern) =>
      AppLocale.instance.isArabic ? DateFormat(pattern, 'ar') : DateFormat(pattern);

  /// `28 Oct 2026`
  static String date(DateTime? d) => d == null ? '—' : dateFormat('d MMM yyyy').format(d.toLocal());

  /// `28 Oct 2026, 2:05 PM`
  static String dateTime(DateTime? d) => d == null ? '—' : dateFormat('d MMM yyyy, h:mm a').format(d.toLocal());

  /// `28 Oct`
  static String shortDate(DateTime? d) => d == null ? '—' : dateFormat('d MMM').format(d.toLocal());

  /// Two-letter initials for avatars.
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters(2).toUpperCase();
    return (parts.first.characters(1) + parts.last.characters(1)).toUpperCase();
  }
}

extension on String {
  String characters(int n) => length <= n ? this : substring(0, n);
}
