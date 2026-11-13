import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/categories/category_form_dialog.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/view_models/category_v_m.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

List<RowAction> _actions(BuildContext context, CategoryModel category) => [
      RowAction(label: tr('Edit'), icon: Iconsax.edit_2_copy, onPressed: () => openCategoryForm(context, category: category)),
      RowAction(label: tr('Delete'), icon: Iconsax.trash_copy, destructive: true, onPressed: () => _delete(context, category)),
    ];

Future<void> _delete(BuildContext context, CategoryModel category) async {
  if (category.productCount > 0) {
    showError(context, tr('Move or delete the {0} in "{1}" first.', [Fmt.count(category.productCount, 'product'), category.name]));
    return;
  }
  final vm = context.read<CategoryVM>();
  final confirmed = await confirmAction(
    context,
    title: tr('Delete category?'),
    message: tr('"{0}" will be removed from the store.', [category.name]),
    confirmLabel: tr('Delete'),
  );
  if (!confirmed || !context.mounted) return;
  final ok = await vm.delete(category);
  if (context.mounted) reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: tr('"{0}" deleted.', [category.name]));
}

Widget _productCount(CategoryModel c) => StatusPill(
      label: Fmt.count(c.productCount, 'product', none: tr('No products')),
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
            padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.s16, AppSpacing.s12, AppSpacing.s4, AppSpacing.s12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleSmall(category.name, maxLines: 1),
                      AppText.caption(
                        (category.description ?? '').isEmpty ? tr('No description') : category.description!,
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
