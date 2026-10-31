import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/categories/category_form_dialog.dart';
import 'package:warsha_app/views/categories/widgets/category_card.dart';
import 'package:warsha_app/view_models/category_v_m.dart';

/// Categories: a searchable image grid (a list on phones).
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryVM>();
    final categories = vm.categories;
    final products = vm.allCategories.fold<int>(0, (sum, c) => sum + c.productCount);

    return ModulePage(
      title: 'Categories',
      subtitle: vm.hasLoaded
          ? '${Fmt.count(vm.allCategories.length, 'category', plural: 'categories')} · ${Fmt.count(products, 'product')}'
          : 'How products are grouped in the store',
      primaryAction: PageAction(label: 'Add category', icon: Iconsax.add_copy, onPressed: () => openCategoryForm(context)),
      actions: [IconButton(tooltip: 'Refresh', icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch)],
      toolbar: AppSearchField(hint: 'Search categories', initialValue: vm.query, onChanged: vm.search),
      body: AsyncView(
        vm: vm,
        onRetry: vm.fetch,
        isEmpty: categories.isEmpty,
        empty: vm.query.trim().isNotEmpty
            ? EmptyView.noMatch(vm.query)
            : EmptyView(
                icon: Iconsax.category_2_copy,
                title: 'No categories yet',
                message: 'Group your products so customers can find them easily.',
                actionLabel: 'Add category',
                onAction: () => openCategoryForm(context),
              ),
        builder: (context) => context.isCompact
            ? TileList(items: categories, onRefresh: vm.fetch, itemBuilder: (_, c) => CategoryTile(category: c))
            : GridView.builder(
                padding: listPadding(context),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisExtent: 260,
                  crossAxisSpacing: AppSpacing.s16,
                  mainAxisSpacing: AppSpacing.s16,
                ),
                itemCount: categories.length,
                itemBuilder: (_, i) => CategoryCard(category: categories[i]),
              ),
      ),
    );
  }
}
