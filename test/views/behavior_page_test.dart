import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/theme/app_theme.dart';
import 'package:warsha_app/services/behavior_service.dart';
import 'package:warsha_app/view_models/behavior_v_m.dart';
import 'package:warsha_app/views/behavior/behavior_page.dart';

http.Response _json(Object body) =>
    http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json; charset=utf-8'});

http.Response _answer(String path) {
  if (path.endsWith('overview')) {
    return _json({
      'range': {'from': '2026-10-02', 'to': '2026-10-31', 'days': 30},
      'visitors': 120,
      'newVisitors': 70,
      'sessions': 150,
      'pageViews': 600,
      'productViews': 400,
      'cartAdds': 80,
      'orders': 10,
      'orderValue': 4200.5,
      'funnel': {'sessions': 150, 'viewedProduct': 100, 'addedToCart': 40, 'startedCheckout': 25, 'ordered': 10},
      'devices': [{'device': 'MOBILE', 'sessions': 120, 'share': 0.8}, {'device': 'DESKTOP', 'sessions': 30, 'share': 0.2}],
      'days': [{'date': '2026-10-30', 'visitors': 50, 'orders': 5}],
    });
  }
  if (path.endsWith('abandoned-carts')) {
    return _json({
      'count': 1,
      'value': 430,
      'carts': [
        {
          'visitorId': 'v1',
          'customerId': 44,
          'customerName': 'A customer with a rather long name that should not overflow',
          'phone': '01000000000',
          'itemCount': 3,
          'value': 430,
          'lastActivity': '2026-10-31T09:15:00',
          'source': 'Facebook',
          'device': 'MOBILE',
          'items': [{'productId': 1, 'name': 'Mug', 'variant': 'L / Black', 'quantity': 2}],
        },
      ],
    });
  }
  if (path.endsWith('products')) {
    return _json([{'productId': 2, 'name': 'Shirt', 'views': 50, 'viewers': 30, 'cartAdds': 5, 'viewToCartRate': 0.1}]);
  }
  if (path.endsWith('searches')) {
    return _json({'total': 5, 'top': [{'query': 'mug', 'searches': 5}], 'withoutResults': []});
  }
  if (path.endsWith('vouchers')) {
    return _json([{'code': 'RAMADAN10', 'tries': 4, 'applied': 3, 'rejected': 1, 'rejections': {'EXPIRED': 1}}]);
  }
  return _json([{'source': 'Facebook', 'visitors': 40, 'orders': 5, 'conversionRate': 0.1}]);
}

void main() {
  for (final (name, size) in [('desktop', const Size(1440, 3000)), ('phone', const Size(390, 6000))]) {
    testWidgets('renders every section on $name without layout errors', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = BehaviorVM(
        BehaviorService(ApiClient(baseUrl: 'http://api.test/', client: MockClient((req) async => _answer(req.url.path)))),
        today: () => DateTime(2026, 10, 31, 12),
      );
      await vm.fetch();

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: ChangeNotifierProvider.value(value: vm, child: const BehaviorPage()),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.text('Customer behavior'), findsOneWidget);
      expect(find.text('From visit to order'), findsOneWidget);
      expect(find.text('Carts left without ordering'), findsOneWidget);
      expect(find.text('Shirt'), findsOneWidget);
      expect(find.text('RAMADAN10'), findsOneWidget);
    });
  }
}
