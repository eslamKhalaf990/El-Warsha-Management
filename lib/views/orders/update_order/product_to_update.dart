import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

// Assuming these are your paths
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/models/orderItemModel.dart';
import 'package:warsha_app/models/product_variant.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/update_order_v_m.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/default_text.dart';

class ProductToUpdate extends StatelessWidget {
  const ProductToUpdate({super.key});

  @override
  Widget build(BuildContext context) {
    // We listen to ProductVM for search query changes
    final productVM = Provider.of<ProductVM>(context);
    final orderVM = Provider.of<UpdateOrderVM>(context);

    return FutureBuilder<List<ProductModel>>(
      future: productVM.allProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No products found"));
        }

        // Filtering logic
        final query = productVM.searchController.text.toLowerCase();
        final filteredProducts = snapshot.data!.where((product) {
          final name = product.name.toLowerCase();
          final sku = product.sku?.toLowerCase() ?? "";
          return name.contains(query) || sku.contains(query);
        }).toList();

        return Expanded(
          child: ListView.builder(
            itemCount: filteredProducts.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (context, index) {
              final product = filteredProducts[index];

              // Check if selected
              final bool isSelected = orderVM.orderModel.orderItems
                  .any((item) => item.productId.toString() == product.id);

              return GestureDetector(
                onTap: () async {
                  ProductVariant? variant;
                  if (product.hasVariants) {
                    variant = await _pickVariant(context, product);
                    if (variant == null) return;
                  }
                  OrderItemModel orderItemModel = OrderItemModel(
                    productId: int.parse(product.id),
                    productName: product.name,
                    quantity: variant?.quantity ?? int.tryParse(product.quantity) ?? 0,
                    unitPrice: variant?.price ?? double.parse(product.sellingPrice),
                    variantId: variant?.id,
                    size: variant?.size,
                    color: variant?.color,
                  )..unitDiscount = double.tryParse(product.discount) ?? 0;

                  final lineExists = orderVM.orderModel.orderItems
                      .any((item) => item.sameLineAs(orderItemModel));
                  if (!lineExists) {
                    orderVM.addToOrderItems = orderItemModel;
                  } else {
                    orderVM.removeFromOrderItems = orderItemModel;
                  }
                },
                child: ProductWidget(
                  productModel: product,
                  isSelected: isSelected,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Asks which size/color to add (or remove, if it is already on the order).
Future<ProductVariant?> _pickVariant(BuildContext context, ProductModel product) {
  return showDialog<ProductVariant>(
    context: context,
    builder: (context) => SimpleDialog(
      backgroundColor: Colors.white,
      title: Text("${product.name}: size / color"),
      children: product.variants
          .map((v) => SimpleDialogOption(
                onPressed: v.inStock ? () => Navigator.pop(context, v) : null,
                child: Text("${v.label} · ${v.price} EGP · stock ${v.quantity}",
                    style: TextStyle(color: v.inStock ? null : Colors.grey)),
              ))
          .toList(),
    ),
  );
}

class ProductWidget extends StatelessWidget {
  final ProductModel productModel;
  final bool isSelected;

  const ProductWidget({
    super.key,
    required this.productModel,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.tertiary.withAlpha(40)
            : Theme.of(context).colorScheme.surface,
        borderRadius: Constants.BORDER_RADIUS_20,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.tertiary
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flexible Image handling
              _buildProductImage(context),
              const SizedBox(width: 12),

              // Content Area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 4),
                    Text(
                      productModel.productDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTags(context),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPriceSection(context),
        ],
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        productModel.image,
        width: 65,
        height: 65,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 65,
            height: 65,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (context, _, __) => Container(
          width: 65,
          height: 65,
          color: Colors.grey.shade100,
          child: const Icon(Iconsax.box, size: 30, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        DefaultText(txt: productModel.sku ?? "N/A", bold: true, size: 14),
        Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
        DefaultText(txt: productModel.name, bold: true, size: 14),
        if (int.parse(productModel.quantity) < 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(6)),
            child: const Text('Out of stock', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildTags(BuildContext context) {
    return Row(
      children: [
        Icon(Iconsax.category, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        DefaultText(txt: productModel.category, size: 12),
        const SizedBox(width: 12),
        Icon(Iconsax.archive_1, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        DefaultText(txt: "${productModel.quantity} In Stock", size: 12),
      ],
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    // Wrap allows price boxes to stack if they are too wide for the screen
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _priceBadge(label: "Buying", value: productModel.buyingPrice, color: Theme.of(context).colorScheme.tertiary.withAlpha(40)),
        _priceBadge(label: "Selling", value: productModel.sellingPrice, color: Theme.of(context).colorScheme.tertiary.withAlpha(40)),
      ],
    );
  }

  Widget _priceBadge({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.black, fontSize: 12)),
          Text("$value EGP", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}