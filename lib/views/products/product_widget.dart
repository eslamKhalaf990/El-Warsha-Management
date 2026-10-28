import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/views/products/update_product.dart';

class ProductWidget extends StatelessWidget {
  final ProductModel product;

  const ProductWidget({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = int.tryParse(product.quantity) != null &&
        int.parse(product.quantity) < 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Breakpoint for Mobile vs Desktop
            bool isDesktop = constraints.maxWidth > 600;

            return isDesktop
                ? _buildDesktopLayout(context, isOutOfStock)
                : _buildMobileLayout(context, isOutOfStock);
          },
        ),
      ),
    );
  }

  // ==========================================
  // MOBILE LAYOUT (Vertical Stack)
  // ==========================================
  Widget _buildMobileLayout(BuildContext context, bool isOutOfStock) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            _buildProductImage(context, size: 70),
            const SizedBox(width: 16),

            // Title & SKU
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBadge(isOutOfStock),
                  const SizedBox(height: 4),
                  DefaultText(
                    txt: product.name,
                    size: 16,
                    bold: true,
                  ),
                  const SizedBox(height: 4),
                  DefaultText(
                    txt: "SKU: ${product.sku}  •  ${product.category}",
                    size: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),

            // Actions (Icons only on mobile)
            Column(
              children: [
                _buildEditButton(context, compact: true),
                _buildDeleteButton(context, compact: true),
              ],
            )
          ],
        ),
        const SizedBox(height: 12),

        // Description
        if (product.productDescription.isNotEmpty) ...[
          Text(
            product.productDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 12),
        ],

        // Chips Row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip(
              context,
              label: "Qty: ${product.quantity}",
              color: Colors.grey.shade100,
              textColor: Colors.black87,
              icon: Iconsax.box_1_copy,
            ),
            _buildInfoChip(
              context,
              label: "Buy: ${product.buyingPrice} EGP",
              color: Colors.green.shade50,
              textColor: Colors.green.shade800,
            ),
            _buildInfoChip(
              context,
              label: "Sell: ${product.sellingPrice} EGP",
              color: Theme.of(context).colorScheme.tertiary.withAlpha(20),
              textColor: Theme.of(context).colorScheme.tertiary,
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // DESKTOP LAYOUT (Horizontal Row)
  // ==========================================
  Widget _buildDesktopLayout(BuildContext context, bool isOutOfStock) {
    return Row(
      children: [
        // Image
        _buildProductImage(context, size: 80),
        const SizedBox(width: 20),

        // Main Details
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  DefaultText(
                    txt: product.name,
                    size: 18,
                    bold: true,
                  ),
                  const SizedBox(width: 10),
                  _buildStatusBadge(isOutOfStock),
                ],
              ),
              const SizedBox(height: 5),
              DefaultText(
                txt: "SKU: ${product.sku}  |  ${product.category}",
                size: 13,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                product.productDescription,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),

        // Stats (Prices & Qty)
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildInfoChip(
                context,
                label: "${product.quantity} Pieces",
                icon: Iconsax.box_copy,
                color: Colors.grey.shade100,
                textColor: Colors.black87,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Buy: ${product.buyingPrice}",
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Sell: ${product.sellingPrice}",
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                ],
              )
            ],
          ),
        ),

        const SizedBox(width: 20),
        Container(width: 1, height: 60, color: Colors.grey.shade200),
        const SizedBox(width: 20),

        // Actions
        Column(
          children: [
            _buildEditButton(context, compact: false),
            const SizedBox(height: 8),
            _buildDeleteButton(context, compact: false),
          ],
        )
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildProductImage(BuildContext context, {required double size}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          product.image,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: SpinKitFadingCircle(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  size: 20,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: size,
              height: size,
              child: const Icon(Iconsax.image, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isOutOfStock) {
    if (!isOutOfStock) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Text(
        "Out of Stock",
        style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, {
    required String label,
    required Color color,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- Actions ---

  Widget _buildEditButton(BuildContext context, {required bool compact}) {
    final color = Theme.of(context).colorScheme.secondary;

    if (compact) {
      return IconButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => UpdateProduct(productModel: product))),
        icon: Icon(Iconsax.edit, color: color, size: 20),
        tooltip: "Edit",
      );
    }

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => UpdateProduct(productModel: product))),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Iconsax.edit, size: 16, color: color),
            const SizedBox(width: 6),
            Text("Edit", style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, {required bool compact}) {
    final productVM = context.watch<ProductVM>();
    final isDeletingThis = productVM.deletingId == product.id;
    final canDelete = !productVM.isSaving;

    void onDelete() async {
      if (!canDelete) return;
      final confirmed = await confirmAction(
        context,
        title: "Delete Product",
        message: "Delete ${product.name}? It disappears from the store; past orders keep it.",
        confirmLabel: "Delete",
      );
      if (!confirmed || !context.mounted) return;
      final ok = await productVM.delete(product);
      if (!context.mounted) return;
      reportResult(context, ok: ok, errorMessage: productVM.errorMessage, success: "${product.name} deleted.");
    }

    // Loading State
    if (isDeletingThis) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SpinKitThreeBounce(color: Colors.red.shade300, size: 15),
      );
    }

    if (compact) {
      return IconButton(
        onPressed: canDelete ? onDelete : null,
        icon: Icon(Iconsax.trash, color: Colors.red.shade400, size: 20),
        tooltip: "Delete",
      );
    }

    return InkWell(
      onTap: canDelete ? onDelete : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Iconsax.trash, size: 16, color: Colors.red.shade400),
            const SizedBox(width: 6),
            Text("Delete", style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}