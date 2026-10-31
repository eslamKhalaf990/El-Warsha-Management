import 'package:intl/intl.dart';

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
    return currency ? '$text EGP' : text;
  }

  /// `12.5K EGP`, for KPI tiles and chart axes.
  static String moneyCompact(num? value) => '${_compact.format(value ?? 0)} EGP';

  static String number(num? value) => _number.format(value ?? 0);

  /// `3 products`, `1 product`, `No products`.
  static String count(int n, String singular, {String? plural, String? none}) {
    if (n == 0 && none != null) return none;
    return '${_moneyWhole.format(n)} ${n == 1 ? singular : (plural ?? '${singular}s')}';
  }

  /// `28 Oct 2026`
  static String date(DateTime? d) => d == null ? '—' : DateFormat('d MMM yyyy').format(d.toLocal());

  /// `28 Oct 2026, 2:05 PM`
  static String dateTime(DateTime? d) => d == null ? '—' : DateFormat('d MMM yyyy, h:mm a').format(d.toLocal());

  /// `28 Oct`
  static String shortDate(DateTime? d) => d == null ? '—' : DateFormat('d MMM').format(d.toLocal());

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
