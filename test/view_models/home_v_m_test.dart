import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/services/home_service.dart';
import 'package:warsha_app/view_models/home_v_m.dart';

void main() {
  HomeVM vm(http.Response Function(String path) answer) => HomeVM(HomeService(ApiClient(
        baseUrl: 'http://api.test/',
        client: MockClient((req) async => answer(req.url.path)),
      )));

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

  test('one failing section leaves the others and is named for retry', () async {
    final model = vm((path) {
      if (path.endsWith('average-basket-size')) return json({'average': 412.5});
      if (path.endsWith('revenue-by-source')) return json({'code': 'INTERNAL_ERROR', 'message': 'boom'}, 500);
      if (path.endsWith('revenueSummary')) return json({});
      return json([]);
    });

    expect(await model.fetch(), isTrue);
    expect(model.averageBasketSize, 412.5);
    expect(model.failedSections, {'Revenue by source'});
    expect(model.loadFailed, isFalse);
  });

  test('when every section fails the dashboard shows the error', () async {
    final model = vm((_) => json({'code': 'INTERNAL_ERROR', 'message': 'Something went wrong on our side.'}, 500));

    expect(await model.fetch(), isFalse);
    expect(model.loadFailed, isTrue);
    expect(model.errorMessage, 'Something went wrong on our side.');
  });
}
