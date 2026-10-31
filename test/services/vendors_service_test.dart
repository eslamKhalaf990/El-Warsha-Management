import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/models/vendor.dart';
import 'package:warsha_app/services/vendors_service.dart';

void main() {
  late http.Request seen;

  VendorService serviceReturning(Object? body, [int status = 200]) => VendorService(ApiClient(
        baseUrl: 'http://api.test/',
        client: MockClient((req) async {
          seen = req;
          return http.Response(body == null ? '' : jsonEncode(body), status,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }),
      ));

  test('list parses vendors; a null isActive counts as active', () async {
    final service = serviceReturning([
      {'vendorId': 1, 'name': 'Silver Co', 'isActive': null, 'createdAt': '2026-10-01T10:00:00'},
    ]);

    final list = await service.list();

    expect(seen.url.toString(), 'http://api.test/vendors');
    expect(list.single.isActive, isTrue);
    expect(list.single.createdAt, DateTime(2026, 10, 1, 10));
  });

  test('list can include archived vendors', () async {
    await serviceReturning([]).list(includeArchived: true);
    expect(seen.url.queryParameters, {'includeArchived': 'true'});
  });

  test('create sends blank fields as null', () async {
    await serviceReturning({'vendorId': 2, 'name': 'Silver Co'}, 201)
        .create(const VendorRequest(name: ' Silver Co ', phone: ' ', email: 'a@b.co'));

    expect(jsonDecode(seen.body), {
      'name': 'Silver Co',
      'phone': null,
      'email': 'a@b.co',
      'address': null,
      'taxNumber': null,
      'contactPerson': null,
      'notes': null,
    });
  });

  test('update and archive hit the id path', () async {
    await serviceReturning({'vendorId': 2, 'name': 'x'}).update(2, const VendorRequest(name: 'x'));
    expect((seen.method, seen.url.path), ('PUT', '/vendors/2'));

    await serviceReturning(null, 204).archive(2);
    expect((seen.method, seen.url.path), ('DELETE', '/vendors/2'));
  });
}
