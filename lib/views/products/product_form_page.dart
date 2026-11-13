import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/categories/category_form_dialog.dart';
import 'package:warsha_app/views/products/widgets/gallery_section.dart';
import 'package:warsha_app/views/products/widgets/option_chips_input.dart';
import 'package:warsha_app/views/products/widgets/pricing_summary.dart';
import 'package:warsha_app/views/products/widgets/variants_section.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/services/product_images_service.dart';
import 'package:warsha_app/services/product_variants_service.dart';
import 'package:warsha_app/view_models/product_v_m.dart';
import 'package:warsha_app/view_models/category_v_m.dart';
import 'package:warsha_app/view_models/product_gallery_v_m.dart';
import 'package:warsha_app/view_models/product_variants_v_m.dart';
import 'package:warsha_app/view_models/vendors_v_m.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

/// Opens the add form, or the edit form for [product] (which also manages
/// its gallery and sizes / colors).
Future<void> openProductForm(BuildContext context, {ProductModel? product}) {
  context.read<ProductVM>().clearError();
  final id = int.tryParse(product?.id ?? '');
  String plain(String s) => s == '0' || s == '0.0' ? '' : s;
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => FormDraft(
              text: {
                'name': product?.name,
                'nameAr': product?.nameAr,
                'description': product?.productDescription,
                'descriptionAr': product?.descriptionAr,
                'buyingPrice': product?.buyingPrice,
                'sellingPrice': product?.sellingPrice,
                'discount': product == null ? null : plain(product.discount),
                'quantity': product?.quantity,
              },
              values: {
                'categoryId': int.tryParse(product?.categoryId ?? ''),
                'vendorId': product?.vendorId,
                'sizes': const <String>[],
                'colors': const <String>[],
              },
            ),
          ),
          if (id != null) ...[
            ChangeNotifierProvider(create: (c) => ProductGalleryVM(c.read<ProductImagesService>(), id)..fetch()),
            ChangeNotifierProvider(create: (c) => ProductVariantsVM(c.read<ProductVariantsService>(), id)..fetch()),
          ],
        ],
        child: ProductFormPage(product: product),
      ),
    ),
  );
}

class ProductFormPage extends StatelessWidget {
  const ProductFormPage({super.key, this.product});

  final ProductModel? product;

  bool get _isNew => product == null;

  Future<void> _save(BuildContext context) async {
    final vm = context.read<ProductVM>();
    final d = context.read<FormDraft>();
    final form = ProductForm(
      name: d.text('name'),
      nameAr: d.text('nameAr'),
      description: d.text('description'),
      descriptionAr: d.text('descriptionAr'),
      buyingPrice: d.text('buyingPrice'),
      sellingPrice: d.text('sellingPrice'),
      discount: d.text('discount'),
      quantity: d.text('quantity'),
      categoryId: d.value<int>('categoryId'),
      vendorId: d.value<int>('vendorId'),
    );
    final image = d.value<PickedImage>('image');
    final ok = _isNew
        ? await vm.add(
            form,
            image: image?.bytes,
            imageName: image?.name,
            sizes: d.value<List<String>>('sizes') ?? const [],
            colors: d.value<List<String>>('colors') ?? const [],
          )
        : await vm.update(product!, form, image: image?.bytes, imageName: image?.name);
    if (!context.mounted) return;
    if (ok) {
      Navigator.pop(context);
      vm.warning != null ? showInfo(context, vm.warning!) : showSuccess(context, _isNew ? tr('Product added.') : tr('Product updated.'));
    } else if (ProductVM.formFields.every((f) => vm.fieldError(f) == null)) {
      showError(context, vm.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductVM>();
    final d = context.watch<FormDraft>();
    final hasVariants = !_isNew &&
        (context.select<ProductVariantsVM, bool>((v) => v.variants.isNotEmpty) || product!.hasVariants);

    AppTextField field(String key, String label, IconData icon, int maxLength,
            {bool required = false, int maxLines = 1, String? helper, TextDirection? dir}) =>
        AppTextField(
          label: label,
          icon: icon,
          required: required,
          controller: d.controller(key),
          errorText: vm.fieldError(key),
          maxLength: maxLength,
          maxLines: maxLines,
          helperText: helper,
          textDirection: dir,
          onChanged: (_) => vm.clearError(),
        );

    AppTextField money(String key, String label, {bool required = false, String? helper}) => AppTextField.money(
          label: label,
          required: required,
          helperText: helper,
          controller: d.controller(key),
          errorText: vm.fieldError(key),
          onChanged: (_) {
            vm.clearError();
            d.touch();
          },
        );

    return FormPage(
      title: _isNew ? tr('New product') : tr('Edit product'),
      subtitle: product?.name,
      draft: d,
      saving: vm.isSaving,
      saveLabel: _isNew ? tr('Add product') : tr('Save changes'),
      onSave: () => _save(context),
      sections: [
        FormSection(
          title: tr('Basics'),
          icon: Iconsax.box_1_copy,
          children: [
            FieldRow(children: [
              field('name', tr('Name in English'), Iconsax.text_copy, ProductVM.nameMaxLength, required: true),
              field('nameAr', tr('Name in Arabic'), Iconsax.translate_copy, ProductVM.nameArMaxLength, dir: TextDirection.rtl),
            ]),
            _CategoryField(
              value: d.value<int>('categoryId'),
              errorText: vm.fieldError('categoryId'),
              onChanged: (id) {
                d.set('categoryId', id);
                vm.clearError();
              },
            ),
            _VendorField(
              value: d.value<int>('vendorId'),
              linkedName: product?.vendorId == null ? null : product!.vendorName,
              linkedId: product?.vendorId,
              errorText: vm.fieldError('vendorId'),
              onChanged: (id) {
                d.set('vendorId', id);
                vm.clearError();
              },
            ),
          ],
        ),
        FormSection(
          title: tr('Description'),
          icon: Iconsax.note_text_copy,
          subtitle: tr('Shown on the product page in the store.'),
          children: [
            field('description', tr('In English'), Iconsax.text_copy, ProductVM.descriptionMaxLength, maxLines: 4),
            field('descriptionAr', tr('In Arabic'), Iconsax.translate_copy, ProductVM.descriptionArMaxLength,
                maxLines: 4, dir: TextDirection.rtl),
          ],
        ),
        FormSection(
          title: tr('Pricing'),
          icon: Iconsax.money_2_copy,
          children: [
            FieldRow(children: [
              money('buyingPrice', tr('Cost'), required: true, helper: tr('What one piece costs you.')),
              money('sellingPrice', tr('Selling price'), required: true),
            ]),
            money('discount', tr('Discount per piece'), helper: tr('Taken off the selling price in the store and in orders.')),
            PricingSummary(buying: d.text('buyingPrice'), selling: d.text('sellingPrice'), discount: d.text('discount')),
          ],
        ),
        FormSection(
          title: tr('Stock'),
          icon: Iconsax.box_tick_copy,
          subtitle: hasVariants ? tr('Stock is kept per size / color below.') : null,
          children: [
            if (!hasVariants)
              AppTextField(
                label: _isNew ? tr('Pieces in stock') : tr('Stock'),
                required: true,
                icon: Iconsax.box_1_copy,
                controller: d.controller('quantity'),
                errorText: vm.fieldError('quantity'),
                keyboardType: TextInputType.number,
                inputFormatters: intInputFormatters,
                onChanged: (_) => vm.clearError(),
              ),
            if (_isNew) ...[
              OptionChipsInput(
                label: tr('Sizes'),
                hint: tr('S, M, L'),
                icon: Iconsax.ruler_copy,
                controller: d.controller('sizeEntry'),
                values: d.value<List<String>>('sizes') ?? const [],
                onChanged: (v) => d.set('sizes', v),
              ),
              OptionChipsInput(
                label: tr('Colors'),
                hint: tr('Black, White'),
                icon: Iconsax.color_swatch_copy,
                controller: d.controller('colorEntry'),
                values: d.value<List<String>>('colors') ?? const [],
                onChanged: (v) => d.set('colors', v),
              ),
              if ((d.value<List<String>>('sizes') ?? const []).isNotEmpty ||
                  (d.value<List<String>>('colors') ?? const []).isNotEmpty)
                InlineBanner(
                  message: tr('Each size × color is created with 0 stock. Set their stock after saving.'),
                  tone: Tone.info,
                ),
            ] else if (hasVariants)
              AppText.bodySmall(tr('Total: {0} pieces', [context.select<ProductVariantsVM, int>((v) => v.totalStock)]),
                  color: AppColors.muted),
          ],
        ),
        if (!_isNew) const VariantsSection(),
      ],
      aside: [
        FormSection(
          title: tr('Cover image'),
          icon: Iconsax.image_copy,
          subtitle: tr('The first picture customers see.'),
          children: [
            ImagePickerField(
              label: tr('cover image'),
              height: 280,
              picked: d.value<PickedImage>('image'),
              url: product?.imageFullUrl,
              errorText: vm.fieldError('image'),
              onPicked: (image) {
                d.set('image', image);
                vm.clearError();
              },
              onRemove: d.value<PickedImage>('image') == null ? null : () => d.set('image', null),
            ),
          ],
        ),
        if (!_isNew) const GallerySection(),
      ],
    );
  }
}

/// Who the product is bought from. Optional; "No vendor" clears the link.
/// A vendor archived since it was linked stays listed so the form still opens.
class _VendorField extends StatelessWidget {
  const _VendorField({
    required this.value,
    required this.onChanged,
    this.linkedId,
    this.linkedName,
    this.errorText,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final int? linkedId;
  final String? linkedName;
  final String? errorText;

  static const _none = 0;

  @override
  Widget build(BuildContext context) {
    final vendors = context.watch<VendorVM>().allVendors;
    final names = {for (final v in vendors) v.vendorId: v.name};
    if (linkedId != null && !names.containsKey(linkedId)) {
      names[linkedId!] = tr('{0} (archived)', [linkedName ?? tr('Vendor #{0}', [linkedId])]);
    }
    return AppDropdown<int>(
      label: tr('Vendor'),
      icon: Iconsax.shop_copy,
      items: [_none, ...names.keys],
      value: value ?? _none,
      itemLabel: (id) => id == _none ? tr('No vendor') : names[id]!,
      helperText: vendors.isEmpty ? tr('Add vendors on the Vendors page.') : tr('Who you buy this product from.'),
      errorText: errorText,
      onChanged: (id) => onChanged(id == null || id == _none ? null : id),
    );
  }
}

/// Category picker with a shortcut to create one without leaving the form.
class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.value, required this.onChanged, this.errorText});

  final int? value;
  final ValueChanged<int?> onChanged;
  final String? errorText;

  Future<void> _addCategory(BuildContext context) async {
    final vm = context.read<CategoryVM>();
    final before = vm.allCategories.length;
    if (await openCategoryForm(context) && vm.allCategories.length > before) {
      onChanged(vm.allCategories.last.categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryVM>().allCategories;
    final selected = categories.where((c) => c.categoryId == value).firstOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppDropdown<CategoryModel>(
            label: tr('Category'),
            required: true,
            icon: Iconsax.category_2_copy,
            items: categories,
            value: selected,
            itemLabel: (c) => c.name,
            hintText: categories.isEmpty ? tr('Add a category first') : null,
            errorText: errorText,
            onChanged: (c) => onChanged(c?.categoryId),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: IconButton.outlined(
            tooltip: tr('New category'),
            icon: const Icon(Iconsax.add_copy),
            onPressed: () => _addCategory(context),
          ),
        ),
      ],
    );
  }
}
