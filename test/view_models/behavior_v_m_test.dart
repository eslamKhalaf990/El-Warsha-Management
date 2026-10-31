import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/models/behavior.dart';
import 'package:warsha_app/services/behavior_service.dart';
import 'package:warsha_app/view_models/behavior_v_m.dart';
import 'package:warsha_app/views/behavior/widgets/daily_activity_chart.dart';

void main() {
  final seen = <Uri>[];

  BehaviorVM vm(http.Response Function(String path) answer) => BehaviorVM(
        BehaviorService(ApiClient(
          baseUrl: 'http://api.test/',
          client: MockClient((req) async {
            seen.add(req.url);
            return answer(req.url.path);
          }),
        )),
        today: () => DateTime(2026, 10, 31, 15, 30),
      );

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

  http.Response sample(String path) {
    if (path.endsWith('overview')) {
      return json({
        'range': {'from': '2026-10-02', 'to': '2026-10-31', 'days': 30},
        'visitors': 120,
        'newVisitors': 70,
        'sessions': 150,
        'productViews': 400,
        'orders': 10,
        'orderValue': 4200.5,
        'funnel': {'sessions': 150, 'viewedProduct': 100, 'addedToCart': 40, 'conversionRate': 0.0667},
        'devices': [{'device': 'MOBILE', 'sessions': 120, 'share': 0.8}],
        'days': [{'date': '2026-10-30', 'visitors': 50, 'orders': 5}],
      });
    }
    if (path.endsWith('abandoned-carts')) {
      return json({
        'range': {'from': '2026-10-02', 'to': '2026-10-31', 'days': 30},
        'idleMinutes': 60,
        'count': 2,
        'value': 480,
        'orderedCarts': 6,
        'abandonmentRate': 0.25,
        'carts': [
          {
            'visitorId': 'v1',
            'customerId': 44,
            'customerName': 'Mona Ali',
            'phone': '01000000000',
            'itemCount': 3,
            'value': 430,
            'lastActivity': '2026-10-31T09:15:00',
            'source': 'Facebook',
            'device': 'MOBILE',
            'items': [
              {'productId': 1, 'variantId': 9, 'name': 'Mug', 'variant': 'L / Black', 'quantity': 2},
            ],
          },
          {'visitorId': 'v2', 'customerId': null, 'itemCount': 1, 'value': 50, 'items': []},
        ],
      });
    }
    if (path.endsWith('products')) {
      return json([
        {'productId': 2, 'name': 'Shirt', 'views': 50, 'cartAdds': 5, 'viewToCartRate': 0.1},
      ]);
    }
    if (path.endsWith('searches')) {
      return json({
        'total': 33,
        'noResults': 7,
        'top': [{'query': 'mug', 'searches': 20, 'averageResults': 4.3}],
        'withoutResults': [{'query': 'tote bag', 'searches': 5, 'averageResults': null, 'noResultSearches': 5}],
      });
    }
    if (path.endsWith('vouchers')) {
      return json([
        {'code': 'RAMADAN10', 'tries': 10, 'applied': 6, 'rejected': 4, 'rejections': {'EXPIRED': 3, 'MIN_ORDER': 1}},
      ]);
    }
    if (path.endsWith('sources')) return json([{'source': 'Facebook', 'visitors': 40, 'orders': 5, 'conversionRate': 0.1}]);
    return json({});
  }

  setUp(seen.clear);

  test('loads every section for the last 30 days by default', () async {
    final model = vm(sample);

    expect(await model.fetch(), isTrue);
    expect(model.failedSections, isEmpty);
    expect(model.hasActivity, isTrue);
    expect(model.overview!.visitors, 120);
    expect(model.overview!.returningVisitors, 50);
    expect(model.overview!.funnel.addedToCart, 40);
    expect(model.overview!.devices.single.label, 'Mobile');
    expect(model.products!.single.name, 'Shirt');
    expect(model.searches!.withoutResults.single.averageResults, isNull);
    expect(model.vouchers!.single.rejectionSummary, 'Expired ×3, Below minimum ×1');
    expect(model.sources!.single.source, 'Facebook');

    final carts = model.abandoned!;
    expect(carts.count, 2);
    expect(carts.carts.first.who, 'Mona Ali');
    expect(carts.carts.first.items.single.label, 'Mug (L / Black)');
    expect(carts.carts.first.lastActivity, DateTime(2026, 10, 31, 9, 15));
    expect(carts.carts.last.isGuest, isTrue);
    expect(carts.carts.last.who, 'Guest visitor');

    final overview = seen.firstWhere((u) => u.path.endsWith('overview'));
    expect(overview.queryParameters, {'from': '2026-10-02', 'to': '2026-10-31'});
    final abandoned = seen.firstWhere((u) => u.path.endsWith('abandoned-carts'));
    expect(abandoned.queryParameters['idleMinutes'], '60');
  });

  test('presets turn into the right days', () async {
    final model = vm(sample);
    await model.setPreset(BehaviorPreset.today);
    expect((model.from, model.to), (DateTime(2026, 10, 31), DateTime(2026, 10, 31)));
    await model.setPreset(BehaviorPreset.last7);
    expect(model.from, DateTime(2026, 10, 25));
    await model.setPreset(BehaviorPreset.thisMonth);
    expect(model.from, DateTime(2026, 10, 1));
    await model.setCustomRange(DateTime(2026, 9, 1, 13), DateTime(2026, 9, 15, 8));
    expect((model.from, model.to), (DateTime(2026, 9, 1), DateTime(2026, 9, 15)));
  });

  test('changing the idle cut-off reloads only the carts', () async {
    final model = vm(sample);
    await model.fetch();
    seen.clear();

    expect(await model.setIdle(IdleCutoff.day1), isTrue);

    expect(seen.single.path, endsWith('abandoned-carts'));
    expect(seen.single.queryParameters['idleMinutes'], '1440');
    expect(model.idle, IdleCutoff.day1);
  });

  test('one failing section leaves the others', () async {
    final model = vm((path) => path.endsWith('searches') ? json({'code': 'INTERNAL_ERROR'}, 500) : sample(path));

    expect(await model.fetch(), isTrue);
    expect(model.failedSections, {'Searches'});
    expect(model.overview, isNotNull);
  });

  test('fails when every section fails', () async {
    final model = vm((_) => json({'code': 'INTERNAL_ERROR', 'message': 'Something went wrong on our side.'}, 500));

    expect(await model.fetch(), isFalse);
    expect(model.loadFailed, isTrue);
  });

  test('no tracked visits means no activity', () async {
    final model = vm((path) => path.endsWith('overview') ? json({'sessions': 0}) : json(path.endsWith('carts') ? {'count': 0} : []));
    await model.fetch();
    expect(model.hasActivity, isFalse);
  });

  test('the daily chart fills days without activity with zeros', () {
    final days = DailyActivityChart.filled(
      [BehaviorDay(date: DateTime(2026, 10, 2), visitors: 5)],
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 3),
    );
    expect(days.map((d) => d.visitors), [0, 5, 0]);
  });
}
