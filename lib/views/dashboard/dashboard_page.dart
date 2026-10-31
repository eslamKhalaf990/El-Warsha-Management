import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/analytics.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/analytics_v_m.dart';
import 'package:warsha_app/view_models/order_v_m.dart';
import 'package:warsha_app/views/dashboard/widgets/ranked_bars.dart';
import 'package:warsha_app/views/dashboard/widgets/trend_chart.dart';
import 'package:warsha_app/views/shell/destinations.dart';
import 'package:warsha_app/views/shell/navigation_v_m.dart';

/// The business in numbers for a chosen range: KPIs against the previous
/// period, the sales trend, products and stock, channels and regions,
/// customers, and cash.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnalyticsVM>();
    return ModulePage(
      title: 'Dashboard',
      subtitle: _rangeText(vm),
      actions: [IconButton(tooltip: 'Refresh', icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch)],
      toolbar: const _RangeBar(),
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

  static String _rangeText(AnalyticsVM vm) {
    final p = vm.overview?.period;
    final from = p?.from ?? vm.from;
    final range = from == null ? 'All time' : '${Fmt.date(from)} – ${Fmt.date(p?.to ?? vm.to)}';
    return p?.previousFrom == null ? range : '$range · compared with the ${Fmt.count(p!.days, 'day')} before';
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar();

  Future<void> _pickCustom(BuildContext context) async {
    final vm = context.read<AnalyticsVM>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: vm.from ?? DateTime.now().subtract(const Duration(days: 29)), end: vm.to),
    );
    if (range != null) vm.setCustomRange(range.start, range.end);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnalyticsVM>();
    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.s8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.ink),
            onSelected: vm.isLoading ? null : (_) => onTap(),
          ),
        );
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final p in RangePreset.values.where((p) => p != RangePreset.custom))
            chip(p.label, vm.preset == p, () => vm.setPreset(p)),
          chip(vm.preset == RangePreset.custom ? '${Fmt.shortDate(vm.from)} – ${Fmt.shortDate(vm.to)}' : 'Custom…',
              vm.preset == RangePreset.custom, () => _pickCustom(context)),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnalyticsVM>();
    const gap = SizedBox(height: AppSpacing.s16, width: AppSpacing.s16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vm.isLoading) const Padding(padding: EdgeInsets.only(bottom: AppSpacing.s12), child: LinearProgressIndicator(minHeight: 2)),
        if (vm.failedSections.isNotEmpty) ...[
          InlineBanner(
            message: "Some figures couldn't be loaded: ${vm.failedSections.join(', ')}.",
            actionLabel: 'Retry',
            onAction: vm.fetch,
          ),
          gap,
        ],
        const _Attention(),
        const _Kpis(),
        gap,
        const _Trend(),
        gap,
        const _Pair(_Channels(), _Regions()),
        gap,
        const _Pair(_Categories(), _TopProducts()),
        gap,
        const _Pair(_RunningLow(), _SlowMovers()),
        gap,
        const _Pair(_Customers(), _Cash()),
        gap,
        const _Pair(_Weekdays(), _Statuses()),
      ],
    );
  }
}

/// Two panels side by side on wide screens, stacked otherwise.
class _Pair extends StatelessWidget {
  const _Pair(this.a, this.b);

  final Widget a;
  final Widget b;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.s16, width: AppSpacing.s16);
    return context.isExpanded
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), gap, Expanded(child: b)])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, gap, b]);
  }
}

/// "+12% vs before" as a pill: green when the change is good, red when bad.
class _Delta extends StatelessWidget {
  const _Delta(this.current, this.previous, {this.higherIsBetter = true});

  final num current;
  final num? previous;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final change = AnalyticsVM.change(current, previous);
    if (change == null) return const SizedBox.shrink();
    final good = higherIsBetter ? change >= 0 : change <= 0;
    return Tooltip(
      message: 'Previous period: ${Fmt.number(previous)}',
      child: StatusPill(label: Fmt.change(change), tone: change.abs() < 0.005 ? Tone.neutral : (good ? Tone.success : Tone.error)),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis();

  @override
  Widget build(BuildContext context) {
    final overview = context.watch<AnalyticsVM>().overview;
    final k = overview?.current ?? const Kpis();
    final p = overview?.previous;
    return ResponsiveGrid(
      minTileWidth: 200,
      spacing: AppSpacing.s12,
      children: [
        StatCard(
          label: 'Net sales',
          value: Fmt.money(k.netSales),
          icon: Iconsax.money_recive_copy,
          highlighted: true,
          caption: k.discounts > 0 ? 'After ${Fmt.money(k.discounts)} discounts' : 'Items sold, after discounts',
          trailing: _Delta(k.netSales, p?.netSales),
        ),
        StatCard(
          label: 'Gross profit',
          value: Fmt.money(k.grossProfit),
          icon: Iconsax.chart_success_copy,
          tone: Tone.success,
          caption: '${Fmt.percent(k.grossMargin)} margin',
          trailing: _Delta(k.grossProfit, p?.grossProfit),
        ),
        StatCard(
          label: 'Orders',
          value: Fmt.number(k.orders),
          icon: Iconsax.receipt_2_copy,
          caption: '${Fmt.count(k.units, 'piece')} · ${Fmt.number(k.itemsPerOrder)} per order',
          trailing: _Delta(k.orders, p?.orders),
        ),
        StatCard(
          label: 'Average order',
          value: Fmt.money(k.averageOrderValue),
          icon: Iconsax.shopping_bag_copy,
          caption: 'Incl. ${Fmt.money(k.deliveryFees)} delivery in total',
          trailing: _Delta(k.averageOrderValue, p?.averageOrderValue),
        ),
        StatCard(
          label: 'Customers',
          value: Fmt.number(k.customers),
          icon: Iconsax.profile_2user_copy,
          tone: Tone.info,
          caption: '${k.newCustomers} new · ${k.returningCustomers} returning',
          trailing: _Delta(k.customers, p?.customers),
        ),
        StatCard(
          label: 'Collected',
          value: Fmt.money(k.collected),
          icon: Iconsax.wallet_check_copy,
          tone: Tone.success,
          caption: 'Down payments + completed orders',
        ),
        StatCard(
          label: 'Still to collect',
          value: Fmt.money(k.outstanding),
          icon: Iconsax.wallet_minus_copy,
          tone: Tone.warning,
          caption: 'On orders not completed yet',
        ),
        StatCard(
          label: 'Cancelled',
          value: Fmt.percent(k.cancellationRate, decimals: 1),
          icon: Iconsax.close_circle_copy,
          tone: Tone.error,
          caption: Fmt.count(k.cancelledOrders, 'order'),
          trailing: _Delta(k.cancellationRate, p?.cancellationRate, higherIsBetter: false),
        ),
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

class _Trend extends StatefulWidget {
  const _Trend();

  @override
  State<_Trend> createState() => _TrendState();
}

class _TrendState extends State<_Trend> {
  TrendMeasure _measure = TrendMeasure.netSales;

  @override
  Widget build(BuildContext context) {
    final trend = context.watch<AnalyticsVM>().trend;
    final per = switch (trend?.granularity) { 'week' => 'Per week (from Saturday)', 'month' => 'Per month', _ => 'Per day' };
    return DashboardPanel(
      title: 'Sales over time',
      subtitle: per,
      icon: Iconsax.chart_2_copy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SegmentedButton<TrendMeasure>(
              segments: [for (final m in TrendMeasure.values) ButtonSegment(value: m, label: Text(m.label))],
              selected: {_measure},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _measure = s.first),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          TrendChart(trend: trend, measure: _measure),
        ],
      ),
    );
  }
}

class _Channels extends StatelessWidget {
  const _Channels();

  @override
  Widget build(BuildContext context) {
    final channels = context.watch<AnalyticsVM>().channels ?? const [];
    return DashboardPanel(
      title: 'Sales channels',
      subtitle: 'Net sales by where the order came from',
      icon: Iconsax.global_copy,
      child: RankedBars(
        emptyText: 'No orders in this period.',
        items: [
          for (final c in channels)
            RankedItem(
              label: '${c.channel} · ${Fmt.percent(c.share)}',
              value: c.netSales,
              valueLabel: Fmt.money(c.netSales),
              caption: '${Fmt.count(c.orders, 'order')} · avg ${Fmt.money(c.averageOrderValue)}'
                  '${c.cancelled > 0 ? ' · ${Fmt.percent(c.cancellationRate)} cancelled' : ''}',
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
    final regions = context.watch<AnalyticsVM>().regions ?? const [];
    final rest = regions.skip(8).fold<double>(0, (s, r) => s + r.share);
    return DashboardPanel(
      title: 'Top governorates',
      subtitle: rest > 0 ? 'Top 8 · the other ${regions.length - 8} make ${Fmt.percent(rest)}' : 'Net sales by delivery area',
      icon: Iconsax.map_1_copy,
      child: RankedBars(
        emptyText: 'No orders in this period.',
        items: [
          for (final r in regions.take(8))
            RankedItem(
              label: '${r.governorate} · ${Fmt.percent(r.share)}',
              value: r.netSales,
              valueLabel: Fmt.money(r.netSales),
              caption: '${Fmt.count(r.orders, 'order')} · ${Fmt.count(r.customers, 'customer')} · avg ${Fmt.money(r.averageOrderValue)}',
            ),
        ],
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories();

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AnalyticsVM>().products?.categories ?? const [];
    return DashboardPanel(
      title: 'Categories',
      subtitle: 'Net sales and margin',
      icon: Iconsax.category_copy,
      child: RankedBars(
        emptyText: 'Nothing sold in this period.',
        items: [
          for (final c in categories)
            RankedItem(
              label: '${c.category} · ${Fmt.percent(c.share)}',
              value: c.netSales,
              valueLabel: Fmt.money(c.netSales),
              caption: '${Fmt.count(c.units, 'piece')} · profit ${Fmt.money(c.grossProfit)} (${Fmt.percent(c.grossMargin)})',
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
    final products = context.watch<AnalyticsVM>().products?.topProducts ?? const [];
    return DashboardPanel(
      title: 'Best sellers',
      subtitle: 'Top 10 by net sales',
      icon: Iconsax.crown_1_copy,
      child: RankedBars(
        emptyText: 'Nothing sold in this period.',
        items: [
          for (final p in products.take(10))
            RankedItem(
              label: p.name,
              value: p.netSales,
              valueLabel: Fmt.money(p.netSales),
              caption: '${Fmt.count(p.units, 'piece')} · ${Fmt.percent(p.grossMargin)} margin'
                  '${p.stock == null ? '' : ' · ${p.stock} left'}',
            ),
        ],
      ),
    );
  }
}

/// Plain "label … value" list for the stock and customer panels.
class _Rows extends StatelessWidget {
  const _Rows({required this.rows, required this.emptyText});

  final List<(String, String, String?)> rows;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
        child: Center(child: AppText.bodySmall(emptyText, color: AppColors.muted)),
      );
    }
    return Column(
      children: [
        for (final (i, (label, value, caption)) in rows.indexed) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodySmall(label, maxLines: 1),
                      if (caption != null) AppText.caption(caption, maxLines: 1),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                AppText.label(value),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RunningLow extends StatelessWidget {
  const _RunningLow();

  @override
  Widget build(BuildContext context) {
    final low = context.watch<AnalyticsVM>().products?.runningLow ?? const [];
    return DashboardPanel(
      title: 'Running low',
      subtitle: 'Stock lasts under 3 weeks at this period’s pace',
      icon: Iconsax.box_remove_copy,
      child: _Rows(
        emptyText: 'Nothing is running low.',
        rows: [
          for (final p in low.take(8))
            (
              p.name,
              (p.stock ?? 0) <= 0 ? 'Out of stock' : '~${p.daysOfCover!.round()} days',
              '${p.stock ?? 0} left · ${Fmt.count(p.units, 'piece')} sold',
            ),
        ],
      ),
    );
  }
}

class _SlowMovers extends StatelessWidget {
  const _SlowMovers();

  @override
  Widget build(BuildContext context) {
    final slow = context.watch<AnalyticsVM>().products?.slowMovers ?? const [];
    final tied = slow.fold<double>(0, (s, p) => s + p.stockValue);
    return DashboardPanel(
      title: 'Not selling',
      subtitle: slow.isEmpty ? 'In stock but no sales in this period' : '${Fmt.money(tied)} of stock at cost with no sales in this period',
      icon: Iconsax.timer_pause_copy,
      child: _Rows(
        emptyText: 'Every product in stock sold something.',
        rows: [
          for (final p in slow)
            (p.name, Fmt.money(p.stockValue), '${p.stock} in stock · last sold ${p.lastSold == null ? 'never' : Fmt.date(p.lastSold)}'),
        ],
      ),
    );
  }
}

class _Customers extends StatelessWidget {
  const _Customers();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AnalyticsVM>().customers ?? const CustomerInsights();
    return DashboardPanel(
      title: 'Customers',
      subtitle: '${c.newCustomers} new · ${c.returningCustomers} returning · ${Fmt.percent(c.repeatRate)} have ordered more than once',
      icon: Iconsax.profile_2user_copy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoRow(label: 'Average spend per customer', value: Fmt.money(c.averageSpend)),
          const SizedBox(height: AppSpacing.s8),
          const AppText.label('Top spenders'),
          _Rows(
            emptyText: 'No customers in this period.',
            rows: [
              for (final t in c.topCustomers)
                (
                  t.name,
                  Fmt.money(t.spend),
                  [Fmt.count(t.orders, 'order'), if (t.governorate != null) t.governorate!, if (t.phone != null) t.phone!].join(' · '),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cash extends StatelessWidget {
  const _Cash();

  @override
  Widget build(BuildContext context) {
    final cash = context.watch<AnalyticsVM>().cash ?? const CashInsights();
    final total = cash.collected + cash.outstanding;
    return DashboardPanel(
      title: 'Cash',
      subtitle: total == 0 ? 'Collected and still to collect' : '${Fmt.percent(cash.collected / total)} of the order value is collected',
      icon: Iconsax.wallet_money_copy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoRow(label: 'Collected', value: Fmt.money(cash.collected), valueColor: AppStatusColors.successText),
          InfoRow(label: 'Still to collect', value: Fmt.money(cash.outstanding), valueColor: AppStatusColors.warningText),
          const SizedBox(height: AppSpacing.s12),
          const AppText.label('How down payments were made'),
          RankedBars(
            emptyText: 'No down payments in this period.',
            items: [
              for (final m in cash.paymentMethods)
                RankedItem(
                  label: '${m.method} · ${Fmt.percent(m.share)}',
                  value: m.amount,
                  valueLabel: Fmt.money(m.amount),
                  caption: Fmt.count(m.orders, 'order'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Weekdays extends StatelessWidget {
  const _Weekdays();

  @override
  Widget build(BuildContext context) {
    final days = context.watch<AnalyticsVM>().cash?.weekdays ?? const [];
    final busiest = days.isEmpty ? null : days.reduce((a, b) => b.orders > a.orders ? b : a);
    return DashboardPanel(
      title: 'Busiest days',
      subtitle: busiest == null || busiest.orders == 0 ? 'Orders per weekday' : '${busiest.weekday} brings the most orders',
      icon: Iconsax.calendar_1_copy,
      child: WeekdayChart(days: days),
    );
  }
}

class _Statuses extends StatelessWidget {
  const _Statuses();

  @override
  Widget build(BuildContext context) {
    final statuses = context.watch<AnalyticsVM>().cash?.statuses ?? const <StatusTotal>[];
    return DashboardPanel(
      title: 'Order pipeline',
      subtitle: 'Orders placed in this period, by where they are now',
      icon: Iconsax.task_square_copy,
      child: _Rows(
        emptyText: 'No orders in this period.',
        rows: [
          for (final s in statuses)
            (
              s.status,
              Fmt.count(s.orders, 'order'),
              '${Fmt.money(s.orderValue)}${s.outstanding > 0 ? ' · ${Fmt.money(s.outstanding)} to collect' : ''}',
            ),
        ],
      ),
    );
  }
}
