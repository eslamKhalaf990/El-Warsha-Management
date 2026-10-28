import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/product_variant.dart';
import 'package:warsha_app/services/product_variants_service.dart';

/// Opens the sizes/colors editor for a product. Resolves to the product's
/// variants as they are when the dialog closes.
Future<List<ProductVariant>?> showProductVariantsEditor(
    BuildContext context, {required int productId, required String productName}) {
  return showDialog<List<ProductVariant>>(
    context: context,
    builder: (_) => ProductVariantsEditor(productId: productId, productName: productName),
  );
}

class ProductVariantsEditor extends StatefulWidget {
  const ProductVariantsEditor({super.key, required this.productId, required this.productName});

  final int productId;
  final String productName;

  @override
  State<ProductVariantsEditor> createState() => _ProductVariantsEditorState();
}

class _ProductVariantsEditorState extends State<ProductVariantsEditor> {
  List<ProductVariant> _variants = [];
  bool _loading = true;
  String? _error;

  ProductVariantsService get _service => context.read<ProductVariantsService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _variants = await _service.list(widget.productId);
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit([ProductVariant? variant]) async {
    final request = await showDialog<ProductVariantRequest>(
      context: context,
      builder: (_) => _VariantForm(variant: variant),
    );
    if (request == null) return;
    await _run(() => variant == null
        ? _service.create(widget.productId, request)
        : _service.update(widget.productId, variant.id, request));
  }

  Future<void> _delete(ProductVariant variant) =>
      _run(() => _service.delete(widget.productId, variant.id));

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _error = null);
    try {
      await action();
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _variants.fold<int>(0, (sum, v) => sum + v.quantity);
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text("Sizes & colors · ${widget.productName}"),
      content: SizedBox(
        width: 560,
        child: _loading
            ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  if (_variants.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("No sizes or colors yet. The product uses its own stock.",
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _variants.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final v = _variants[i];
                          return ListTile(
                            leading: _Swatch(hex: v.colorHex),
                            title: Text(v.label),
                            subtitle: Text([
                              "Stock: ${v.quantity}",
                              v.sellingPrice != null ? "${v.sellingPrice} EGP" : "Product price",
                              if (v.sku != null) "SKU ${v.sku}",
                            ].join(" · ")),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Iconsax.edit, size: 18), onPressed: () => _edit(v)),
                                IconButton(
                                  icon: const Icon(Iconsax.trash, size: 18, color: Colors.redAccent),
                                  onPressed: () => _delete(v),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  if (_variants.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text("Total stock: $total", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _loading ? null : () => _edit(),
          icon: const Icon(Iconsax.add_circle),
          label: const Text("Add size/color"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _variants),
          child: const Text("Done"),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({this.hex});
  final String? hex;

  @override
  Widget build(BuildContext context) {
    final value = hex == null ? null : int.tryParse(hex!.replaceFirst('#', ''), radix: 16);
    final color = value == null ? null : Color(hex!.length == 7 ? 0xFF000000 | value : value);
    return CircleAvatar(
      radius: 12,
      backgroundColor: color ?? Colors.grey.shade200,
      child: color == null ? const Icon(Iconsax.size, size: 14, color: Colors.grey) : null,
    );
  }
}

/// Add/edit form for one size/color. Pops a [ProductVariantRequest].
class _VariantForm extends StatefulWidget {
  const _VariantForm({this.variant});
  final ProductVariant? variant;

  @override
  State<_VariantForm> createState() => _VariantFormState();
}

class _VariantFormState extends State<_VariantForm> {
  final _formKey = GlobalKey<FormState>();
  late final _size = TextEditingController(text: widget.variant?.size);
  late final _color = TextEditingController(text: widget.variant?.color);
  late final _colorAr = TextEditingController(text: widget.variant?.colorAr);
  late final _colorHex = TextEditingController(text: widget.variant?.colorHex);
  late final _sku = TextEditingController(text: widget.variant?.sku);
  late final _price = TextEditingController(text: widget.variant?.sellingPrice?.toString());
  late final _quantity = TextEditingController(text: (widget.variant?.quantity ?? 0).toString());

  @override
  void dispose() {
    for (final c in [_size, _color, _colorAr, _colorHex, _sku, _price, _quantity]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ProductVariantRequest(
        size: _text(_size),
        color: _text(_color),
        colorAr: _text(_colorAr),
        colorHex: _text(_colorHex),
        sku: _text(_sku),
        sellingPrice: double.tryParse(_price.text.trim()),
        quantity: int.parse(_quantity.text.trim()),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {String? hint, TextDirection? direction, TextInputType? keyboard, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        textDirection: direction,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(widget.variant == null ? "Add size/color" : "Edit ${widget.variant!.label}"),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(
                    child: _field(_size, "Size", hint: "M, 42, 30x40", validator: (_) {
                      return _text(_size) == null && _text(_color) == null ? "Enter a size or a color" : null;
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_color, "Color", hint: "Black")),
                ]),
                Row(children: [
                  Expanded(child: _field(_colorAr, "Color (Arabic)", hint: "أسود", direction: TextDirection.rtl)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(_colorHex, "Color code", hint: "#1A1A1A", validator: (v) {
                      final t = v?.trim() ?? '';
                      return t.isEmpty || RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(t)
                          ? null
                          : "Use #RRGGBB";
                    }),
                  ),
                ]),
                Row(children: [
                  Expanded(
                    child: _field(_quantity, "Stock *", keyboard: TextInputType.number, validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      return n == null || n < 0 ? "Enter 0 or more" : null;
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(_price, "Price (optional)",
                        hint: "Product price", keyboard: TextInputType.number, validator: (v) {
                      final t = v?.trim() ?? '';
                      final n = double.tryParse(t);
                      return t.isEmpty || (n != null && n >= 0) ? null : "Invalid price";
                    }),
                  ),
                ]),
                _field(_sku, "SKU (optional)"),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: _save, child: const Text("Save")),
      ],
    );
  }
}
