import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/models/json_read.dart';
import 'package:warsha_app/models/product_variant.dart';

/// Sizes/colors of a product (backend: ProductController under `/products/{id}/variants`).
/// Every failure surfaces as an ApiException from [ApiClient].
class ProductVariantsService {
  ProductVariantsService(this._api);

  final ApiClient _api;

  Future<List<ProductVariant>> list(int productId) async =>
      readList(await _api.get('products/$productId/variants')).map(ProductVariant.fromJson).toList();

  Future<ProductVariant> create(int productId, ProductVariantRequest request) async =>
      ProductVariant.fromJson(await _api.post('products/$productId/variants', body: request.toJson()));

  Future<ProductVariant> update(int productId, int variantId, ProductVariantRequest request) async =>
      ProductVariant.fromJson(await _api.put('products/$productId/variants/$variantId', body: request.toJson()));

  Future<void> delete(int productId, int variantId) =>
      _api.delete('products/$productId/variants/$variantId');
}
