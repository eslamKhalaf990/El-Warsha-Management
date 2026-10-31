import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/product_variant.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/product_variants_v_m.dart';

/// Sizes / colors of the product being edited, each with its own stock.
class VariantsSection extends StatelessWidget {
  const VariantsSection({super.key});

  Future<void> _delete(BuildContext context, ProductVariant v) async {
    final vm = context.read<ProductVariantsVM>();
    final confirmed = await confirmAction(
      context,
      title: 'Remove ${v.label}?',
      message: 'Customers will no longer be able to order ${v.label}.',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await vm.delete(v);
    if (!context.mounted) return;
    reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: '${v.label} removed.');
    if (ok) context.read<ProductVM>().fetch();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductVariantsVM>();
    final variants = vm.variants;

    return FormSection(
      title: 'Sizes & colors',
      subtitle: variants.isEmpty ? 'Optional. Each option gets its own stock.' : 'Total stock: ${vm.totalStock}',
      icon: Iconsax.color_swatch_copy,
      trailing: AppButton.secondary(
        label: 'Add option',
        icon: Iconsax.add_copy,
        compact: true,
        onPressed: vm.hasLoaded ? () => openVariantForm(context) : null,
      ),
      children: [
        if (vm.loadFailed)
          InlineBanner(message: vm.errorMessage!, tone: Tone.error, actionLabel: 'Retry', onAction: vm.fetch)
        else if (!vm.hasLoaded)
          const LinearProgressIndicator(minHeight: 2)
        else if (variants.isEmpty)
          const AppText.bodySmall('No options. The product uses the stock above.', color: AppColors.muted)
        else
          Column(
            children: [
              for (final v in variants)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _Swatch(hex: v.colorHex),
                  title: Text(v.label),
                  subtitle: Text([
                    v.sellingPrice != null ? Fmt.money(v.sellingPrice) : 'Product price',
                    if (v.sku != null) 'SKU ${v.sku}',
                  ].join(' · ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusPill(label: '${v.quantity} pcs', tone: v.inStock ? Tone.success : Tone.error),
                      RowActions([
                        RowAction(label: 'Edit', icon: Iconsax.edit_2_copy, onPressed: () => openVariantForm(context, variant: v)),
                        RowAction(label: 'Remove', icon: Iconsax.trash_copy, destructive: true, onPressed: () => _delete(context, v)),
                      ]),
                    ],
                  ),
                ),
            ],
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
    final value = int.tryParse((hex ?? '').replaceFirst('#', ''), radix: 16);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: value == null ? AppColors.blush : Color(0xFF000000 | value),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line),
      ),
      child: value == null ? const Icon(Iconsax.ruler_copy, size: 16, color: AppColors.muted) : null,
    );
  }
}

/// Add / edit one size or color. The view model is handed over because the
/// dialog's route can't see the page's providers.
Future<void> openVariantForm(BuildContext context, {ProductVariant? variant}) {
  final vm = context.read<ProductVariantsVM>()..clearError();
  final products = context.read<ProductVM>();
  return showDialog(
    context: context,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: vm),
        ChangeNotifierProvider(
          create: (_) => FormDraft(text: {
            'size': variant?.size,
            'color': variant?.color,
            'colorAr': variant?.colorAr,
            'colorHex': variant?.colorHex,
            'sku': variant?.sku,
            'sellingPrice': variant?.sellingPrice == null ? null : Fmt.number(variant!.sellingPrice).replaceAll(',', ''),
            'quantity': variant == null ? null : '${variant.quantity}',
          }),
        ),
      ],
      child: _VariantFormDialog(variant: variant, onSaved: products.fetch),
    ),
  );
}

class _VariantFormDialog extends StatelessWidget {
  const _VariantFormDialog({this.variant, required this.onSaved});

  final ProductVariant? variant;
  final Future<bool> Function() onSaved;

  Future<void> _save(BuildContext context) async {
    final vm = context.read<ProductVariantsVM>();
    final d = context.read<FormDraft>();
    final ok = await vm.save(
      VariantForm(
        size: d.text('size'),
        color: d.text('color'),
        colorAr: d.text('colorAr'),
        colorHex: d.text('colorHex'),
        sku: d.text('sku'),
        price: d.text('sellingPrice'),
        quantity: d.text('quantity'),
      ),
      editing: variant,
    );
    if (!context.mounted) return;
    if (ok) onSaved();
    reportResult(
      context,
      ok: ok,
      pop: true,
      errorMessage: vm.errorMessage,
      success: variant == null ? 'Option added.' : 'Option updated.',
      fieldError: vm.fieldError,
      fields: ProductVariantsVM.formFields,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductVariantsVM>();
    final d = context.read<FormDraft>();
    AppTextField field(String key, String label, IconData icon,
            {String? hint, TextInputType? keyboard, TextDirection? dir, bool required = false}) =>
        AppTextField(
          label: label,
          icon: icon,
          hintText: hint,
          required: required,
          controller: d.controller(key),
          errorText: vm.fieldError(key),
          keyboardType: keyboard,
          textDirection: dir,
          maxLength: 50,
          onChanged: (_) => vm.clearError(),
        );

    return FormDialog(
      title: variant == null ? 'New size / color' : 'Edit ${variant!.label}',
      icon: Iconsax.color_swatch_copy,
      maxWidth: 520,
      saveLabel: variant == null ? 'Add option' : 'Save changes',
      saving: vm.isSaving,
      onSave: () => _save(context),
      children: [
        FieldRow(children: [
          field('size', 'Size', Iconsax.ruler_copy, hint: 'M, 42, 30×40'),
          field('color', 'Color', Iconsax.color_swatch_copy, hint: 'Black'),
        ]),
        FieldRow(children: [
          field('colorAr', 'Color in Arabic', Iconsax.translate_copy, hint: 'أسود', dir: TextDirection.rtl),
          field('colorHex', 'Color code', Iconsax.brush_2_copy, hint: '#1A1A1A', dir: TextDirection.ltr),
        ]),
        FieldRow(children: [
          AppTextField(
            label: 'Stock',
            required: true,
            icon: Iconsax.box_1_copy,
            controller: d.controller('quantity'),
            errorText: vm.fieldError('quantity'),
            keyboardType: TextInputType.number,
            inputFormatters: intInputFormatters,
            onChanged: (_) => vm.clearError(),
          ),
          AppTextField.money(
            label: 'Own price',
            helperText: 'Empty = product price',
            controller: d.controller('sellingPrice'),
            errorText: vm.fieldError('sellingPrice'),
            onChanged: (_) => vm.clearError(),
          ),
        ]),
        field('sku', 'SKU', Iconsax.barcode_copy, dir: TextDirection.ltr),
      ],
    );
  }
}
