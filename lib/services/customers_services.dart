import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/customerModel.dart';

/// Customers API (backend: CustomerController under `/customers`).
/// Every failure surfaces as an [ApiException] from [ApiClient].
class CustomerService {
  CustomerService(this._api);

  final ApiClient _api;

  /// Every customer, newest first.
  Future<List<CustomerModel>> list() async {
    final body = await _api.get('customers');
    if (body is! List) throw ApiException.badResponse(200);
    return body.whereType<Map<String, dynamic>>().map(CustomerModel.fromJson).toList();
  }

  Future<CustomerModel> create(CustomerRequest request) async =>
      _customer(await _api.post('customers', body: request.toJson()));

  Future<CustomerModel> update(int id, CustomerRequest request) async =>
      _customer(await _api.put('customers/$id', body: request.toJson()));

  /// Refused (409) while the customer has orders or other history.
  Future<void> delete(int id) async {
    await _api.delete('customers/$id');
  }

  static CustomerModel _customer(Object? body) {
    if (body is! Map<String, dynamic>) throw ApiException.badResponse(200);
    return CustomerModel.fromJson(body);
  }
}
