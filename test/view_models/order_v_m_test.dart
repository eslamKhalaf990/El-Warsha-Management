import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/order_request.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/services/orders_service.dart';
import 'package:warsha_app/view_models/order_v_m.dart';

Map<String, dynamic> order(int id, String status) => {
      'orderId': id,
      'status': status,
      'allowedNextStatuses': [],
      'orderItems': [],
    };

http.Response json(Object? body, [int status = 200]) => http.Response(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

const request = OrderRequest(
  customerId: 1,
  items: [OrderLineRequest(productId: 1, quantity: 1)],
  paymentMethod: 'cash',
  orderSource: 'facebook',
);

void main() {
  late List<http.Request> calls;
  late Map<String, http.Response Function(http.Request)> routes;

  OrderVM vm() => OrderVM(OrdersService(ApiClient(
        baseUrl: 'http://api.test/',
        client: MockClient((req) async {
          calls.add(req);
          final handler = routes['${req.method} ${req.url.path}'];
          return handler == null ? json({'code': 'NOT_FOUND'}, 404) : handler(req);
        }),
      )));

  setUp(() {
    calls = [];
    routes = {
      'GET /orders': (_) => json([order(1, 'Pending'), order(2, 'Processing')]),
    };
  });

  Future<OrderVM> loaded() async {
    final model = vm();
    await model.fetchOrders();
    return model;
  }

  test('fetchOrders loads the last 45 days', () async {
    final model = await loaded();

    expect(model.state, ViewState.idle);
    expect(model.orders.map((o) => o.orderId), [1, 2]);
    expect(calls.single.url.queryParameters.keys, containsAll(['from', 'to']));
  });

  test('fetchOrders failure sets the error state and message', () async {
    routes['GET /orders'] = (_) => json({'code': 'INTERNAL_ERROR', 'message': 'Database is down.'}, 500);
    final model = await loaded();

    expect(model.state, ViewState.error);
    expect(model.errorMessage, 'Database is down.');
    expect(model.lastError?.code, 'INTERNAL_ERROR');
  });

  test('addOrder puts the created order first without refetching', () async {
    routes['POST /orders'] = (_) => json(order(9, 'Pending'), 201);
    final model = await loaded();

    final created = await model.addOrder(request);

    expect(created?.orderId, 9);
    expect(model.orders.first.orderId, 9);
    expect(model.isSaving, isFalse);
    expect(calls.where((c) => c.method == 'GET'), hasLength(1));
  });

  test('status change replaces the order with the server response', () async {
    routes['PATCH /orders/2/status'] = (_) => json(order(2, 'Completed'));
    final model = await loaded();

    final ok = await model.updateOrderStatus(
        orderId: 2, status: OrderStatus.completed, bankAccountId: 4);

    expect(ok, isTrue);
    expect(model.orders.last.status, OrderStatus.completed);
    expect(jsonDecode(calls.last.body), {'status': 'Completed', 'bankAccountId': 4});
  });

  test('cancelling uses the cancel endpoint', () async {
    routes['POST /orders/1/cancel'] = (_) => json(order(1, 'Cancelled'));
    final model = await loaded();

    expect(await model.updateOrderStatus(orderId: 1, status: OrderStatus.cancelled), isTrue);
    expect(model.orders.first.status, OrderStatus.cancelled);
  });

  test('a rejected status change keeps the order and exposes the reason', () async {
    routes['PATCH /orders/1/status'] = (_) => json({
          'code': 'INVALID_STATUS_TRANSITION',
          'message': "A Pending order can't move to Completed.",
        }, 422);
    final model = await loaded();

    final ok = await model.updateOrderStatus(orderId: 1, status: OrderStatus.completed);

    expect(ok, isFalse);
    expect(model.orders.first.status, OrderStatus.pending);
    expect(model.errorMessage, "A Pending order can't move to Completed.");
    expect(model.isSaving, isFalse);
  });

  test('validation failures are available per field', () async {
    routes['PUT /orders/1'] = (_) => json({
          'code': 'VALIDATION_FAILED',
          'message': 'Some fields are missing or invalid.',
          'details': [
            {'field': 'discount', 'message': "Discount can't be negative."},
            {'field': 'items[0].quantity', 'message': 'Quantity must be at least 1.'},
          ],
        }, 400);
    final model = await loaded();

    expect(await model.updateOrder(1, request), isFalse);
    expect(model.fieldError('discount'), "Discount can't be negative.");
    expect(model.fieldError('items[0].quantity'), 'Quantity must be at least 1.');
    expect(model.fieldError('delivery'), isNull);

    model.clearError();
    expect(model.fieldError('discount'), isNull);
    expect(model.lastError, isNull);
  });

  test('non-validation errors have no field errors', () async {
    routes['PUT /orders/1'] = (_) => json({
          'code': 'INSUFFICIENT_STOCK',
          'message': 'Only 1 Lamp left in stock.',
          'details': [
            {'field': 'items[0].quantity', 'message': 'Only 1 left.'},
          ],
        }, 409);
    final model = await loaded();

    expect(await model.updateOrder(1, request), isFalse);
    expect(model.lastError?.code, 'INSUFFICIENT_STOCK');
    expect(model.fieldError('items[0].quantity'), isNull);
  });

  test('deleteOrder removes the order; a network error keeps it', () async {
    routes['DELETE /orders/1'] = (_) => json(null, 204);
    final model = await loaded();

    expect(await model.deleteOrder(1), isTrue);
    expect(model.orders.map((o) => o.orderId), [2]);

    routes['DELETE /orders/2'] = (_) => throw http.ClientException('offline');
    expect(await model.deleteOrder(2), isFalse);
    expect(model.orders.map((o) => o.orderId), [2]);
    expect(model.lastError?.code, ApiException.codeNetwork);
  });

  test('a successful save clears the previous error', () async {
    routes['PUT /orders/1'] = (_) => json({'code': 'CONFLICT'}, 409);
    final model = await loaded();
    await model.updateOrder(1, request);
    expect(model.lastError, isNotNull);

    routes['PUT /orders/1'] = (_) => json(order(1, 'Pending'));
    await model.updateOrder(1, request);
    expect(model.lastError, isNull);
    expect(model.errorMessage, isEmpty);
  });
}
