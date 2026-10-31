import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/services/analytics_service.dart';
import 'package:warsha_app/view_models/analytics_v_m.dart';

void main() {
  final seen = <Uri>[];

  AnalyticsVM vm(http.Response Function(String path) answer) => AnalyticsVM(
        AnalyticsService(ApiClient(
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
        'period': {'from': '2025-11-01', 'to': '2026-10-31', 'previousFrom': '2024-11-01', 'previousTo': '2025-10-31', 'days': 365},
        'current': {'orders': 300, 'netSales': 100000.5, 'grossMargin': 0.67},
        'previous': {'orders': 200, 'netSales': 80000},
      });
    }
    if (path.endsWith('channels')) return json([{'channel': 'TikTok', 'orders': 187, 'netSales': 50000, 'share': 0.5}]);
    if (path.endsWith('regions')) return json([]);
    if (path.endsWith('trend')) return json({'granularity': 'month', 'points': [{'start': '2025-11-01', 'orders': 45, 'netSales': 9000}]});
    return json({});
  }

  setUp(seen.clear);

  test('loads every section for the last 12 months by default', () async {
    final model = vm(sample);

    expect(await model.fetch(), isTrue);
    expect(model.failedSections, isEmpty);
    expect(model.overview!.current.orders, 300);
    expect(model.overview!.previous!.netSales, 80000);
    expect(model.channels!.single.channel, 'TikTok');
    expect(model.trend!.points.single.start, DateTime(2025, 11, 1));
    expect(seen, hasLength(7));
    expect(seen.first.queryParameters, {'from': '2025-11-01', 'to': '2026-10-31'});
  });

  test('presets turn into day ranges; all time sends no start', () async {
    final model = vm(sample);

    await model.setPreset(RangePreset.thisMonth);
    expect(seen.last.queryParameters, {'from': '2026-10-01', 'to': '2026-10-31'});

    await model.setPreset(RangePreset.last30);
    expect(seen.last.queryParameters['from'], '2026-10-02');

    await model.setPreset(RangePreset.allTime);
    expect(seen.last.queryParameters, {'to': '2026-10-31'});

    await model.setCustomRange(DateTime(2026, 1, 1, 9), DateTime(2026, 2, 28, 18));
    expect(model.preset, RangePreset.custom);
    expect(seen.last.queryParameters, {'from': '2026-01-01', 'to': '2026-02-28'});
  });

  test('one failing section leaves the others and is named for retry', () async {
    final model = vm((path) => path.endsWith('products') ? json({'code': 'INTERNAL_ERROR', 'message': 'boom'}, 500) : sample(path));

    expect(await model.fetch(), isTrue);
    expect(model.failedSections, {'Products'});
    expect(model.overview, isNotNull);
    expect(model.loadFailed, isFalse);
  });

  test('when every section fails the dashboard shows the error', () async {
    final model = vm((_) => json({'code': 'INTERNAL_ERROR', 'message': 'Something went wrong on our side.'}, 500));

    expect(await model.fetch(), isFalse);
    expect(model.loadFailed, isTrue);
    expect(model.errorMessage, 'Something went wrong on our side.');
  });

  test('change compares with the previous period', () {
    expect(AnalyticsVM.change(120, 100), closeTo(0.2, 1e-9));
    expect(AnalyticsVM.change(80, 100), closeTo(-0.2, 1e-9));
    expect(AnalyticsVM.change(5, 0), isNull);
    expect(AnalyticsVM.change(5, null), isNull);
  });
}
