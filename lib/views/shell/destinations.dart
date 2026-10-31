import 'package:flutter/widgets.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/views/accounting/accounting_page.dart';
import 'package:warsha_app/views/categories/categories_page.dart';
import 'package:warsha_app/views/customers/customers_page.dart';
import 'package:warsha_app/views/dashboard/dashboard_page.dart';
import 'package:warsha_app/views/orders/orders_page.dart';
import 'package:warsha_app/views/products/products_page.dart';
import 'package:warsha_app/views/reviews/reviews_page.dart';
import 'package:warsha_app/views/shipping_zones/shipping_zones_page.dart';
import 'package:warsha_app/views/vendors/vendors_page.dart';
import 'package:warsha_app/views/vouchers/vouchers_page.dart';

/// Sidebar groups, in order.
enum NavGroup {
  overview('Overview'),
  sales('Sales'),
  catalog('Catalog'),
  operations('Operations'),
  finance('Finance');

  const NavGroup(this.label);
  final String label;
}

/// Every top-level page of the ERP, grouped like the sidebar shows them.
enum AppDestination {
  dashboard('Dashboard', Iconsax.element_3_copy, Iconsax.element_3, NavGroup.overview),
  orders('Orders', Iconsax.receipt_2_copy, Iconsax.receipt_2, NavGroup.sales),
  customers('Customers', Iconsax.profile_2user_copy, Iconsax.profile_2user, NavGroup.sales),
  vouchers('Promo codes', Iconsax.ticket_discount_copy, Iconsax.ticket_discount, NavGroup.sales),
  products('Products', Iconsax.box_1_copy, Iconsax.box_1, NavGroup.catalog),
  categories('Categories', Iconsax.category_2_copy, Iconsax.category_2, NavGroup.catalog),
  reviews('Reviews', Iconsax.message_text_copy, Iconsax.message_text, NavGroup.catalog),
  vendors('Vendors', Iconsax.shop_copy, Iconsax.shop, NavGroup.operations),
  shippingZones('Shipping zones', Iconsax.truck_copy, Iconsax.truck, NavGroup.operations),
  accounting('Accounting', Iconsax.wallet_2_copy, Iconsax.wallet_2, NavGroup.finance);

  const AppDestination(this.label, this.icon, this.selectedIcon, this.group);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final NavGroup group;

  /// The four pages in the phone's bottom bar; the rest are under "More".
  static const primary = [dashboard, orders, products, customers];

  Widget get page => switch (this) {
        dashboard => const DashboardPage(),
        orders => const OrdersPage(),
        customers => const CustomersPage(),
        vouchers => const VouchersPage(),
        products => const ProductsPage(),
        categories => const CategoriesPage(),
        reviews => const ReviewsPage(),
        vendors => const VendorsPage(),
        shippingZones => const ShippingZonesPage(),
        accounting => const AccountingPage(),
      };
}
