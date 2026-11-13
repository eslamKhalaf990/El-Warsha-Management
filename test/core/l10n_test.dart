import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/core/format/formatters.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';
import 'package:warsha_app/core/l10n/ar.dart';
import 'package:warsha_app/models/order_options.dart';
import 'package:warsha_app/models/review.dart';
import 'package:warsha_app/models/voucher.dart';
import 'package:warsha_app/view_models/analytics_v_m.dart';
import 'package:warsha_app/view_models/behavior_v_m.dart';
import 'package:warsha_app/view_models/product_v_m.dart';
import 'package:warsha_app/views/behavior/widgets/daily_activity_chart.dart';
import 'package:warsha_app/views/dashboard/widgets/trend_chart.dart';

/// Every `tr('…')` phrase in lib/, as its runtime text.
Set<String> _trPhrases() {
  final call = RegExp(r"\btr\('((?:\\.|[^'\\])*)'");
  final phrases = <String>{};
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart') || f.path.endsWith('ar.dart')) continue;
    // Doc comments show tr() examples; only code counts.
    final code = f.readAsStringSync().split('\n').where((l) => !l.trimLeft().startsWith('//')).join('\n');
    for (final m in call.allMatches(code)) {
      phrases.add(m.group(1)!.replaceAllMapped(RegExp(r'\\(.)'), (e) => switch (e.group(1)) {
            'n' => '\n',
            't' => '\t',
            final c => c!,
          }));
    }
  }
  return phrases;
}

Iterable<String> _placeholders(String s) => RegExp(r'\{\d+\}').allMatches(s).map((m) => m.group(0)!).toList()..sort();

void main() {
  tearDown(() => AppLocale.instance.debugSet('en'));

  test('every tr() phrase has Egyptian Arabic with the same placeholders', () {
    final phrases = _trPhrases();
    expect(phrases.length, greaterThan(500));
    final missing = phrases.where((p) => !arStrings.containsKey(p)).toList();
    expect(missing, isEmpty, reason: 'Add these to lib/core/l10n/ar.dart');
    for (final p in phrases) {
      expect(_placeholders(arStrings[p]!), _placeholders(p), reason: p);
    }
  });

  test('labels kept in enums and option lists have Arabic too', () {
    final labels = [
      for (final v in RangePreset.values) v.labelEn,
      for (final v in BehaviorPreset.values) v.labelEn,
      for (final v in IdleCutoff.values) v.labelEn,
      for (final v in StockFilter.values) v.labelEn,
      for (final v in ReviewStatus.values) v.labelEn,
      for (final v in DiscountKind.values) v.labelEn,
      for (final v in ActivityMeasure.values) v.labelEn,
      for (final v in TrendMeasure.values) v.labelEn,
      for (final o in [...orderSources, ...paymentMethods]) o.labelEn,
      ...reviewTypes.values,
    ];
    expect(labels.where((l) => !arStrings.containsKey(l)), isEmpty);
  });

  test('no emojis in the Arabic', () {
    // ★ (U+2605) is the plain rating star the English uses too.
    final emoji = RegExp('[\u{1F300}-\u{1FAFF}\u{2600}-\u{2604}\u{2606}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true);
    expect(arStrings.values.where(emoji.hasMatch), isEmpty);
  });

  test('tr switches language and fills placeholders', () {
    expect(tr('Order #{0}', [12]), 'Order #12');
    AppLocale.instance.debugSet('ar');
    expect(tr('Order #{0}', [12]), 'طلب #12');
    expect(tr('Not translated yet'), 'Not translated yet');
  });

  test('Arabic counts follow Egyptian grammar and money says ج.م', () {
    AppLocale.instance.debugSet('ar');
    expect(Fmt.count(1, 'order'), 'طلب واحد');
    expect(Fmt.count(2, 'order'), 'طلبين');
    expect(Fmt.count(5, 'order'), '5 طلبات');
    expect(Fmt.count(15, 'order'), '15 طلب');
    expect(Fmt.count(0, 'product', none: 'No products'), 'No products');
    expect(Fmt.money(1250), '1,250 ج.م');
    AppLocale.instance.debugSet('en');
    expect(Fmt.count(5, 'order'), '5 orders');
    expect(Fmt.money(1250), '1,250 EGP');
  });
}
