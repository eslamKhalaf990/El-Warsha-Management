import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/core/validation/validators.dart';
import 'package:warsha_app/models/product_variant.dart';
import 'package:warsha_app/services/product_variants_service.dart';

/// What the size/color form holds, as typed.
class VariantForm {
  const VariantForm({
    this.size = '',
    this.color = '',
    this.colorAr = '',
    this.colorHex = '',
    this.sku = '',
    this.price = '',
    this.quantity = '',
  });

  final String size;
  final String color;
  final String colorAr;
  final String colorHex;
  final String sku;
  final String price;
  final String quantity;

  static String? _blank(String s) => s.trim().isEmpty ? null : s.trim();

  ProductVariantRequest toRequest() => ProductVariantRequest(
        size: _blank(size),
        color: _blank(color),
        colorAr: _blank(colorAr),
        colorHex: _blank(colorHex)?.toUpperCase(),
        sku: _blank(sku),
        sellingPrice: double.tryParse(price.trim().replaceAll(',', '.')),
        quantity: int.tryParse(quantity.trim()) ?? 0,
      );
}

/// Sizes / colors of one product, each with its own stock. Lives with the
/// edit product page.
class ProductVariantsVM extends ChangeNotifier with AsyncViewModel {
  ProductVariantsVM(this._service, this.productId);

  final ProductVariantsService _service;
  final int productId;

  static const formFields = ['size', 'color', 'colorAr', 'colorHex', 'sku', 'sellingPrice', 'quantity'];

  List<ProductVariant> _variants = [];

  List<ProductVariant> get variants => List.unmodifiable(_variants);

  int get totalStock => _variants.fold(0, (sum, v) => sum + v.quantity);

  Future<bool> fetch() => load(() async => _variants = await _service.list(productId));

  Map<String, String> validate(VariantForm f, {int? editingId}) {
    final errors = Validators.collect({
      'size': () => f.size.trim().isEmpty && f.color.trim().isEmpty ? 'Enter a size, a color or both.' : null,
      'colorHex': () => f.colorHex.trim().isEmpty || RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(f.colorHex.trim())
          ? null
          : 'Use a code like #1A1A1A.',
      'quantity': () {
        final t = f.quantity.trim();
        if (t.isEmpty) return 'Enter the stock.';
        final n = int.tryParse(t);
        if (n == null) return 'Stock must be a whole number.';
        return n < 0 ? "Stock can't be negative." : null;
      },
      'sellingPrice': () => Validators.nonNegativeNumber(f.price, 'Price'),
    });
    if (!errors.containsKey('size')) {
      String key(String? s) => (s ?? '').trim().toLowerCase();
      final clash = _variants.where(
          (v) => v.id != editingId && key(v.size) == key(f.size) && key(v.color) == key(f.color));
      if (clash.isNotEmpty) errors['size'] = '${clash.first.label} already exists.';
    }
    return errors;
  }

  /// Adds a size/color, or updates [editing].
  Future<bool> save(VariantForm form, {ProductVariant? editing}) async {
    final errors = validate(form, editingId: editing?.id);
    if (errors.isNotEmpty) return fail(ApiException.validation(errors));
    var hex = form.colorHex.trim();
    if (hex.isNotEmpty && !hex.startsWith('#')) hex = '#$hex';
    final request = VariantForm(
      size: form.size,
      color: form.color,
      colorAr: form.colorAr,
      colorHex: hex,
      sku: form.sku,
      price: form.price,
      quantity: form.quantity,
    ).toRequest();
    return run(() async {
      if (editing == null) {
        _variants = [..._variants, await _service.create(productId, request)];
      } else {
        final updated = await _service.update(productId, editing.id, request);
        _variants = [for (final v in _variants) v.id == editing.id ? updated : v];
      }
    });
  }

  Future<bool> delete(ProductVariant variant) => run(() async {
        await _service.delete(productId, variant.id);
        _variants = _variants.where((v) => v.id != variant.id).toList();
      });
}
