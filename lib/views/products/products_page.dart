import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/products/product_form_page.dart';
import 'package:warsha_app/views/products/widgets/product_card.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/category_v_m.dart';

/// The catalog: a searchable, filterable product grid.
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductVM>();
    final products = vm.products;
    final filtered = vm.query.trim().isNotEmpty || vm.categoryId != null || vm.stockFilter != StockFilter.all;

    return ModulePage(
      title: 'Products',
      subtitle: vm.hasLoaded
          ? [
              Fmt.count(vm.allProducts.length, 'product'),
              if (vm.lowStockCount > 0) '${vm.lowStockCount} low on stock',
              if (vm.outOfStockCount > 0) '${vm.outOfStockCount} out of stock',
            ].join(' · ')
          : 'Everything you sell in the store',
      primaryAction: PageAction(label: 'Add product', icon: Iconsax.add_copy, onPressed: () => openProductForm(context)),
      actions: [IconButton(tooltip: 'Refresh', icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch)],
      toolbar: const _Filters(),
      body: AsyncView(
        vm: vm,
        onRetry: vm.fetch,
        isEmpty: products.isEmpty,
        empty: filtered
            ? const EmptyView(
                icon: Iconsax.search_normal_1_copy,
                title: 'No products match',
                message: 'Try another word or clear the filters.',
              )
            : EmptyView(
                icon: Iconsax.box_1_copy,
                title: 'No products yet',
                message: 'Add your first product and it shows up in the store right away.',
                actionLabel: 'Add product',
                onAction: () => openProductForm(context),
              ),
        builder: (context) => RefreshIndicator(
          onRefresh: vm.fetch,
          child: GridView.builder(
            padding: listPadding(context),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: context.isCompact ? 220 : 260,
              mainAxisExtent: context.isCompact ? 280 : 320,
              crossAxisSpacing: AppSpacing.s12,
              mainAxisSpacing: AppSpacing.s12,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) => ProductCard(product: products[i]),
          ),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductVM>();
    final categories = context.watch<CategoryVM>().allCategories;
    final selected = categories.where((c) => c.categoryId == vm.categoryId).firstOrNull;

    final search = AppSearchField(hint: 'Search by name or SKU', initialValue: vm.query, onChanged: vm.setQuery);
    final category = AppDropdown<CategoryModel?>(
      label: 'Category',
      icon: Iconsax.category_2_copy,
      items: [null, ...categories],
      value: selected,
      hintText: 'All categories',
      itemLabel: (c) => c?.name ?? 'All categories',
      onChanged: (c) => vm.setCategory(c?.categoryId),
    );
    final stock = AppDropdown<StockFilter>(
      label: 'Stock',
      icon: Iconsax.box_1_copy,
      items: StockFilter.values,
      value: vm.stockFilter,
      itemLabel: (f) => switch (f) {
        StockFilter.all => 'All',
        StockFilter.low => 'Low (${vm.lowStockCount})',
        StockFilter.out => 'Out (${vm.outOfStockCount})',
      },
      onChanged: (f) => vm.setStockFilter(f ?? StockFilter.all),
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 860
          ? Row(children: [
              Expanded(child: search),
              const SizedBox(width: AppSpacing.s12),
              SizedBox(width: 240, child: category),
              const SizedBox(width: AppSpacing.s12),
              SizedBox(width: 180, child: stock),
            ])
          : Column(children: [
              search,
              const SizedBox(height: AppSpacing.s12),
              Row(children: [
                Expanded(flex: 3, child: category),
                const SizedBox(width: AppSpacing.s12),
                Expanded(flex: 2, child: stock),
              ]),
            ]),
    );
  }
}
