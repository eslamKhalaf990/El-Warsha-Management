import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/behavior.dart';
import 'package:warsha_app/view_models/behavior_v_m.dart';
import 'package:warsha_app/views/behavior/widgets/daily_activity_chart.dart';
import 'package:warsha_app/views/dashboard/widgets/ranked_bars.dart';

/// What store visitors do: visits, the path from product view to order,
/// interest per product, carts left behind, searches, promo codes tried and
/// where visitors come from.
class BehaviorPage extends StatelessWidget {
  const BehaviorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BehaviorVM>();
    return ModulePage(
      title: 'Customer behavior',
      subtitle: '${Fmt.date(vm.from)} – ${Fmt.date(vm.to)} · from the online store',
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
}

class _RangeBar extends StatelessWidget {
  const _RangeBar();

  Future<void> _pickCustom(BuildContext context) async {
    final vm = context.read<BehaviorVM>();
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      // Raw events are kept for one year
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
      initialDateRange: DateTimeRange(start: vm.from, end: vm.to),
    );
    if (range != null) vm.setCustomRange(range.start, range.end);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BehaviorVM>();
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
          for (final p in BehaviorPreset.values.where((p) => p != BehaviorPreset.custom))
            chip(p.label, vm.preset == p, () => vm.setPreset(p)),
          chip(vm.preset == BehaviorPreset.custom ? '${Fmt.shortDate(vm.from)} – ${Fmt.shortDate(vm.to)}' : 'Custom…',
              vm.preset == BehaviorPreset.custom, () => _pickCustom(context)),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BehaviorVM>();
    const gap = SizedBox(height: AppSpacing.s16, width: AppSpacing.s16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vm.isBusy) const Padding(padding: EdgeInsets.only(bottom: AppSpacing.s12), child: LinearProgressIndicator(minHeight: 2)),
        if (vm.failedSections.isNotEmpty) ...[
          InlineBanner(
            message: "Some figures couldn't be loaded: ${vm.failedSections.join(', ')}.",
            actionLabel: 'Retry',
            onAction: vm.fetch,
          ),
          gap,
        ],
        if (!vm.hasActivity) ...[
          const InlineBanner(
            tone: Tone.info,
            message: 'Nothing was tracked in this period. Visits show up here once the updated online store is live.',
          ),
          gap,
        ],
        const _Kpis(),
        gap,
        const _Pair(_Funnel(), _Daily()),
        gap,
        const _AbandonedCarts(),
        gap,
        const _Products(),
        gap,
        const _Pair(_Sources(), _Devices()),
        gap,
        const _Pair(_Searches(), _Vouchers()),
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

class _Kpis extends StatelessWidget {
  const _Kpis();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BehaviorVM>();
    final o = vm.overview;
    final carts = vm.abandoned;
    return ResponsiveGrid(
      minTileWidth: 200,
      spacing: AppSpacing.s12,
      children: [
        StatCard(
          label: 'Visitors',
          value: Fmt.number(o?.visitors),
          icon: Iconsax.profile_2user_copy,
          highlighted: true,
          caption: '${Fmt.number(o?.newVisitors)} new · ${Fmt.number(o?.returningVisitors)} returning',
        ),
        StatCard(
          label: 'Visits',
          value: Fmt.number(o?.sessions),
          icon: Iconsax.monitor_mobbile_copy,
          caption: Fmt.count(o?.pageViews ?? 0, 'page view'),
        ),
        StatCard(
          label: 'Product views',
          value: Fmt.number(o?.productViews),
          icon: Iconsax.eye_copy,
          tone: Tone.info,
          caption: '${Fmt.count(o?.cartAdds ?? 0, 'cart add')} · ${Fmt.number(o?.cartRemoves)} removed',
        ),
        StatCard(
          label: 'Conversion',
          value: Fmt.percent(o?.funnel.conversionRate, decimals: 1),
          icon: Iconsax.chart_success_copy,
          tone: Tone.success,
          caption: '${Fmt.count(o?.orders ?? 0, 'order')} · ${Fmt.money(o?.orderValue)}',
        ),
        StatCard(
          label: 'Abandoned carts',
          value: Fmt.number(carts?.count),
          icon: Iconsax.shopping_cart_copy,
          tone: Tone.warning,
          caption: '${Fmt.money(carts?.value)} left · ${Fmt.percent(carts?.abandonmentRate)} of carts',
        ),
      ],
    );
  }
}

class _Funnel extends StatelessWidget {
  const _Funnel();

  @override
  Widget build(BuildContext context) {
    final f = context.watch<BehaviorVM>().overview?.funnel ?? const BehaviorFunnel();
    String of(double rate, String step) => '${Fmt.percent(rate)} $step';
    return DashboardPanel(
      title: 'From visit to order',
      subtitle: 'Visits that reached each step',
      icon: Iconsax.filter_copy,
      child: RankedBars(
        emptyText: 'No visits in this period.',
        items: f.sessions == 0
            ? const []
            : [
                RankedItem(label: 'Visited the store', value: f.sessions.toDouble(), valueLabel: Fmt.number(f.sessions)),
                RankedItem(
                  label: 'Opened a product',
                  value: f.viewedProduct.toDouble(),
                  valueLabel: Fmt.number(f.viewedProduct),
                  caption: of(f.sessions == 0 ? 0 : f.viewedProduct / f.sessions, 'of visits'),
                ),
                RankedItem(
                  label: 'Added to cart',
                  value: f.addedToCart.toDouble(),
                  valueLabel: Fmt.number(f.addedToCart),
                  caption: of(f.viewToCartRate, 'of product viewers'),
                ),
                RankedItem(
                  label: 'Started checkout',
                  value: f.startedCheckout.toDouble(),
                  valueLabel: Fmt.number(f.startedCheckout),
                  caption: of(f.cartToCheckoutRate, 'of carts'),
                ),
                RankedItem(
                  label: 'Ordered',
                  value: f.ordered.toDouble(),
                  valueLabel: Fmt.number(f.ordered),
                  caption: of(f.checkoutToOrderRate, 'of checkouts'),
                ),
              ],
      ),
    );
  }
}

class _Daily extends StatefulWidget {
  const _Daily();

  @override
  State<_Daily> createState() => _DailyState();
}

class _DailyState extends State<_Daily> {
  ActivityMeasure _measure = ActivityMeasure.visitors;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BehaviorVM>();
    return DashboardPanel(
      title: 'Day by day',
      icon: Iconsax.chart_2_copy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ActivityMeasure>(
              segments: [for (final m in ActivityMeasure.values) ButtonSegment(value: m, label: Text(m.label))],
              selected: {_measure},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _measure = s.first),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          DailyActivityChart(days: vm.overview?.days ?? const [], from: vm.from, to: vm.to, measure: _measure),
        ],
      ),
    );
  }
}

final _cartColumns = <ExcelColumn<AbandonedCart>>[
  ExcelColumn('Last activity', (c) => c.lastActivity),
  ExcelColumn('Customer', (c) => c.who),
  ExcelColumn('Mobile', (c) => c.phone),
  ExcelColumn('Email', (c) => c.email),
  ExcelColumn('Items', (c) => c.items.map((i) => '${i.quantity} × ${i.label}').join(', ')),
  ExcelColumn('Pieces', (c) => c.itemCount),
  ExcelColumn('Value', (c) => c.value, money: true),
  ExcelColumn('Came from', (c) => c.source),
  ExcelColumn('Device', (c) => c.device),
];

class _AbandonedCarts extends StatelessWidget {
  const _AbandonedCarts();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BehaviorVM>();
    final report = vm.abandoned;
    final carts = report?.carts ?? const <AbandonedCart>[];
    return DashboardPanel(
      title: 'Carts left without ordering',
      subtitle: report == null
          ? null
          : '${Fmt.count(report.count, 'cart')} worth ${Fmt.money(report.value)} · '
              '${Fmt.count(report.orderedCarts, 'cart')} did turn into orders',
      icon: Iconsax.shopping_cart_copy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const AppText.bodySmall('Unchanged for at least', color: AppColors.muted),
              for (final idle in IdleCutoff.values)
                ChoiceChip(
                  label: Text(idle.label),
                  selected: vm.idle == idle,
                  showCheckmark: false,
                  labelStyle: TextStyle(color: vm.idle == idle ? AppColors.white : AppColors.ink),
                  onSelected: vm.isBusy ? null : (_) => vm.setIdle(idle),
                ),
              ExportExcelButton<AbandonedCart>(
                rows: () => carts,
                columns: _cartColumns,
                fileName: 'abandoned_carts',
                sheetName: 'Abandoned carts',
                noun: 'cart',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          if (carts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
              child: Center(child: AppText.bodySmall('No abandoned carts in this period.', color: AppColors.muted)),
            )
          else
            for (final (i, cart) in carts.take(50).indexed) ...[
              if (i > 0) const Divider(height: AppSpacing.s24, color: AppColors.line),
              _CartTile(cart),
            ],
          if (carts.length > 50)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s12),
              child: AppText.caption('Showing the latest 50 of ${Fmt.number(report!.count)}. Export to see them all.',
                  color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile(this.cart);

  final AbandonedCart cart;

  @override
  Widget build(BuildContext context) {
    final phone = cart.phone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: AppText.label(cart.who, maxLines: 1)),
                    if (cart.isGuest) ...[
                      const SizedBox(width: AppSpacing.s8),
                      const StatusPill(label: 'Guest', tone: Tone.neutral),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  AppText.caption(
                    [Fmt.dateTime(cart.lastActivity), cart.source, if (cart.device != null) cart.device!.toLowerCase()].join(' · '),
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            AppText.label(Fmt.money(cart.value)),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        AppText.bodySmall(
          cart.items.isEmpty ? Fmt.count(cart.itemCount, 'piece') : cart.items.map((i) => '${i.quantity} × ${i.label}').join(' · '),
        ),
        if (phone != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Row(children: [
            AppText.bodySmall(phone, color: AppColors.muted),
            IconButton(
              tooltip: 'Copy number',
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              icon: const Icon(Iconsax.copy_copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phone));
                showSuccess(context, 'Number copied.');
              },
            ),
          ]),
        ],
      ],
    );
  }
}

final _productColumns = <ExcelColumn<ProductInterest>>[
  ExcelColumn('#', (p) => p.productId),
  ExcelColumn('Product', (p) => p.name),
  ExcelColumn('Views', (p) => p.views),
  ExcelColumn('Viewers', (p) => p.viewers),
  ExcelColumn('Added to cart', (p) => p.cartAdds),
  ExcelColumn('Removed from cart', (p) => p.cartRemoves),
  ExcelColumn('Orders', (p) => p.orders),
  ExcelColumn('Pieces ordered', (p) => p.unitsOrdered),
  ExcelColumn('View → cart', (p) => p.viewToCartRate),
  ExcelColumn('Cart → order', (p) => p.cartToOrderRate),
];

class _Products extends StatelessWidget {
  const _Products();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<BehaviorVM>().products ?? const <ProductInterest>[];
    DataCell n(int v) => DataCell(AppText.bodySmall(Fmt.number(v)));
    return DashboardPanel(
      title: 'Products people look at',
      subtitle: 'Most viewed first. Many views but few cart adds may mean the price or photos need a look.',
      icon: Iconsax.eye_copy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ExportExcelButton<ProductInterest>(
              rows: () => products,
              columns: _productColumns,
              fileName: 'product_interest',
              sheetName: 'Product interest',
              noun: 'product',
            ),
          ),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
              child: Center(child: AppText.bodySmall('No product views in this period.', color: AppColors.muted)),
            )
          else
            AppDataTable(
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Views'), numeric: true),
                DataColumn(label: Text('Viewers'), numeric: true),
                DataColumn(label: Text('Added'), numeric: true),
                DataColumn(label: Text('Removed'), numeric: true),
                DataColumn(label: Text('Orders'), numeric: true),
                DataColumn(label: Text('View → cart'), numeric: true),
                DataColumn(label: Text('Cart → order'), numeric: true),
              ],
              rows: [
                for (final p in products.take(25))
                  DataRow(cells: [
                    DataCell(ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: AppText.bodySmall(p.name, maxLines: 1),
                    )),
                    n(p.views),
                    n(p.viewers),
                    n(p.cartAdds),
                    n(p.cartRemoves),
                    n(p.orders),
                    DataCell(AppText.bodySmall(Fmt.percent(p.viewToCartRate))),
                    DataCell(AppText.bodySmall(Fmt.percent(p.cartToOrderRate))),
                  ]),
              ],
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
    final sources = context.watch<BehaviorVM>().sources ?? const <TrafficSource>[];
    return DashboardPanel(
      title: 'Where visitors come from',
      subtitle: 'First visit of each visitor',
      icon: Iconsax.global_copy,
      child: RankedBars(
        emptyText: 'No visitors in this period.',
        items: [
          for (final s in sources.take(8))
            RankedItem(
              label: s.source,
              value: s.visitors.toDouble(),
              valueLabel: Fmt.count(s.visitors, 'visitor'),
              caption: '${Fmt.count(s.orders, 'order')} · ${Fmt.percent(s.conversionRate, decimals: 1)} ordered',
            ),
        ],
      ),
    );
  }
}

class _Devices extends StatelessWidget {
  const _Devices();

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<BehaviorVM>().overview?.devices ?? const <DeviceSessions>[];
    return DashboardPanel(
      title: 'Devices',
      subtitle: 'Visits per device',
      icon: Iconsax.mobile_copy,
      child: RankedBars(
        emptyText: 'No visits in this period.',
        items: [
          for (final d in devices)
            RankedItem(label: d.label, value: d.sessions.toDouble(), valueLabel: Fmt.percent(d.share), caption: Fmt.count(d.sessions, 'visit')),
        ],
      ),
    );
  }
}

class _Searches extends StatelessWidget {
  const _Searches();

  @override
  Widget build(BuildContext context) {
    final report = context.watch<BehaviorVM>().searches ?? const SearchReport();
    Widget list(List<SearchTerm> terms, String Function(SearchTerm) value) => terms.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: AppText.bodySmall('None in this period.', color: AppColors.muted),
          )
        : Column(
            children: [
              for (final t in terms.take(10))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: AppText.bodySmall(t.query, maxLines: 1)),
                    AppText.label(value(t)),
                  ]),
                ),
            ],
          );
    return DashboardPanel(
      title: 'Searches',
      subtitle: '${Fmt.count(report.total, 'search', plural: 'searches')} · ${Fmt.number(report.noResults)} found nothing',
      icon: Iconsax.search_normal_1_copy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.s8),
          const AppText.label('Most searched'),
          list(report.top, (t) => Fmt.number(t.searches)),
          const SizedBox(height: AppSpacing.s16),
          const AppText.label('Searched but not found'),
          const AppText.caption('Products people want that the store did not show.', color: AppColors.muted),
          list(report.withoutResults, (t) => Fmt.number(t.noResultSearches)),
        ],
      ),
    );
  }
}

class _Vouchers extends StatelessWidget {
  const _Vouchers();

  @override
  Widget build(BuildContext context) {
    final vouchers = context.watch<BehaviorVM>().vouchers ?? const <VoucherAttempts>[];
    return DashboardPanel(
      title: 'Promo codes typed',
      subtitle: 'At the cart, applied or refused',
      icon: Iconsax.ticket_discount_copy,
      child: vouchers.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
              child: Center(child: AppText.bodySmall('No codes tried in this period.', color: AppColors.muted)),
            )
          : Column(
              children: [
                for (final v in vouchers.take(10))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.label(v.code),
                              if (v.rejected > 0) AppText.caption(v.rejectionSummary, color: AppColors.muted),
                            ],
                          ),
                        ),
                        StatusPill(label: '${v.applied} applied', tone: Tone.success),
                        const SizedBox(width: AppSpacing.s8),
                        StatusPill(label: '${v.rejected} refused', tone: v.rejected > 0 ? Tone.error : Tone.neutral),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
