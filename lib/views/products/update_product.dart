import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/controllers/update_drag_drop.dart';
import 'package:warsha_app/controllers/update_order/update_product.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/default_button.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/category_v_m.dart';
import 'package:warsha_app/views/products/product_gallery_editor.dart';
import 'package:warsha_app/views/products/product_variants_editor.dart';
import 'package:warsha_app/views/products/update_drag_drop.dart';

class UpdateProduct extends StatelessWidget {
  const UpdateProduct({super.key, required this.productModel});
  final ProductModel productModel;

  @override
  Widget build(BuildContext context) {
    final productProvider = context.read<UpdateProductProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      productProvider.loadProduct(productModel);
      context.read<ProductVM>().clearError();
    });
    final vm = context.watch<ProductVM>();
    final categories = context.watch<CategoryVM>().allCategories;

    Future<void> save(UpdateProductProvider update) async {
      final drop = context.read<UpdateDragDropController>();
      final ok = await vm.update(
        productModel,
        ProductForm(
          name: update.productName.text,
          nameAr: update.productNameAr.text,
          description: update.productDescription.text,
          descriptionAr: update.productDescriptionAr.text,
          buyingPrice: update.productBuyingPrice.text,
          sellingPrice: update.productSellingPrice.text,
          discount: update.discount.text,
          quantity: update.productQuantity.text,
          categoryId: int.tryParse(productModel.categoryId),
        ),
        // Only a newly picked image replaces the cover
        image: drop.changed ? drop.droppedBytes : null,
        imageName: drop.droppedFileName,
      );
      if (!context.mounted) return;
      if (ok) {
        Navigator.pop(context);
        showSuccess(context, 'Product updated.');
      } else if (ProductVM.formFields.every((f) => vm.fieldError(f) == null)) {
        showError(context, vm.errorMessage!);
      }
    }

    return Consumer<UpdateProductProvider>(
      builder: (context, update, child) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const DefaultText(txt: "Update Product"),
        ),
        body: Row(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(top: 60, bottom: 50, left: 15),
                child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary,
                      borderRadius: Constants.BORDER_RADIUS_15,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Expanded(
                          flex: 3,
                          child: UpdateDragDropImageUpload(productImage: productModel.image,),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final images = await showProductGalleryEditor(
                                  context,
                                  productId: int.parse(productModel.id),
                                  productName: productModel.name,
                                  coverUrl: productModel.image,
                                );
                                if (images == null) return;
                                productModel.images = images;
                                update.refresh();
                                if (context.mounted) {
                                  context.read<ProductVM>().fetch();
                                }
                              },
                              icon: const Icon(Iconsax.gallery),
                              label: Text(productModel.images.isEmpty
                                  ? "Add more images"
                                  : "Gallery (${productModel.images.length + 1} images)"),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(15),
                          child: const Row(
                            children: [DefaultText(txt: "Product Pricing")],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0),
                                child: DefaultProductForm(
                                  title: "Product buying price",
                                  controller: update.productBuyingPrice,
                                  errorText: vm.fieldError('buyingPrice'),
                                  onChange: update.updateBuyingPrice,
                                  icon: null,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0),
                                child: DefaultProductForm(
                                  title: "Product selling price",
                                  controller: update.productSellingPrice,
                                  errorText: vm.fieldError('sellingPrice'),
                                  onChange: update.updateSellingPrice,
                                  icon: null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 15.0),
                            child: DefaultProductForm(
                              title: "Discount by EGP",
                              controller: update.discount,
                              errorText: vm.fieldError('discount'),
                              icon: Iconsax.discount_shape,
                            ),
                          ),
                        ),
                      ],
                    )),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 60, bottom: 50, right: 15, left: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
                    borderRadius: Constants.BORDER_RADIUS_15,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.0),
                          child: Row(
                            children: [DefaultText(txt: "Product Details")],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 15.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DefaultProductForm(
                                    title: "Product name",
                                    controller: update.productName,
                                    errorText: vm.fieldError('name'),
                                    icon: Iconsax.bag,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: DefaultProductForm(
                                    title: "Product name (Arabic)",
                                    controller: update.productNameAr,
                                    errorText: vm.fieldError('nameAr'),
                                    icon: Iconsax.language_square,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 15.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DefaultProductForm(
                                    title: "Product description",
                                    controller: update.productDescription,
                                    errorText: vm.fieldError('description'),
                                    icon: Iconsax.document,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: DefaultProductForm(
                                    title: "Product description (Arabic)",
                                    controller: update.productDescriptionAr,
                                    errorText: vm.fieldError('descriptionAr'),
                                    icon: Iconsax.document,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Product category",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                DropdownButtonFormField<CategoryModel>(
                                  // Find the matching category instance from the list
                                  initialValue: categories
                                      .where((c) => c.categoryId.toString() == productModel.categoryId)
                                      .firstOrNull,
                                  decoration: InputDecoration(
                                    errorText: vm.fieldError('categoryId'),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors.transparent,
                                      ),
                                      borderRadius: Constants.BORDER_RADIUS_15,
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 30.0, right: 30),
                                      child: Icon(
                                        Iconsax.category,
                                        color: Theme.of(context).colorScheme.tertiary,
                                      ),
                                    ),
                                  ),
                                  hint: const Text("Select a category"),
                                  items: categories.map((category) {
                                    return DropdownMenuItem<CategoryModel>(
                                      value: category,
                                      child: Text(category.name),
                                    );
                                  }).toList(),
                                  onChanged: (selectedCategory) {
                                    if (selectedCategory != null) {
                                      update.productCategory.text = selectedCategory.categoryId.toString();
                                      productModel.category = selectedCategory.name;
                                      productModel.categoryId = selectedCategory.categoryId.toString();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 15.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DefaultProductForm(
                                    title: productModel.hasVariants
                                        ? "Product quantity (total of sizes/colors)"
                                        : "Product quantity",
                                    controller: update.productQuantity,
                                    errorText: vm.fieldError('quantity'),
                                    icon: Iconsax.add,
                                    readOnly: productModel.hasVariants,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final variants = await showProductVariantsEditor(
                                      context,
                                      productId: int.parse(productModel.id),
                                      productName: productModel.name,
                                    );
                                    if (variants == null) return;
                                    productModel.variants = variants;
                                    if (variants.isNotEmpty) {
                                      update.productQuantity.text =
                                          variants.fold<int>(0, (sum, v) => sum + v.quantity).toString();
                                    }
                                    update.refresh();
                                    if (context.mounted) {
                                      context.read<ProductVM>().fetch();
                                    }
                                  },
                                  icon: const Icon(Iconsax.color_swatch),
                                  label: Text(productModel.hasVariants
                                      ? "Sizes & colors (${productModel.variants.length})"
                                      : "Add sizes & colors"),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DefaultButton(
                                onTap: () => save(update),
                                isValid: !vm.isSaving,
                                isLoading: vm.isSaving,
                                title: "Update product",
                                margin: const EdgeInsets.symmetric(horizontal: 15),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: Constants.BORDER_RADIUS_20,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 15),
                                child: Row(
                                  children: [
                                    const DefaultText(
                                        txt: "Profit Margin is:  "),
                                    DefaultText(
                                      txt:
                                          "${update.sellingPrice - update.buyingPrice}",
                                      bold: true,
                                      size: 16,
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DefaultProductForm extends StatelessWidget {
  const DefaultProductForm({
    super.key,
    required this.title,
    required this.icon,
    required this.controller,
    this.onChange,
    this.fillColor, this.currency,
    this.textDirection,
    this.readOnly = false,
    this.errorText,
  });
  final String? errorText;
  final String title;
  final TextEditingController controller;
  final Function(String)? onChange;
  final IconData? icon;
  final bool? currency;
  final Color? fillColor;
  final TextDirection? textDirection;
  final bool readOnly;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChange,
      textDirection: textDirection,
      readOnly: readOnly,
      cursorColor: Theme.of(context)
          .colorScheme
          .tertiary
          .withAlpha(Constants.OPACITY_05),
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
            borderRadius: Constants.BORDER_RADIUS_15),
        errorStyle: TextStyle(color: Colors.red.shade300),
        errorText: errorText,
        errorMaxLines: 2,
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              )
            : null,
        border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.transparent),
            borderRadius: Constants.BORDER_RADIUS_15),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
            borderRadius: Constants.BORDER_RADIUS_15),
        suffix: currency !=  null ? const DefaultText(txt: "EGP") : null,
        labelText: title,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }
}
