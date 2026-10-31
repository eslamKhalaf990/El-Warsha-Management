import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/customers/customer_form_page.dart';
import 'package:warsha_app/views/products/widgets/product_card.dart';
import 'package:warsha_app/models/customer_model.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/models/product_variant.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';

/// Search-as-you-type for a customer, with "New customer" always offered.
class CustomerPicker extends StatelessWidget {
  const CustomerPicker({super.key, required this.onSelected, this.errorText});

  final ValueChanged<CustomerModel> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CustomerVM>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchAnchor(
          viewHintText: 'Name, mobile or #number',
          isFullScreen: context.isCompact,
          viewBackgroundColor: AppColors.white,
          builder: (_, controller) => _SearchBox(
            hint: vm.hasLoaded ? 'Find a customer by name or mobile' : 'Loading customers…',
            icon: Iconsax.user_search_copy,
            errorText: errorText,
            onTap: controller.openView,
          ),
          suggestionsBuilder: (_, controller) {
            final query = controller.text;
            final digits = CustomerVM.normalizePhone(query);
            return [
              ListTile(
                leading: const IconBadge(Iconsax.user_add_copy, size: 36),
                title: const Text('New customer'),
                subtitle: Text(query.trim().isEmpty ? 'Add someone who isn’t in the list' : 'Add “${query.trim()}”'),
                onTap: () async {
                  controller.closeView('');
                  final created = await openCustomerForm(
                    context,
                    phone: RegExp(r'^\d{6,}$').hasMatch(digits) ? digits : null,
                  );
                  if (created != null) onSelected(created);
                },
              ),
              for (final c in vm.search(query, limit: 30))
                ListTile(
                  leading: InitialsAvatar(Fmt.initials(c.fullName), size: 36),
                  title: Text(c.fullName),
                  subtitle: Text([c.phone, c.governorate].where((s) => s.trim().isNotEmpty).join(' · ')),
                  onTap: () {
                    controller.closeView('');
                    onSelected(c);
                  },
                ),
            ];
          },
        ),
      ],
    );
  }
}

/// Search-as-you-type for a product; products with sizes / colors ask which
/// one. Shows price and stock so staff can pick without opening Products.
class ProductPicker extends StatelessWidget {
  const ProductPicker({super.key, required this.onSelected, this.errorText});

  final void Function(ProductModel product, ProductVariant? variant) onSelected;
  final String? errorText;

  Future<void> _pick(BuildContext context, ProductModel p) async {
    if (!p.hasVariants) return onSelected(p, null);
    final variant = await showDialog<ProductVariant>(
      context: context,
      builder: (_) => AppDialog(
        title: p.name,
        icon: Iconsax.color_swatch_copy,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppText.bodySmall('Which size / color?', color: AppColors.muted),
            const SizedBox(height: AppSpacing.s12),
            for (final v in p.variants)
              ListTile(
                enabled: v.inStock,
                title: Text(v.label),
                subtitle: Text(Fmt.money(v.totalPrice)),
                trailing: StockPill(v.quantity),
                onTap: () => Navigator.pop(context, v),
              ),
          ],
        ),
        actions: [AppButton.text(label: 'Cancel', onPressed: () => Navigator.pop(context))],
      ),
    );
    if (variant != null) onSelected(p, variant);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductVM>();
    return SearchAnchor(
      viewHintText: 'Product name or SKU',
      isFullScreen: context.isCompact,
      viewBackgroundColor: AppColors.white,
      builder: (_, controller) => _SearchBox(
        hint: vm.hasLoaded ? 'Add a product by name or SKU' : 'Loading products…',
        icon: Iconsax.box_add_copy,
        errorText: errorText,
        onTap: controller.openView,
      ),
      suggestionsBuilder: (_, controller) => [
        for (final p in vm.search(controller.text, limit: 30))
          ListTile(
            enabled: ProductVM.stockOf(p) > 0,
            leading: AppNetworkImage(p.imageFullUrl, width: 44, height: 44),
            title: Text(p.name),
            subtitle: Text([
              Fmt.money(p.finalPrice),
              if (p.hasVariants) Fmt.count(p.variants.length, 'option'),
            ].join(' · ')),
            trailing: StockPill(ProductVM.stockOf(p)),
            onTap: () {
              controller.closeView('');
              _pick(context, p);
            },
          ),
      ],
    );
  }
}

/// Looks like a search field; opens the picker's search view when tapped.
class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint, required this.icon, required this.onTap, this.errorText});

  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.inputBorderRadius,
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: const Icon(Iconsax.search_normal_1_copy, size: 18),
          errorText: errorText,
        ),
        child: Text(hint, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
      ),
    );
  }
}
