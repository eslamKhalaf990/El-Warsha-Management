import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/models/product_image.dart';
import 'package:warsha_app/services/product_images_service.dart';

/// The extra images of one product, shown after the cover in the store:
/// upload, pick from the library, reorder and remove. Lives with the edit
/// product page.
class ProductGalleryVM extends ChangeNotifier with AsyncViewModel {
  ProductGalleryVM(this._service, this.productId);

  final ProductImagesService _service;
  final int productId;

  List<ProductImage> _images = [];
  List<String>? _library;

  List<ProductImage> get images => List.unmodifiable(_images);

  /// File names in the shared image library, once [loadLibrary] ran.
  List<String>? get library => _library;

  Future<bool> fetch() => load(() async => _images = await _service.list(productId));

  /// Uploads each file in turn; the ones before a failure stay added.
  Future<bool> upload(List<({List<int> bytes, String name})> files) => run(() async {
        for (final f in files) {
          _images = [..._images, await _service.upload(productId, f.bytes, f.name)];
          notify();
        }
      });

  Future<bool> loadLibrary() => run(() async => _library = await _service.library());

  Future<bool> addFromLibrary(String filename) =>
      run(() async => _images = [..._images, await _service.addFromLibrary(productId, filename)]);

  /// Moves the image at [index] by [by] places (−1 earlier, +1 later).
  Future<bool> move(int index, int by) async {
    final target = index + by;
    if (target < 0 || target >= _images.length) return true;
    final ids = _images.map((i) => i.id).toList();
    ids.insert(target, ids.removeAt(index));
    return run(() async => _images = await _service.reorder(productId, ids));
  }

  Future<bool> remove(ProductImage image) => run(() async {
        await _service.remove(productId, image.id);
        _images = _images.where((i) => i.id != image.id).toList();
      });
}
