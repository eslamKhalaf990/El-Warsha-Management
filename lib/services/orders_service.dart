import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/orderModel.dart';
import 'package:warsha_app/models/order_governorate_count.dart';
import 'package:warsha_app/models/order_request.dart';
import 'package:warsha_app/models/order_status.dart';

/// ERP orders API (backend: OrderController under `/orders`).
/// Every failure surfaces as an [ApiException] from [ApiClient].
class OrdersService {
  OrdersService(this._api);

  final ApiClient _api;

  /// Orders placed between [from] and [to] (inclusive dates), optionally
  /// filtered by [status].
  Future<List<OrderModel>> list({DateTime? from, DateTime? to, OrderStatus? status}) async {
    final body = await _api.get('orders', query: {
      if (from != null) 'from': _date(from),
      if (to != null) 'to': _date(to),
      if (status != null) 'status': status.label,
    });
    return _list(body).map(OrderModel.fromJson).toList();
  }

  Future<OrderModel> get(int id) async => _order(await _api.get('orders/$id'));

  Future<OrderModel> create(OrderRequest request) async =>
      _order(await _api.post('orders', body: request.toJson()));

  Future<OrderModel> update(int id, OrderRequest request) async =>
      _order(await _api.put('orders/$id', body: request.toJson()));

  /// Moves the order to [status]. Completing an order needs the
  /// [bankAccountId] that receives the remaining amount.
  Future<OrderModel> changeStatus(int id, OrderStatus status, {int? bankAccountId}) async =>
      _order(await _api.patch('orders/$id/status', body: {
        'status': status.label,
        if (bankAccountId != null) 'bankAccountId': bankAccountId,
      }));

  /// Cancels the order: stock goes back and the down payment is refunded.
  Future<OrderModel> cancel(int id) async => _order(await _api.post('orders/$id/cancel'));

  Future<void> delete(int id) async {
    await _api.delete('orders/$id');
  }

  Future<List<GovernorateCountPerOrder>> countsByGovernorate() async {
    final body = await _api.get('orders/stats/by-governorate');
    return _list(body).map(GovernorateCountPerOrder.fromJson).toList();
  }

  static String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static List<Map<String, dynamic>> _list(Object? body) {
    if (body is! List) throw ApiException.badResponse(200);
    return body.whereType<Map<String, dynamic>>().toList();
  }

  static OrderModel _order(Object? body) {
    if (body is! Map<String, dynamic>) throw ApiException.badResponse(200);
    return OrderModel.fromJson(body);
  }
}
