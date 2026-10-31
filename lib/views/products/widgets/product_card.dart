import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/products/product_form_page.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';

/// Stock as a colored pill: out, low, or the count.
class StockPill extends StatelessWidget {
  const StockPill(this.stock, {super.key});

  final int stock;

  @override
  Widget build(BuildContext context) {
    if (stock <= 0) return const StatusPill(label: 'Out of stock', tone: Tone.error);
    if (stock <= ProductVM.lowStockThreshold) {
      return StatusPill(label: 'Only $stock left', tone: Tone.warning, icon: Iconsax.warning_2_copy);
    }
    return StatusPill(label: '$stock in stock', tone: Tone.success);
  }
}

/// Final price, with the price before discount struck through.
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.price, this.before});

  final double price;
  final double? before;

  @override
  Widget build(BuildContext context) {
    final discounted = before != null && before! > price;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.s8,
      children: [
        AppText.price(Fmt.money(price), color: AppColors.burgundy),
        if (discounted)
          Text(
            Fmt.money(before),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(decoration: TextDecoration.lineThrough),
          ),
      ],
    );
  }
}

/// A product in the catalog grid: image, stock, name, category and price.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final ProductModel product;

  Future<void> _delete(BuildContext context) async {
    final vm = context.read<ProductVM>();
    final confirmed = await confirmAction(
      context,
      title: 'Delete product?',
      message: '"${product.name}" will be removed from the store. Past orders keep it.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await vm.delete(product);
    if (context.mounted) reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: '"${product.name}" deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final p = product;
    final deleting = context.select<ProductVM, bool>((vm) => vm.deletingId == p.id);
    final stock = ProductVM.stockOf(p);

    return Opacity(
      opacity: deleting ? 0.5 : 1,
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: deleting ? null : () => openProductForm(context, product: p),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(p.imageFullUrl, radius: 0),
                  PositionedDirectional(top: AppSpacing.s8, start: AppSpacing.s8, child: StockPill(stock)),
                  if (p.discountValue > 0)
                    PositionedDirectional(
                      top: AppSpacing.s8,
                      end: AppSpacing.s8,
                      child: StatusPill(label: '−${Fmt.money(p.discountValue)}', tone: Tone.brand),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s12, AppSpacing.s8, 0, AppSpacing.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.label(p.name, maxLines: 1),
                        AppText.caption(
                          [
                            if (p.category.isNotEmpty) p.category,
                            if (p.hasVariants) Fmt.count(p.variants.length, 'option'),
                          ].join(' · '),
                          maxLines: 1,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        PriceTag(price: p.finalPrice, before: p.sellingPriceValue),
                      ],
                    ),
                  ),
                  RowActions(
                    [
                      RowAction(label: 'Edit', icon: Iconsax.edit_2_copy, onPressed: () => openProductForm(context, product: p)),
                      RowAction(label: 'Delete', icon: Iconsax.trash_copy, destructive: true, onPressed: () => _delete(context)),
                    ],
                    busy: deleting,
                    forceMenu: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
