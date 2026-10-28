import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/controllers/add_order/add_product.dart';
import 'package:warsha_app/controllers/drag_drop_controller.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/utils/default_button.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/category_v_m.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProductVM>().clearError();
    });
  }

  Future<void> _save(ProductProvider product) async {
    final vm = context.read<ProductVM>();
    final drop = context.read<DragDropController>();
    final ok = await vm.add(
      ProductForm(
        name: product.productName.text,
        nameAr: product.productNameAr.text,
        description: product.productDescription.text,
        descriptionAr: product.productDescriptionAr.text,
        buyingPrice: product.productBuyingPrice.text,
        sellingPrice: product.productSellingPrice.text,
        discount: product.discount.text,
        quantity: product.productQuantity.text,
        categoryId: int.tryParse(product.productCategory.text),
      ),
      image: drop.droppedBytes,
      imageName: drop.droppedFileName,
      sizes: List.of(product.productSizes),
      colors: List.of(product.productColors),
    );
    if (!mounted) return;
    if (ok) {
      product.clear();
      drop.clear();
      Navigator.pop(context);
      showSuccess(context, vm.warning ?? 'Product added.');
    } else if (ProductVM.formFields.every((f) => vm.fieldError(f) == null)) {
      showError(context, vm.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductVM>();
    final categories = context.watch<CategoryVM>().allCategories;
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 250, child: DragDropImageUpload()),
                            if (vm.fieldError('image') case final String error)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 8),
                                child: Text(error, style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
                              ),
                          ],
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
                                    errorText: vm.fieldError('buyingPrice'),
                                    onChange: product.updateBuyingPrice,
                                    icon: Iconsax.moneys,
                                    currency: true,
                                    isRequired: true,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: DefaultProductForm(
                                    title: "Selling Price",
                                    controller: product.productSellingPrice,
                                    errorText: vm.fieldError('sellingPrice'),
                                    onChange: product.updateSellingPrice,
                                    icon: Iconsax.moneys,
                                    currency: true,
                                    isRequired: true,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            DefaultProductForm(
                              title: "Discount Amount",
                              controller: product.discount,
                              errorText: vm.fieldError('discount'),
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
                          errorText: vm.fieldError('name'),
                          icon: Iconsax.bag_2,
                          isRequired: true,
                        ),
                        const SizedBox(height: 20),
                        DefaultProductForm(
                          title: "Product Name (Arabic)",
                          controller: product.productNameAr,
                          errorText: vm.fieldError('nameAr'),
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
                                  errorText: vm.fieldError('categoryId'),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
                                    child: Icon(Iconsax.category, color: Theme.of(context).colorScheme.tertiary),
                                  ),
                                ),
                                dropdownColor: Colors.white,
                                items: categories.map((category) {
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
                          errorText: vm.fieldError('quantity'),
                          icon: Iconsax.box_add,
                          isRequired: true,
                          keyboardType: TextInputType.number,
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
                          errorText: vm.fieldError('description'),
                          icon: Iconsax.document_text,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        DefaultProductForm(
                          title: "Description (Arabic)",
                          controller: product.productDescriptionAr,
                          errorText: vm.fieldError('descriptionAr'),
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
                                onTap: () => _save(product),
                                isValid: !vm.isSaving,
                                isLoading: vm.isSaving,
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
    showDialog(context: context, builder: (_) => const _QuickAddCategory());
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

/// Adds a category without leaving the product form.
class _QuickAddCategory extends StatefulWidget {
  const _QuickAddCategory();

  @override
  State<_QuickAddCategory> createState() => _QuickAddCategoryState();
}

class _QuickAddCategoryState extends State<_QuickAddCategory> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoryVM>().clearError();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = context.read<CategoryVM>();
    final ok = await vm.add(CategoryRequest(name: _controller.text));
    if (!mounted) return;
    reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: 'Category added.',
        fieldError: vm.fieldError, fields: const ['name'], pop: true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryVM>();
    return AlertDialog(
      title: const Text('Add New Category'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onChanged: (_) => vm.clearError(),
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          hintText: 'Enter category name',
          errorText: vm.fieldError('name'),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: vm.isSaving ? null : _save, child: const Text('Save')),
      ],
    );
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
    this.errorText,
  });

  final String? errorText;
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
        errorText: errorText,
        errorMaxLines: 2,
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
