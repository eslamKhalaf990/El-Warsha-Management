import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/vendor.dart';

/// Suppliers API (backend: VendorController under `/vendors`).
/// Every failure surfaces as an [ApiException] from [ApiClient].
class VendorService {
  VendorService(this._api);

  final ApiClient _api;

  /// Active vendors; archived ones too when [includeArchived] is set.
  Future<List<Vendor>> list({bool includeArchived = false}) async {
    final body = await _api.get('vendors', query: {if (includeArchived) 'includeArchived': 'true'});
    if (body is! List) throw ApiException.badResponse(200);
    return body.whereType<Map<String, dynamic>>().map(Vendor.fromJson).toList();
  }

  Future<Vendor> create(VendorRequest request) async => _vendor(await _api.post('vendors', body: request.toJson()));

  Future<Vendor> update(int id, VendorRequest request) async =>
      _vendor(await _api.put('vendors/$id', body: request.toJson()));

  /// Archives the vendor; it disappears from [list] but its record is kept.
  Future<void> archive(int id) async {
    await _api.delete('vendors/$id');
  }

  static Vendor _vendor(Object? body) {
    if (body is! Map<String, dynamic>) throw ApiException.badResponse(200);
    return Vendor.fromJson(body);
  }
}
