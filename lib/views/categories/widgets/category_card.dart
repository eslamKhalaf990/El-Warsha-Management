import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/categories/category_form_dialog.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/view_models/category_v_m.dart';

List<RowAction> _actions(BuildContext context, CategoryModel category) => [
      RowAction(label: 'Edit', icon: Iconsax.edit_2_copy, onPressed: () => openCategoryForm(context, category: category)),
      RowAction(label: 'Delete', icon: Iconsax.trash_copy, destructive: true, onPressed: () => _delete(context, category)),
    ];

Future<void> _delete(BuildContext context, CategoryModel category) async {
  if (category.productCount > 0) {
    showError(context, 'Move or delete the ${Fmt.count(category.productCount, 'product')} in "${category.name}" first.');
    return;
  }
  final vm = context.read<CategoryVM>();
  final confirmed = await confirmAction(
    context,
    title: 'Delete category?',
    message: '"${category.name}" will be removed from the store.',
    confirmLabel: 'Delete',
  );
  if (!confirmed || !context.mounted) return;
  final ok = await vm.delete(category);
  if (context.mounted) reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: '"${category.name}" deleted.');
}

Widget _productCount(CategoryModel c) => StatusPill(
      label: Fmt.count(c.productCount, 'product', none: 'No products'),
      tone: c.productCount == 0 ? Tone.neutral : Tone.brand,
      icon: Iconsax.box_1_copy,
    );

/// A category as a list row (phones).
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    return EntityTile(
      leading: AppNetworkImage(category.imageFullUrl, width: 52, height: 52),
      title: category.name,
      subtitle: category.description,
      meta: [_productCount(category)],
      actions: _actions(context, category),
      onTap: () => openCategoryForm(context, category: category),
    );
  }
}

/// A category as an image card (tablet and desktop grid).
class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => openCategoryForm(context, category: category),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: AppNetworkImage(category.imageFullUrl, radius: 0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s12, AppSpacing.s4, AppSpacing.s12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleSmall(category.name, maxLines: 1),
                      AppText.caption(
                        (category.description ?? '').isEmpty ? 'No description' : category.description!,
                        maxLines: 1,
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      _productCount(category),
                    ],
                  ),
                ),
                RowActions(_actions(context, category), forceMenu: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
