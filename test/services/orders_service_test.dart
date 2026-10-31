import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/order_request.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/services/orders_service.dart';

http.Response jsonResponse(Object? body, int status) => http.Response(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

const orderJson = {'orderId': 5, 'status': 'Pending', 'orderItems': []};

void main() {
  late http.Request seen;

  OrdersService serviceReturning(Object? body, [int status = 200]) =>
      OrdersService(ApiClient(
        baseUrl: 'http://api.test/',
        client: MockClient((req) async {
          seen = req;
          return jsonResponse(body, status);
        }),
      ));

  Object? sentBody() => seen.body.isEmpty ? null : jsonDecode(seen.body);

  const request = OrderRequest(
    customerId: 3,
    items: [OrderLineRequest(productId: 1, quantity: 2, unitPrice: 99.5)],
    paymentMethod: 'Cash',
    orderSource: 'Instagram',
    downPayment: 100,
    delivery: 50,
    discount: 10,
  );

  test('list sends the date range and status label', () async {
    final service = serviceReturning([orderJson, orderJson]);

    final orders = await service.list(
      from: DateTime(2026, 9, 1, 23, 59),
      to: DateTime(2026, 10, 24),
      status: OrderStatus.shipped,
    );

    expect(orders, hasLength(2));
    expect(seen.method, 'GET');
    expect(seen.url.path, '/orders');
    expect(seen.url.queryParameters, {'from': '2026-09-01', 'to': '2026-10-24', 'status': 'Shipped'});
  });

  test('list without filters sends no query', () async {
    await serviceReturning([]).list();
    expect(seen.url.toString(), 'http://api.test/orders');
  });

  test('get reads one order', () async {
    final order = await serviceReturning(orderJson).get(5);
    expect(seen.method, 'GET');
    expect(seen.url.path, '/orders/5');
    expect(order.orderId, 5);
    expect(order.status, OrderStatus.pending);
  });

  test('create posts the request with numbers as numbers', () async {
    await serviceReturning(orderJson, 201).create(request);
    expect(seen.method, 'POST');
    expect(seen.url.path, '/orders');
    expect(sentBody(), {
      'customerId': 3,
      'items': [
        {'productId': 1, 'quantity': 2, 'unitPrice': 99.5},
      ],
      'paymentMethod': 'Cash',
      'orderSource': 'Instagram',
      'notes': '',
      'downPayment': 100.0,
      'delivery': 50.0,
      'discount': 10.0,
    });
  });

  test('update puts the request without a bank account', () async {
    await serviceReturning(orderJson).update(5, request);
    expect(seen.method, 'PUT');
    expect(seen.url.path, '/orders/5');
    expect((sentBody() as Map).containsKey('bankAccountId'), isFalse);
  });

  test('changeStatus patches the label and optional bank account', () async {
    final service = serviceReturning(orderJson);

    await service.changeStatus(5, OrderStatus.completed, bankAccountId: 2);
    expect(seen.method, 'PATCH');
    expect(seen.url.path, '/orders/5/status');
    expect(sentBody(), {'status': 'Completed', 'bankAccountId': 2});

    await service.changeStatus(5, OrderStatus.shipped);
    expect(sentBody(), {'status': 'Shipped'});
  });

  test('cancel posts to the cancel endpoint', () async {
    await serviceReturning(orderJson).cancel(5);
    expect(seen.method, 'POST');
    expect(seen.url.path, '/orders/5/cancel');
    expect(sentBody(), isNull);
  });

  test('delete accepts an empty 204', () async {
    await serviceReturning(null, 204).delete(5);
    expect(seen.method, 'DELETE');
    expect(seen.url.path, '/orders/5');
  });

  test('countsByGovernorate reads the stats endpoint', () async {
    final counts = await serviceReturning([
      {'governorate': 'Cairo', 'orderCount': 4},
      {'governorate': null, 'orderCount': '2'},
    ]).countsByGovernorate();

    expect(seen.url.path, '/orders/stats/by-governorate');
    expect(counts.map((c) => (c.governorate, c.count)), [('Cairo', 4), ('-', 2)]);
  });

  test('an ApiError body becomes an ApiException with its message', () async {
    final service = serviceReturning({
      'status': 422,
      'code': 'INSUFFICIENT_STOCK',
      'message': 'Only 1 Lamp left in stock.',
      'details': [],
    }, 422);

    await expectLater(
      service.create(request),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'INSUFFICIENT_STOCK')
          .having((e) => e.message, 'message', 'Only 1 Lamp left in stock.')),
    );
  });

  test('an unexpected body shape is a bad response', () async {
    await expectLater(
      serviceReturning({'orders': []}).list(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiException.codeBadResponse)),
    );
    await expectLater(
      serviceReturning([orderJson]).get(5),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiException.codeBadResponse)),
    );
  });
}
