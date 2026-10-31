import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/models/json_read.dart';
import 'package:warsha_app/models/product_image.dart';

/// Extra gallery images of a product (backend: ProductController under `/products/{id}/images`).
/// Every failure surfaces as an ApiException from [ApiClient].
class ProductImagesService {
  ProductImagesService(this._api);

  final ApiClient _api;

  Future<List<ProductImage>> list(int productId) async =>
      readList(await _api.get('products/$productId/images')).map(ProductImage.fromJson).toList();

  /// Uploads a new file to the image library and adds it to the gallery.
  Future<ProductImage> upload(int productId, List<int> bytes, String filename) async =>
      ProductImage.fromJson(await _api.postFile('products/$productId/images/upload',
          field: 'image', bytes: bytes, filename: filename));

  /// Adds an image that is already in the library.
  Future<ProductImage> addFromLibrary(int productId, String filename) async =>
      ProductImage.fromJson(await _api.post('products/$productId/images', body: {'filename': filename}));

  Future<List<ProductImage>> reorder(int productId, List<int> imageIds) async =>
      readList(await _api.put('products/$productId/images/order', body: {'imageIds': imageIds}))
          .map(ProductImage.fromJson)
          .toList();

  Future<void> remove(int productId, int imageId) => _api.delete('products/$productId/images/$imageId');

  /// File names of every image in the library, for the "choose an image" picker.
  Future<List<String>> library() async =>
      readList(await _api.get('products/images')).map((m) => readString(m['filename'])).toList();
}
