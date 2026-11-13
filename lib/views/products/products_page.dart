import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/products/product_form_page.dart';
import 'package:warsha_app/views/products/widgets/product_card.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/view_models/product_v_m.dart';
import 'package:warsha_app/view_models/category_v_m.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

/// The catalog: a searchable, filterable product grid.
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductVM>();
    final products = vm.products;
    final filtered = vm.query.trim().isNotEmpty || vm.categoryId != null || vm.stockFilter != StockFilter.all;

    return ModulePage(
      title: tr('Products'),
      subtitle: vm.hasLoaded
          ? [
              Fmt.count(vm.allProducts.length, 'product'),
              if (vm.lowStockCount > 0) tr('{0} low on stock', [vm.lowStockCount]),
              if (vm.outOfStockCount > 0) tr('{0} out of stock', [vm.outOfStockCount]),
            ].join(' · ')
          : tr('Everything you sell in the store'),
      primaryAction: PageAction(label: tr('Add product'), icon: Iconsax.add_copy, onPressed: () => openProductForm(context)),
      actions: [IconButton(tooltip: tr('Refresh'), icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch)],
      toolbar: const _Filters(),
      body: AsyncView(
        vm: vm,
        onRetry: vm.fetch,
        isEmpty: products.isEmpty,
        empty: filtered
            ? EmptyView(
                icon: Iconsax.search_normal_1_copy,
                title: tr('No products match'),
                message: tr('Try another word or clear the filters.'),
              )
            : EmptyView(
                icon: Iconsax.box_1_copy,
                title: tr('No products yet'),
                message: tr('Add your first product and it shows up in the store right away.'),
                actionLabel: tr('Add product'),
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

    final search = AppSearchField(hint: tr('Search by name or SKU'), initialValue: vm.query, onChanged: vm.setQuery);
    final category = AppDropdown<CategoryModel?>(
      label: tr('Category'),
      icon: Iconsax.category_2_copy,
      items: [null, ...categories],
      value: selected,
      hintText: tr('All categories'),
      itemLabel: (c) => c?.name ?? tr('All categories'),
      onChanged: (c) => vm.setCategory(c?.categoryId),
    );
    final stock = AppDropdown<StockFilter>(
      label: tr('Stock'),
      icon: Iconsax.box_1_copy,
      items: StockFilter.values,
      value: vm.stockFilter,
      itemLabel: (f) => switch (f) {
        StockFilter.all => tr('All'),
        StockFilter.low => tr('Low ({0})', [vm.lowStockCount]),
        StockFilter.out => tr('Out ({0})', [vm.outOfStockCount]),
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
