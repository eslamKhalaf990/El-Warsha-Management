import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/analytics.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/view_models/product_v_m.dart';
import 'package:warsha_app/view_models/analytics_v_m.dart';
import 'package:warsha_app/view_models/order_v_m.dart';
import 'package:warsha_app/views/dashboard/widgets/ranked_bars.dart';
import 'package:warsha_app/views/dashboard/widgets/trend_chart.dart';
import 'package:warsha_app/views/shell/destinations.dart';
import 'package:warsha_app/views/shell/navigation_v_m.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

/// The business in numbers for a chosen range: KPIs against the previous
/// period, the sales trend, products and stock, channels and regions,
/// customers, and cash.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnalyticsVM>();
    return ModulePage(
      title: tr('Dashboard'),
      subtitle: _rangeText(vm),
      actions: [IconButton(tooltip: tr('Refresh'), icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch)],
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
    final range = from == null ? tr('All time') : '${Fmt.date(from)} – ${Fmt.date(p?.to ?? vm.to)}';
    return p?.previousFrom == null ? range : tr('{0} · compared with the {1} before', [range, Fmt.count(p!.days, 'day')]);
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
          chip(vm.preset == RangePreset.custom ? '${Fmt.shortDate(vm.from)} – ${Fmt.shortDate(vm.to)}' : tr('Custom…'),
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
            message: tr('Some figures couldn\'t be loaded: {0}.', [vm.failedSections.join(', ')]),
            actionLabel: tr('Retry'),
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
      message: tr('Previous period: {0}', [Fmt.number(previous)]),
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
          label: tr('Net sales'),
          value: Fmt.money(k.netSales),
          icon: Iconsax.money_recive_copy,
          highlighted: true,
          caption: k.discounts > 0 ? tr('After {0} discounts', [Fmt.money(k.discounts)]) : tr('Items sold, after discounts'),
          trailing: _Delta(k.netSales, p?.netSales),
        ),
        StatCard(
          label: tr('Gross profit'),
          value: Fmt.money(k.grossProfit),
          icon: Iconsax.chart_success_copy,
          tone: Tone.success,
          caption: tr('{0} margin', [Fmt.percent(k.grossMargin)]),
          trailing: _Delta(k.grossProfit, p?.grossProfit),
        ),
        StatCard(
          label: tr('Orders'),
          value: Fmt.number(k.orders),
          icon: Iconsax.receipt_2_copy,
          caption: tr('{0} · {1} per order', [Fmt.count(k.units, 'piece'), Fmt.number(k.itemsPerOrder)]),
          trailing: _Delta(k.orders, p?.orders),
        ),
        StatCard(
          label: tr('Average order'),
          value: Fmt.money(k.averageOrderValue),
          icon: Iconsax.shopping_bag_copy,
          caption: tr('Incl. {0} delivery in total', [Fmt.money(k.deliveryFees)]),
          trailing: _Delta(k.averageOrderValue, p?.averageOrderValue),
        ),
        StatCard(
          label: tr('Customers'),
          value: Fmt.number(k.customers),
          icon: Iconsax.profile_2user_copy,
          tone: Tone.info,
          caption: tr('{0} new · {1} returning', [k.newCustomers, k.returningCustomers]),
          trailing: _Delta(k.customers, p?.customers),
        ),
        StatCard(
          label: tr('Collected'),
          value: Fmt.money(k.collected),
          icon: Iconsax.wallet_check_copy,
          tone: Tone.success,
          caption: tr('Down payments + completed orders'),
        ),
        StatCard(
          label: tr('Still to collect'),
          value: Fmt.money(k.outstanding),
          icon: Iconsax.wallet_minus_copy,
          tone: Tone.warning,
          caption: tr('On orders not completed yet'),
        ),
        StatCard(
          label: tr('Cancelled'),
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
              label: Text(tr('{0} waiting to be processed', [Fmt.count(pending, 'order')])),
              onPressed: () {
                context.read<OrderVM>().setStatusFilter(OrderStatus.pending);
                nav.go(AppDestination.orders);
              },
            ),
          if (low > 0)
            ActionChip(
              avatar: const Icon(Iconsax.box_remove_copy, size: 16, color: AppStatusColors.errorText),
              label: Text(tr('{0} low or out of stock', [Fmt.count(low, 'product')])),
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
    final per = switch (trend?.granularity) { 'week' => tr('Per week (from Saturday)'), 'month' => tr('Per month'), _ => tr('Per day') };
    return DashboardPanel(
      title: tr('Sales over time'),
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
      title: tr('Sales channels'),
      subtitle: tr('Net sales by where the order came from'),
      icon: Iconsax.global_copy,
      child: RankedBars(
        emptyText: tr('No orders in this period.'),
        items: [
          for (final c in channels)
            RankedItem(
              label: '${c.channel} · ${Fmt.percent(c.share)}',
              value: c.netSales,
              valueLabel: Fmt.money(c.netSales),
              caption: tr('{0} · avg {1}{2}', [Fmt.count(c.orders, 'order'), Fmt.money(c.averageOrderValue), c.cancelled > 0 ? tr(' · {0} cancelled', [Fmt.percent(c.cancellationRate)]) : '']),
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
      title: tr('Top governorates'),
      subtitle: rest > 0 ? tr('Top 8 · the other {0} make {1}', [regions.length - 8, Fmt.percent(rest)]) : tr('Net sales by delivery area'),
      icon: Iconsax.map_1_copy,
      child: RankedBars(
        emptyText: tr('No orders in this period.'),
        items: [
          for (final r in regions.take(8))
            RankedItem(
              label: '${r.governorate} · ${Fmt.percent(r.share)}',
              value: r.netSales,
              valueLabel: Fmt.money(r.netSales),
              caption: tr('{0} · {1} · avg {2}', [Fmt.count(r.orders, 'order'), Fmt.count(r.customers, 'customer'), Fmt.money(r.averageOrderValue)]),
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
      title: tr('Categories'),
      subtitle: tr('Net sales and margin'),
      icon: Iconsax.category_copy,
      child: RankedBars(
        emptyText: tr('Nothing sold in this period.'),
        items: [
          for (final c in categories)
            RankedItem(
              label: '${c.category} · ${Fmt.percent(c.share)}',
              value: c.netSales,
              valueLabel: Fmt.money(c.netSales),
              caption: tr('{0} · profit {1} ({2})', [Fmt.count(c.units, 'piece'), Fmt.money(c.grossProfit), Fmt.percent(c.grossMargin)]),
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
      title: tr('Best sellers'),
      subtitle: tr('Top 10 by net sales'),
      icon: Iconsax.crown_1_copy,
      child: RankedBars(
        emptyText: tr('Nothing sold in this period.'),
        items: [
          for (final p in products.take(10))
            RankedItem(
              label: p.name,
              value: p.netSales,
              valueLabel: Fmt.money(p.netSales),
              caption: tr('{0} · {1} margin{2}', [Fmt.count(p.units, 'piece'), Fmt.percent(p.grossMargin), p.stock == null ? '' : tr(' · {0} left', [p.stock])]),
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
      title: tr('Running low'),
      subtitle: tr('Stock lasts under 3 weeks at this period’s pace'),
      icon: Iconsax.box_remove_copy,
      child: _Rows(
        emptyText: tr('Nothing is running low.'),
        rows: [
          for (final p in low.take(8))
            (
              p.name,
              (p.stock ?? 0) <= 0 ? tr('Out of stock') : tr('~{0} days', [p.daysOfCover!.round()]),
              tr('{0} left · {1} sold', [p.stock ?? 0, Fmt.count(p.units, 'piece')]),
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
      title: tr('Not selling'),
      subtitle: slow.isEmpty ? tr('In stock but no sales in this period') : tr('{0} of stock at cost with no sales in this period', [Fmt.money(tied)]),
      icon: Iconsax.timer_pause_copy,
      child: _Rows(
        emptyText: tr('Every product in stock sold something.'),
        rows: [
          for (final p in slow)
            (p.name, Fmt.money(p.stockValue), tr('{0} in stock · last sold {1}', [p.stock, p.lastSold == null ? tr('never') : Fmt.date(p.lastSold)])),
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
      title: tr('Customers'),
      subtitle: tr('{0} new · {1} returning · {2} have ordered more than once', [c.newCustomers, c.returningCustomers, Fmt.percent(c.repeatRate)]),
      icon: Iconsax.profile_2user_copy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoRow(label: tr('Average spend per customer'), value: Fmt.money(c.averageSpend)),
          const SizedBox(height: AppSpacing.s8),
          AppText.label(tr('Top spenders')),
          _Rows(
            emptyText: tr('No customers in this period.'),
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
      title: tr('Cash'),
      subtitle: total == 0 ? tr('Collected and still to collect') : tr('{0} of the order value is collected', [Fmt.percent(cash.collected / total)]),
      icon: Iconsax.wallet_money_copy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoRow(label: tr('Collected'), value: Fmt.money(cash.collected), valueColor: AppStatusColors.successText),
          InfoRow(label: tr('Still to collect'), value: Fmt.money(cash.outstanding), valueColor: AppStatusColors.warningText),
          const SizedBox(height: AppSpacing.s12),
          AppText.label(tr('How down payments were made')),
          RankedBars(
            emptyText: tr('No down payments in this period.'),
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
      title: tr('Busiest days'),
      subtitle: busiest == null || busiest.orders == 0 ? tr('Orders per weekday') : tr('{0} brings the most orders', [tr(busiest.weekday)]),
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
      title: tr('Order pipeline'),
      subtitle: tr('Orders placed in this period, by where they are now'),
      icon: Iconsax.task_square_copy,
      child: _Rows(
        emptyText: tr('No orders in this period.'),
        rows: [
          for (final s in statuses)
            (
              tr(s.status),
              Fmt.count(s.orders, 'order'),
              s.outstanding > 0
                  ? tr('{0} · {1} to collect', [Fmt.money(s.orderValue), Fmt.money(s.outstanding)])
                  : Fmt.money(s.orderValue),
            ),
        ],
      ),
    );
  }
}
