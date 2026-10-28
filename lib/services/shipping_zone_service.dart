import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/shipping_zone.dart';

/// Delivery prices API (backend: ShippingZoneController under `/shipping`).
/// Every failure surfaces as an [ApiException] from [ApiClient].
class ShippingZoneService {
  ShippingZoneService(this._api);

  final ApiClient _api;

  /// Every zone, active and inactive.
  Future<List<ShippingZone>> list() async {
    final body = await _api.get('shipping');
    if (body is! List) throw ApiException.badResponse(200);
    return body.whereType<Map<String, dynamic>>().map(ShippingZone.fromJson).toList();
  }

  Future<ShippingZone> create(ShippingZoneRequest request) async =>
      _zone(await _api.post('shipping', body: request.toJson()));

  Future<ShippingZone> update(int id, ShippingZoneRequest request) async =>
      _zone(await _api.put('shipping/$id', body: request.toJson()));

  Future<void> delete(int id) async {
    await _api.delete('shipping/$id');
  }

  static ShippingZone _zone(Object? body) {
    if (body is! Map<String, dynamic>) throw ApiException.badResponse(200);
    return ShippingZone.fromJson(body);
  }
}
