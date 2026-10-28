import 'dart:convert';

import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/product_model.dart';

/// Products API (backend: ProductController under `/products`). Sizes/colors
/// and the gallery have their own services. Every failure surfaces as an
/// [ApiException] from [ApiClient].
class ProductService {
  ProductService(this._api);

  final ApiClient _api;

  /// Products that are not deleted, best sellers first.
  Future<List<ProductModel>> list() async {
    final body = await _api.get('products');
    if (body is! List) throw ApiException.badResponse(200);
    return body.whereType<Map<String, dynamic>>().map(ProductModel.fromJson).toList();
  }

  /// [product] is the backend's ProductRequest; the cover [image] is required.
  Future<ProductModel> create(Map<String, dynamic> product, {required List<int> image, String? filename}) async =>
      _product(await _api.multipart('POST', 'products',
          fields: {'product': jsonEncode(product)}, fileField: 'image', bytes: image, filename: filename));

  /// Sends [image] only when it should replace the cover.
  Future<ProductModel> update(int id, Map<String, dynamic> product, {List<int>? image, String? filename}) async =>
      _product(await _api.multipart('PUT', 'products/$id',
          fields: {'product': jsonEncode(product)}, fileField: 'image', bytes: image, filename: filename));

  /// Soft delete: order history keeps the product.
  Future<void> delete(int id) async {
    await _api.delete('products/$id');
  }

  static ProductModel _product(Object? body) {
    if (body is! Map<String, dynamic>) throw ApiException.badResponse(200);
    return ProductModel.fromJson(body);
  }
}
