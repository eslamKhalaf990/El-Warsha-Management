import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/core/validation/validators.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/models/product_variant.dart';
import 'package:warsha_app/services/product_variants_service.dart';
import 'package:warsha_app/services/products_service.dart';

/// Products screen (list, search, add, edit, delete) and the product pickers
/// on the order screens.
class ProductVM extends ChangeNotifier with AsyncViewModel {
  ProductVM(this._service, this._variants);

  final ProductService _service;
  final ProductVariantsService _variants;

  // Same limits as the Products table.
  static const nameMaxLength = 100;
  static const nameArMaxLength = 255;
  static const descriptionMaxLength = 500;
  static const descriptionArMaxLength = 4000;

  static const formFields = [
    'name', 'nameAr', 'description', 'descriptionAr', 'buyingPrice', 'sellingPrice', 'discount', 'quantity',
    'categoryId', 'image',
  ];

  List<ProductModel> _all = [];
  String _query = '';
  String? _deletingId;
  ProductModel? _lastSaved;
  String? _warning;

  /// Products that are not deleted, best sellers first.
  List<ProductModel> get allProducts => List.unmodifiable(_all);

  /// Products matching the Products screen's search box.
  List<ProductModel> get products => search(_query);

  String get query => _query;

  /// Id of the product being deleted, for its spinner.
  String? get deletingId => _deletingId;

  ProductModel? get lastSaved => _lastSaved;

  /// Set when the last save worked but something around it did not (e.g.
  /// some sizes/colors weren't created). Show it instead of the plain success.
  String? get warning => _warning;

  /// Product discount per unit, by product id, for order pricing.
  Map<int, double> get unitDiscounts => {
        for (final p in _all)
          if (int.tryParse(p.id) case final id?) id: double.tryParse(p.discount) ?? 0,
      };

  Future<bool> fetch() => load(() async => _all = await _service.list());

  void setQuery(String query) {
    if (query == _query) return;
    _query = query;
    notify();
  }

  /// Products whose name (English or Arabic) or SKU match [query]. Pure: the
  /// order screens call it with their own search text.
  List<ProductModel> search(String query, {int? limit}) {
    final q = query.trim().toLowerCase();
    Iterable<ProductModel> result = _all;
    if (q.isNotEmpty) {
      result = _all.where((p) =>
          p.name.toLowerCase().contains(q) || p.nameAr.contains(q) || (p.sku?.toLowerCase().contains(q) ?? false));
    }
    return (limit == null ? result : result.take(limit)).toList();
  }

  // ── Validation ──────────────────────────────────────────

  static double? _number(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  /// Checks [form] like the backend does. [hasImage] matters only for new
  /// products; stock is not checked when sizes/colors hold it.
  Map<String, String> validate(ProductForm form, {required bool isNew, bool hasImage = true, bool hasVariants = false}) {
    final errors = Validators.collect({
      'name': () => Validators.firstOf([
            () => Validators.required(form.name, 'Enter the product name.'),
            () => Validators.maxLength(form.name, nameMaxLength, 'Name'),
          ]),
      'nameAr': () => Validators.maxLength(form.nameAr, nameArMaxLength, 'Arabic name'),
      'description': () => Validators.maxLength(form.description, descriptionMaxLength, 'Description'),
      'descriptionAr': () => Validators.maxLength(form.descriptionAr, descriptionArMaxLength, 'Arabic description'),
      'buyingPrice': () => Validators.nonNegativeNumber(form.buyingPrice, 'Buying price', required: true),
      'sellingPrice': () => Validators.nonNegativeNumber(form.sellingPrice, 'Selling price', required: true),
      'discount': () => Validators.nonNegativeNumber(form.discount, 'Discount'),
      'quantity': () {
        if (hasVariants) return null;
        final t = form.quantity.trim();
        if (t.isEmpty) return 'Enter the stock quantity.';
        final n = int.tryParse(t);
        if (n == null) return 'Stock must be a whole number.';
        return n < 0 ? "Stock can't be negative." : null;
      },
      'categoryId': () => form.categoryId == null ? 'Choose a category.' : null,
      'image': () => isNew && !hasImage ? 'Choose a product image.' : null,
    });
    final selling = _number(form.sellingPrice);
    final discount = _number(form.discount) ?? 0;
    if (!errors.containsKey('discount') && selling != null && discount > selling) {
      errors['discount'] = "Discount can't be more than the selling price.";
    }
    return errors;
  }

  /// The backend's ProductRequest for a valid [form].
  static Map<String, dynamic> toRequest(ProductForm form) => {
        'name': form.name.trim(),
        'nameAr': form.nameAr.trim(),
        'description': form.description.trim(),
        'descriptionAr': form.descriptionAr.trim(),
        'buyingPrice': _number(form.buyingPrice),
        'sellingPrice': _number(form.sellingPrice),
        'discount': _number(form.discount) ?? 0,
        'quantity': int.tryParse(form.quantity.trim()) ?? 0,
        'categoryId': form.categoryId,
      };

  // ── CRUD ────────────────────────────────────────────────

  /// Creates the product, then one size × color variant (stock 0) per pick.
  /// When some variants fail the product still counts as saved and
  /// [warning] says what to fix.
  Future<bool> add(
    ProductForm form, {
    required List<int>? image,
    String? imageName,
    List<String> sizes = const [],
    List<String> colors = const [],
  }) async {
    _warning = null;
    final errors = validate(form, isNew: true, hasImage: image != null);
    if (errors.isNotEmpty) return fail(ApiException.validation(errors));
    return run(() async {
      final created = await _service.create(toRequest(form), image: image!, filename: imageName);
      _lastSaved = created;
      _all = [created, ..._all];
      _warning = await _createVariants(int.parse(created.id), sizes, colors);
      if (sizes.isNotEmpty || colors.isNotEmpty) {
        // Stock now lives on the variants: reload to show them
        final fresh = await _service.list();
        _all = fresh;
      }
    });
  }

  Future<String?> _createVariants(int productId, List<String> sizes, List<String> colors) async {
    if (sizes.isEmpty && colors.isEmpty) return null;
    final sizeList = sizes.isEmpty ? <String?>[null] : sizes;
    final colorList = colors.isEmpty ? <String?>[null] : colors;
    try {
      for (final size in sizeList) {
        for (final color in colorList) {
          await _variants.create(productId, ProductVariantRequest(size: size, color: color, quantity: 0));
        }
      }
      return 'Product added. Set the stock of each size/color from Edit product.';
    } on ApiException catch (e) {
      return "Product added, but some sizes/colors weren't saved: ${e.message}";
    }
  }

  /// Saves [form]; [image] replaces the cover only when given.
  Future<bool> update(ProductModel product, ProductForm form, {List<int>? image, String? imageName}) async {
    _warning = null;
    final errors = validate(form, isNew: false, hasVariants: product.hasVariants);
    if (errors.isNotEmpty) return fail(ApiException.validation(errors));
    return run(() async {
      final updated = await _service.update(int.parse(product.id), toRequest(form), image: image, filename: imageName);
      _lastSaved = updated;
      _all = [for (final p in _all) p.id == product.id ? updated : p];
    });
  }

  Future<bool> delete(ProductModel product) async {
    _deletingId = product.id;
    final ok = await run(() async {
      await _service.delete(int.parse(product.id));
      _all = _all.where((p) => p.id != product.id).toList();
    });
    _deletingId = null;
    notify();
    return ok;
  }
}
