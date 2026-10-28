import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/category_v_m.dart';
import 'package:warsha_app/views/categories/add_category.dart';

class CategoryWidget extends StatelessWidget {
  final CategoryModel category;

  const CategoryWidget({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
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
            bool isDesktop = constraints.maxWidth > 600;

            return isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context);
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Row(
      children: [
        _buildCategoryIcon(context),
        const SizedBox(width: 16),
        Expanded(child: _buildTitle(16)),
        _buildEditButton(context),
        _buildDeleteButton(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _buildCategoryIcon(context),
        const SizedBox(width: 20),
        Expanded(child: _buildTitle(18)),
        _buildEditButton(context),
        _buildDeleteButton(context),
      ],
    );
  }

  Widget _buildTitle(double size) {
    final count = category.productCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultText(txt: category.name, size: size, bold: true, center: false),
        const SizedBox(height: 2),
        Text(
          count == 0
              ? "No products"
              : count == 1
                  ? "1 product"
                  : "$count products",
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return IconButton(
      tooltip: "Edit",
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddCategory(category: category)),
      ),
      icon: Icon(Iconsax.edit, color: Theme.of(context).colorScheme.tertiary, size: 22),
    );
  }

  Widget _buildCategoryIcon(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Iconsax.category_copy,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    final categoryVM = context.read<CategoryVM>();

    return IconButton(
      tooltip: "Delete",
      onPressed: () async {
        final confirm = await _showDeleteDialog(context);
        if (confirm != true || !context.mounted) return;
        final ok = await categoryVM.delete(category);
        if (!context.mounted) return;
        if (ok) {
          showSuccess(context, '"${category.name}" deleted.');
        } else {
          showError(context, categoryVM.errorMessage!);
        }
      },
      icon: const Icon(Iconsax.trash, color: Colors.red, size: 24),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text("Are you sure you want to delete ${category.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
