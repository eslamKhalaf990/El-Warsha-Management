import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/services/category_service.dart';

void main() {
  late http.Request seen;

  CategoryService serviceReturning(Object? body, [int status = 200]) => CategoryService(ApiClient(
        baseUrl: 'http://api.test/',
        client: MockClient((req) async {
          seen = req;
          return http.Response(body == null ? '' : jsonEncode(body), status,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }),
      ));

  test('list reads product counts and tolerates the old shape', () async {
    final service = serviceReturning([
      {'categoryId': 1, 'name': 'خاتم', 'productCount': 4},
      {'categoryId': 2, 'name': 'Rings'},
    ]);

    final list = await service.list();

    expect(seen.url.toString(), 'http://api.test/category');
    expect(list.map((c) => (c.name, c.productCount)), [('خاتم', 4), ('Rings', 0)]);
  });

  test('create sends trimmed text and drops a blank description', () async {
    final service = serviceReturning({'categoryId': 9, 'name': 'Rings'}, 201);

    final created = await service.create(const CategoryRequest(name: '  Rings ', description: '  '));

    expect(seen.method, 'POST');
    expect(jsonDecode(seen.body), {'name': 'Rings', 'description': null});
    expect(created.categoryId, 9);
  });

  test('update and delete hit the id path', () async {
    await serviceReturning({'categoryId': 3, 'name': 'x'}).update(3, const CategoryRequest(name: 'x'));
    expect((seen.method, seen.url.path), ('PUT', '/category/3'));

    await serviceReturning(null, 204).delete(3);
    expect((seen.method, seen.url.path), ('DELETE', '/category/3'));
  });

  test('a 409 keeps the backend message and field', () async {
    final service = serviceReturning({
      'code': 'CONFLICT',
      'message': '"Rings" still has 3 products. Move them to another category first.',
      'details': [],
    }, 409);

    await expectLater(
      service.delete(1),
      throwsA(isA<ApiException>()
          .having((e) => e.isConflict, 'isConflict', isTrue)
          .having((e) => e.message, 'message', contains('3 products'))),
    );
  });
}
