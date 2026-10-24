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
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/update_product_v_m.dart';
import 'package:warsha_app/views/products/update_drag_drop.dart';

class UpdateProduct extends StatelessWidget {
  const UpdateProduct({super.key, required this.productModel});
  final ProductModel productModel;

  @override
  Widget build(BuildContext context) {
    final productProvider = context.read<UpdateProductProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      productProvider.loadProduct(productModel);
    });

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
                            child: DefaultProductForm(
                              title: "Product name",
                              controller: update.productName,
                              icon: Iconsax.bag,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 15.0),
                            child: DefaultProductForm(
                              title: "Product description",
                              controller: update.productDescription,
                              icon: Iconsax.document,
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
                                  initialValue: Provider.of<ProductVM>(context, listen: false).allCategories?.firstWhere(
                                        (c) => c.categoryId.toString() == productModel.categoryId,
                                    orElse: () => Provider.of<ProductVM>(context, listen: false).allCategories!.first,
                                  ),
                                  decoration: InputDecoration(
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
                                  items: Provider.of<ProductVM>(context, listen: false).allCategories?.map((category) {
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
                            child: DefaultProductForm(
                              title: "Product quantity",
                              controller: update.productQuantity,
                              icon: Iconsax.add,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Consumer<UpdateProductVM>(
                              builder: (context, productVM, child) =>
                                  Expanded(
                                flex: 3,
                                child: DefaultButton(
                                  onTap: () async {
                                    final drop = Provider.of<UpdateDragDropController>(
                                        context,
                                        listen: false);
                                    String status =
                                        await productVM.updateProduct(
                                      productName: update.productName.text,
                                      productDescription:
                                          update.productDescription.text,
                                      productBPrice:
                                          update.productBuyingPrice.text,
                                      productSPrice:
                                          update.productSellingPrice.text,
                                      productCategory: productModel.categoryId,
                                      productDiscount:
                                          update.discount.text,
                                      productQuantity:
                                          update.productQuantity.text,
                                      // Upload bytes only for a newly dropped/browsed file;
                                      // a library image is assigned by filename instead
                                      imageBytes: drop.isNewFile
                                          ? drop.droppedBytes
                                          : null,
                                      imageName: drop.droppedFileName,
                                      libraryFilename: drop.libraryFilename,
                                      id: productModel.id,
                                    );
                                    if (status == "product_updated" ||
                                        status == "image_not_assigned") {
                                      Navigator.pop(context);
                                      Provider.of<ProductVM>(context, listen: false).initAllProducts();
                                      Provider.of<ProductVM>(context, listen: false).getAllProducts();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(status == "product_updated"
                                              ? "Product updated successfully"
                                              : "Product saved, but the selected image could not be assigned"),
                                        ),
                                      );
                                    }
                                  },
                                  isValid: !Provider.of<UpdateProductVM>(context)
                                      .isLoading,
                                  isLoading: Provider.of<UpdateProductVM>(context)
                                      .isLoading,
                                  title: "Update product",
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                ),
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
  });
  final String title;
  final TextEditingController controller;
  final Function(String)? onChange;
  final IconData? icon;
  final bool? currency;
  final Color? fillColor;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChange,
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
