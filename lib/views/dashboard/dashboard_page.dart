import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/dashboard/widgets/ranked_bars.dart';
import 'package:warsha_app/views/dashboard/widgets/revenue_chart.dart';
import 'package:warsha_app/views/shell/destinations.dart';
import 'package:warsha_app/views/shell/navigation_v_m.dart';
import 'package:warsha_app/models/order_options.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/home_v_m.dart';
import 'package:warsha_app/view_models/order_v_m.dart';
import 'package:warsha_app/models/order_status.dart';

/// Sales at a glance: KPIs, the revenue trend, where sales come from, the
/// best products and the customers worth a call.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeVM>();
    return ModulePage(
      title: 'Dashboard',
      subtitle: 'How the workshop is doing',
      actions: [IconButton(tooltip: 'Refresh', icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch)],
      scrollable: vm.hasLoaded,
      body: AsyncView(
        vm: vm,
        onRetry: vm.fetch,
        isEmpty: false,
        empty: const SizedBox.shrink(),
        loading: const SkeletonList(count: 4, itemHeight: 140),
        builder: (context) => const _Content(),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeVM>();
    final wide = context.isExpanded;
    const gap = SizedBox(height: AppSpacing.s16, width: AppSpacing.s16);

    Widget pair(Widget a, Widget b) => wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), gap, Expanded(child: b)])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, gap, b]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vm.failedSections.isNotEmpty) ...[
          InlineBanner(
            message: "Some figures couldn't be loaded: ${vm.failedSections.join(', ')}.",
            actionLabel: 'Retry',
            onAction: vm.fetch,
          ),
          gap,
        ],
        const _Kpis(),
        gap,
        const _Attention(),
        DashboardPanel(
          title: 'Net revenue',
          subtitle: 'Per day, after discounts',
          icon: Iconsax.chart_2_copy,
          child: RevenueChart(days: vm.dailyRevenueReport ?? const []),
        ),
        gap,
        pair(const _Sources(), const _Regions()),
        gap,
        pair(const _TopProducts(), const _Segments()),
      ],
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeVM>();
    final days = vm.dailyRevenueReport ?? const [];
    final revenue = days.fold<double>(0, (s, d) => s + d.netRevenue);
    final orders = days.fold<int>(0, (s, d) => s + d.numberOfOrders);
    final discounts = days.fold<double>(0, (s, d) => s + d.totalDiscountsGiven);
    final summary = vm.revenueSummary;
    return ResponsiveGrid(
      minTileWidth: 180,
      spacing: AppSpacing.s12,
      children: [
        StatCard(
          label: 'Net revenue',
          value: Fmt.money(revenue),
          icon: Iconsax.money_recive_copy,
          highlighted: true,
          caption: discounts > 0 ? '${Fmt.money(discounts)} given in discounts' : 'In the report period',
        ),
        StatCard(label: 'Orders', value: Fmt.number(orders), icon: Iconsax.receipt_2_copy, caption: 'In the report period'),
        StatCard(
          label: 'Average order',
          value: Fmt.money(vm.averageBasketSize ?? 0),
          icon: Iconsax.shopping_bag_copy,
          caption: 'Per completed order',
        ),
        if (summary != null) ...[
          StatCard(
            label: 'Cash received',
            value: Fmt.money(summary.actualCashReceived),
            icon: Iconsax.wallet_check_copy,
            tone: Tone.success,
            caption: 'Paid so far',
          ),
          StatCard(
            label: 'Still to collect',
            value: Fmt.money(summary.expectedCash),
            icon: Iconsax.wallet_minus_copy,
            tone: Tone.warning,
            caption: 'On open orders',
          ),
        ],
      ],
    );
  }
}

/// Things that need someone today: pending orders and low stock. Hidden when
/// there are none.
class _Attention extends StatelessWidget {
  const _Attention();

  @override
  Widget build(BuildContext context) {
    final pending = context.select<OrderVM, int>((vm) => vm.statusCounts[OrderStatus.pending] ?? 0);
    final products = context.watch<ProductVM>();
    final low = products.lowStockCount + products.outOfStockCount;
    if (pending == 0 && low == 0) return const SizedBox.shrink();
    final nav = context.read<NavigationVM>();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Wrap(
        spacing: AppSpacing.s12,
        runSpacing: AppSpacing.s12,
        children: [
          if (pending > 0)
            ActionChip(
              avatar: const Icon(Iconsax.clock_copy, size: 16, color: AppStatusColors.warningText),
              label: Text('${Fmt.count(pending, 'order')} waiting to be processed'),
              onPressed: () {
                context.read<OrderVM>().setStatusFilter(OrderStatus.pending);
                nav.go(AppDestination.orders);
              },
            ),
          if (low > 0)
            ActionChip(
              avatar: const Icon(Iconsax.box_remove_copy, size: 16, color: AppStatusColors.errorText),
              label: Text('${Fmt.count(low, 'product')} low or out of stock'),
              onPressed: () {
                products.setStockFilter(products.outOfStockCount > 0 ? StockFilter.out : StockFilter.low);
                nav.go(AppDestination.products);
              },
            ),
        ],
      ),
    );
  }
}

class _Sources extends StatelessWidget {
  const _Sources();

  @override
  Widget build(BuildContext context) {
    final sources = [...?context.watch<HomeVM>().revenueBySource]..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    return DashboardPanel(
      title: 'Where sales come from',
      subtitle: 'Revenue by order source',
      icon: Iconsax.global_copy,
      child: RankedBars(
        items: [
          for (final s in sources)
            RankedItem(
              label: optionLabel(orderSources, s.orderSource),
              value: s.totalRevenue,
              valueLabel: Fmt.money(s.totalRevenue),
              caption: '${Fmt.count(s.totalOrders, 'order')} · avg ${Fmt.money(s.averageOrderValue)}',
            ),
        ],
      ),
    );
  }
}

class _Regions extends StatelessWidget {
  const _Regions();

  @override
  Widget build(BuildContext context) {
    final regions = [...?context.watch<HomeVM>().governoratePerformance]
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    return DashboardPanel(
      title: 'Top governorates',
      subtitle: 'Revenue by delivery area',
      icon: Iconsax.map_1_copy,
      child: RankedBars(
        items: [
          for (final r in regions.take(8))
            RankedItem(
              label: r.governorate,
              value: r.totalRevenue,
              valueLabel: Fmt.money(r.totalRevenue),
              caption: Fmt.count(r.totalOrders, 'order'),
            ),
        ],
      ),
    );
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts();

  @override
  Widget build(BuildContext context) {
    final products = [...?context.watch<HomeVM>().topProducts]..sort((a, b) => b.totalSold.compareTo(a.totalSold));
    return DashboardPanel(
      title: 'Best sellers',
      subtitle: 'Pieces sold',
      icon: Iconsax.crown_1_copy,
      child: RankedBars(
        items: [
          for (final p in products.take(8))
            RankedItem(
              label: p.name,
              value: p.totalSold.toDouble(),
              valueLabel: Fmt.count(p.totalSold, 'piece'),
              caption: 'Profit ${Fmt.money(p.totalProfit)}',
            ),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeVM>();
    Widget segment(String title, String hint, IconData icon, Tone tone, List<(String, String)> rows) => ExpansionTile(
          tilePadding: EdgeInsets.zero,
          shape: const Border(),
          leading: IconBadge(icon, tone: tone, size: 32),
          title: AppText.label(title),
          subtitle: AppText.caption(hint),
          trailing: StatusPill(label: '${rows.length}', tone: tone),
          children: [
            if (rows.isEmpty) const Padding(padding: EdgeInsets.all(AppSpacing.s8), child: AppText.caption('No one here yet.')),
            for (final (name, detail) in rows.take(10)) InfoRow(label: name, value: detail),
          ],
        );
    return DashboardPanel(
      title: 'Customers',
      subtitle: 'Who to thank, reward or win back',
      icon: Iconsax.profile_2user_copy,
      child: Column(
        children: [
          segment('VIP', 'Highest lifetime spend', Iconsax.crown_1_copy, Tone.brand, [
            for (final c in vm.vipCustomers ?? const []) (c.fullName, Fmt.money(c.totalLifetimeSpend)),
          ]),
          segment('Loyal', 'Order again and again', Iconsax.heart_copy, Tone.success, [
            for (final c in vm.loyalCustomers ?? const []) (c.fullName, Fmt.count(c.orderCount, 'order')),
          ]),
          segment('At risk', 'Haven’t ordered in a while', Iconsax.timer_pause_copy, Tone.warning, [
            for (final c in vm.atRiskCustomers ?? const []) (c.fullName, '${c.daysSinceLastOrder} days ago'),
          ]),
          segment('Discount lovers', 'Mostly buy on discount', Iconsax.discount_shape_copy, Tone.info, [
            for (final c in vm.discountSeekers ?? const []) (c.fullName, Fmt.money(c.totalDiscountsReceived)),
          ]),
        ],
      ),
    );
  }
}
