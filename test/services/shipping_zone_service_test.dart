import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/models/shipping_zone.dart';
import 'package:warsha_app/services/shipping_zone_service.dart';

void main() {
  late http.Request seen;

  ShippingZoneService serviceReturning(Object? body, [int status = 200]) => ShippingZoneService(ApiClient(
        baseUrl: 'http://api.test/',
        client: MockClient((req) async {
          seen = req;
          return http.Response(body == null ? '' : jsonEncode(body), status,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }),
      ));

  const zoneJson = {'id': 5, 'cityName': 'أسوان', 'shippingFee': 150.5, 'isActive': true};

  test('update sends the whole zone as JSON', () async {
    final zone = await serviceReturning(zoneJson)
        .update(5, const ShippingZoneRequest(cityName: ' أسوان ', shippingFee: 150.5, isActive: false));

    expect((seen.method, seen.url.path), ('PUT', '/shipping/5'));
    expect(jsonDecode(seen.body), {'cityName': 'أسوان', 'shippingFee': 150.5, 'isActive': false});
    expect(zone.priceLabel, '150.50 EGP');
  });

  test('list and delete', () async {
    expect(await serviceReturning([zoneJson]).list(), hasLength(1));
    await serviceReturning(null, 204).delete(5);
    expect((seen.method, seen.url.path), ('DELETE', '/shipping/5'));
  });
}
