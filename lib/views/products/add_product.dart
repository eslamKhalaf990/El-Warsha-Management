import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/controllers/add_order/add_product.dart';
import 'package:warsha_app/controllers/drag_drop_controller.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/product_variant.dart';
import 'package:warsha_app/services/product_variants_service.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/utils/default_button.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/utils/navigator.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';

// Assuming DragDropImageUpload is in the same file or imported
import 'drag_drop_widget.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, product, child) => Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN: Media & Pricing (Flex 1)
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      // Image Upload Section
                      _buildSectionContainer(
                        context,
                        title: "Product Image",
                        child: const SizedBox(
                          height: 250, // Fixed height for upload area
                          child: DragDropImageUpload(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Pricing Section
                      _buildSectionContainer(
                        context,
                        title: "Pricing Strategy",
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: DefaultProductForm(
                                    title: "Buying Price",
                                    controller: product.productBuyingPrice,
                                    onChange: product.updateBuyingPrice,
                                    icon: Iconsax.moneys,
                                    currency: true,
                                    isRequired: true,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: DefaultProductForm(
                                    title: "Selling Price",
                                    controller: product.productSellingPrice,
                                    onChange: product.updateSellingPrice,
                                    icon: Iconsax.moneys,
                                    currency: true,
                                    isRequired: true,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            DefaultProductForm(
                              title: "Discount Amount",
                              controller: product.discount,
                              icon: Iconsax.discount_shape,
                              currency: true,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                            const SizedBox(height: 20),

                            // Profit Margin Indicator (Live Calculation)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Iconsax.moneys, color: Theme.of(context).colorScheme.tertiary, size: 20),
                                      const SizedBox(width: 10),
                                      DefaultText(txt: "Estimated Profit:", color: Theme.of(context).colorScheme.tertiary),
                                    ],
                                  ),
                                  DefaultText(
                                    txt: "${product.sellingPrice - product.buyingPrice} EGP",
                                    bold: true,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.tertiary,
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // RIGHT COLUMN: Details & Actions (Flex 2)
                Expanded(
                  flex: 6,
                  child: _buildSectionContainer(
                    context,
                    title: "Product Details",
                    child: Column(
                      children: [
                        DefaultProductForm(
                          title: "Product Name",
                          controller: product.productName,
                          icon: Iconsax.bag_2,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Product name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        DefaultProductForm(
                          title: "Product Name (Arabic)",
                          controller: product.productNameAr,
                          icon: Iconsax.language_square,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 20),

                        // Category Dropdown (Styled to match inputs)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<CategoryModel>(
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelText: "Category *",
                                  labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 1.5),
                                  ),
                                  errorStyle: TextStyle(color: Colors.red.shade300),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
                                    child: Icon(Iconsax.category, color: Theme.of(context).colorScheme.tertiary),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Category is required';
                                  }
                                  return null;
                                },
                                dropdownColor: Colors.white,
                                items: Provider.of<ProductVM>(context, listen: false)
                                    .allCategories
                                    ?.map((category) {
                                  return DropdownMenuItem<CategoryModel>(
                                    value: category,
                                    child: Text(category.name),
                                  );
                                }).toList(),
                                onChanged: (selectedCategory) {
                                  if (selectedCategory != null) {
                                    product.productCategory.text = selectedCategory.categoryId.toString();
                                  }
                                },
                              ),
                            ),

                            const SizedBox(width: 15),

                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: IconButton(
                                onPressed: () => _showAddCategoryDialog(context),
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.tertiary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Iconsax.add_circle_copy,
                                    color: Theme.of(context).colorScheme.tertiary,
                                    size: 25,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        DefaultProductForm(
                          title: "Initial Quantity",
                          controller: product.productQuantity,
                          icon: Iconsax.box_add,
                          isRequired: true,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        DefaultProductForm(
                          title: "Vendor (Supplier)",
                          controller: product.productSupplier,
                          icon: Iconsax.profile_2user,
                        ),
                        const SizedBox(height: 20),

                        const ColorTagInput(),

                        const SizedBox(height: 20),

                        const SizeTagInput(),

                        const SizedBox(height: 20),
                        
                        DefaultProductForm(
                          title: "Description",
                          controller: product.productDescription,
                          icon: Iconsax.document_text,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        DefaultProductForm(
                          title: "Description (Arabic)",
                          controller: product.productDescriptionAr,
                          icon: Iconsax.document_text,
                          maxLines: 3,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 40),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 55,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                  ),
                                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              flex: 2,
                              child: DefaultButton(
                                onTap: () async {
                                  if (_formKey.currentState!.validate()) {
                                    final productVM = Provider.of<ProductVM>(context, listen: false);
                                    final variantsService = context.read<ProductVariantsService>();
                                    String status = await productVM.addProduct(
                                      productName: product.productName.text,
                                      productDescription: product.productDescription.text,
                                      productNameAr: product.productNameAr.text,
                                      productDescriptionAr: product.productDescriptionAr.text,
                                      productBPrice: product.productBuyingPrice.text,
                                      productDiscount: product.discount.text,
                                      productSPrice: product.productSellingPrice.text,
                                      productCategory: product.productCategory.text,
                                      productQuantity: product.productQuantity.text,
                                      imageBytes: Provider.of<DragDropController>(context, listen: false).droppedBytes,
                                    );
                                    if (status == "product_added") {
                                      final variantError = await _createVariants(
                                          variantsService, productVM.lastCreatedProductId, product);
                                      Navigator.pop(navigatorKey.currentContext!);
                                      Provider.of<ProductVM>(navigatorKey.currentContext!, listen: false).initAllProducts();
                                      Provider.of<ProductVM>(navigatorKey.currentContext!, listen: false).getAllProducts();
                                      final hadVariants = product.productSizes.isNotEmpty || product.productColors.isNotEmpty;
                                      product.clear();
                                      Provider.of<DragDropController>(navigatorKey.currentContext!, listen: false).clear();
                                      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Theme.of(context).colorScheme.tertiary,
                                          content: Text(variantError ??
                                              (!hadVariants
                                                  ? "Product added successfully"
                                                  : "Product added. Set the stock of each size/color from Edit product.")),
                                        ),
                                      );
                                    }
                                  }
                                },
                                isValid: !Provider.of<ProductVM>(context).isLoading,
                                isLoading: Provider.of<ProductVM>(context).isLoading,
                                title: "Save Product", margin: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter category name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: Provider.of<ProductVM>(context).isLoading ? null :() {
              String name = controller.text.trim();
              if (name.isNotEmpty) {
                Provider.of<ProductVM>(context, listen: false).addCategory(name);
                controller.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(BuildContext context, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800
            ),
          ),
          const SizedBox(height: 25),
          child,
        ],
      ),
    );
  }
}

/// Creates one variant per size × color picked on the form, with no stock yet.
/// Returns a message when some could not be created.
Future<String?> _createVariants(
    ProductVariantsService service, int? productId, ProductProvider product) async {
  final sizes = product.productSizes.isEmpty ? <String?>[null] : product.productSizes;
  final colors = product.productColors.isEmpty ? <String?>[null] : product.productColors;
  if (product.productSizes.isEmpty && product.productColors.isEmpty) return null;
  if (productId == null) {
    return "Product added, but its sizes/colors weren't saved. Add them from Edit product.";
  }
  try {
    for (final size in sizes) {
      for (final color in colors) {
        await service.create(productId, ProductVariantRequest(size: size, color: color, quantity: 0));
      }
    }
    return null;
  } on ApiException catch (e) {
    return "Product added, but some sizes/colors weren't saved: ${e.message}";
  }
}

class ColorTagInput extends StatefulWidget {
  const ColorTagInput({super.key});

  @override
  State<ColorTagInput> createState() => _ColorTagInputState();
}

class _ColorTagInputState extends State<ColorTagInput> {
  final TextEditingController _controller = TextEditingController();

  void _handleAdd() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      Provider.of<ProductProvider>(context, listen: false).addColor(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, product, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller,
            onFieldSubmitted: (_) => _handleAdd(),
            cursorColor: Theme.of(context).colorScheme.tertiary,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: "Product Colors",
              hintText: "Type color (e.g. Red) and press +",
              labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(25),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 1.5),
                borderRadius: BorderRadius.circular(25),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Icon(Iconsax.color_swatch, color: Theme.of(context).colorScheme.tertiary),
              ),
              suffixIcon: IconButton(
                onPressed: _handleAdd,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Iconsax.add_circle_copy, color: Theme.of(context).colorScheme.tertiary, size: 25),
                ),
              ),
            ),
          ),
          if (product.productColors.isNotEmpty) ...[
            const SizedBox(height: 15),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: product.productColors.map((color) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        color,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          product.removeColor(color);
                        },
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.6),
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ]
        ],
      ),
    );
  }
}

class SizeTagInput extends StatefulWidget {
  const SizeTagInput({super.key});

  @override
  State<SizeTagInput> createState() => _SizeTagInputState();
}

class _SizeTagInputState extends State<SizeTagInput> {
  final TextEditingController _controller = TextEditingController();

  void _handleAdd() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      Provider.of<ProductProvider>(context, listen: false).addSize(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, product, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller,
            onFieldSubmitted: (_) => _handleAdd(),
            cursorColor: Theme.of(context).colorScheme.tertiary,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: "Product Sizes",
              hintText: "Type size (e.g. 12mm) and press +",
              labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(25),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 1.5),
                borderRadius: BorderRadius.circular(25),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Icon(Iconsax.size, color: Theme.of(context).colorScheme.tertiary),
              ),
              suffixIcon: IconButton(
                onPressed: _handleAdd,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Iconsax.add_circle_copy, color: Theme.of(context).colorScheme.tertiary, size: 25),
                ),
              ),
            ),
          ),
          if (product.productSizes.isNotEmpty) ...[
            const SizedBox(height: 15),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: product.productSizes.map((size) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        size,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          product.removeSize(size);
                        },
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.6),
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ]
        ],
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
    this.fillColor,
    this.currency,
    this.maxLines = 1,
    this.isRequired = false,
    this.validator,
    this.keyboardType,
    this.textDirection,
  });

  final String title;
  final TextEditingController controller;
  final Function(String)? onChange;
  final IconData? icon;
  final bool? currency;
  final Color? fillColor;
  final int? maxLines;
  final bool isRequired;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChange,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      textDirection: textDirection,
      style: const TextStyle(fontWeight: FontWeight.w500),
      cursorColor: Theme.of(context).colorScheme.tertiary,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor ?? Colors.white,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 1.5),
          borderRadius: BorderRadius.circular(25),
        ),
        errorStyle: TextStyle(color: Colors.red.shade300),
        prefixIcon: icon != null
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Icon(icon, color: Theme.of(context).colorScheme.tertiary),
        )
            : null,
        suffixIcon: currency != null
            ? Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text("EGP", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        )
            : null,
        labelText: isRequired ? "$title *" : title,
        alignLabelWithHint: true,
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      ),
    );
  }
}
