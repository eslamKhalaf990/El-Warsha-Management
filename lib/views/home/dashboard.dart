import 'package:flutter/material.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:warsha_app/models/analysis_models/analysis.dart';
import 'package:warsha_app/utils/price_helper.dart';
import 'package:warsha_app/view_models/home_v_m.dart';

// ─────────────────────────────────────────────
//  MAIN DASHBOARD
// ─────────────────────────────────────────────
class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Consumer<HomeVM>(
        builder: (context, vm, child) {
          if (vm.loadFailed) {
            return LoadErrorView(message: vm.errorMessage!, onRetry: vm.fetch);
          }
          if (!vm.hasLoaded) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: cs.tertiary),
                  const SizedBox(height: 14),
                  Text('Loading insights...',
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: cs.tertiary,
            onRefresh: () async => await vm.initHome(),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (vm.failedSections.isNotEmpty) ...[
                        _PartialDataBanner(sections: vm.failedSections, onRetry: vm.fetch),
                        const SizedBox(height: 16),
                      ],
                      const _SectionLabel('Market Overview'),
                      const SizedBox(height: 12),
                      _KpiRow(vm: vm),
                      const SizedBox(height: 24),
                      _buildTopRegions(context, vm),
                      const SizedBox(height: 24),
                      const _SectionLabel('Revenue Trend'),
                      const SizedBox(height: 12),
                      _RevenueChart(vm: vm),
                      const SizedBox(height: 24),
                      const _SectionLabel('Revenue by Source'),
                      const SizedBox(height: 12),
                      _RevenueBySourceCard(vm: vm),
                      const SizedBox(height: 24),
                      const _SectionLabel('Customer Segments'),
                      const SizedBox(height: 12),
                      _CustomerSegmentsGrid(vm: vm),
                      const SizedBox(height: 24),
                      const _SectionLabel('Daily Revenue — Last 30 Days'),
                      const SizedBox(height: 12),
                      _DailyRevenueTable(vm: vm),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  KPI ROW
// ─────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  final HomeVM vm;
  const _KpiRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    final allOrders = (vm.dailyRevenueReport ?? []);
    final totalRevenue = allOrders.fold(0.0, (sum, r) => sum + r.netRevenue);
    final totalOrders = allOrders.fold(0.0, (sum, r) => sum + r.numberOfOrders);

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Net Revenue',
            value: _formatEGP(totalRevenue),
            icon: Iconsax.money_recive,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            label: 'Avg Basket',
            value: _formatEGP(vm.averageBasketSize ?? 0),
            icon: Iconsax.shopping_bag,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            label: 'Orders',
            value: totalOrders.toString(),
            icon: Iconsax.receipt,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REVENUE CHART
// ─────────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final HomeVM vm;
  const _RevenueChart({required this.vm});

  @override
  Widget build(BuildContext context) {
    final reports = (vm.dailyRevenueReport ?? []);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Container(
        height: 220,
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: reports.isEmpty
            ? Center(
                child: Text('No data',
                    style: Theme.of(context).textTheme.bodySmall))
            : SfCartesianChart(
                backgroundColor: Colors.transparent,
                plotAreaBorderWidth: 0,
                margin: EdgeInsets.zero,
                primaryXAxis: DateTimeAxis(
                  labelStyle:
                      TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  axisLine: const AxisLine(width: 0),
                  majorGridLines: const MajorGridLines(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  intervalType: DateTimeIntervalType.days,
                  interval: 7,
                ),
                primaryYAxis: NumericAxis(
                  labelStyle:
                      TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  axisLine: const AxisLine(width: 0),
                  majorGridLines: MajorGridLines(
                    width: 0.5,
                    color: Colors.grey.shade200,
                    dashArray: const <double>[4, 4],
                  ),
                  majorTickLines: const MajorTickLines(size: 0),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x : EGP point.y',
                ),
                series: <CartesianSeries>[
                  AreaSeries<dynamic, DateTime>(
                    dataSource: reports,
                    xValueMapper: (r, _) => r.salesDate as DateTime,
                    yValueMapper: (r, _) => r.netRevenue,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    borderColor: Colors.transparent,
                    animationDuration: 800,
                  ),
                  SplineSeries<dynamic, DateTime>(
                    dataSource: reports,
                    xValueMapper: (r, _) => r.salesDate as DateTime,
                    yValueMapper: (r, _) => r.netRevenue,
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.5,
                    markerSettings: MarkerSettings(
                      isVisible: true,
                      height: 5,
                      width: 5,
                      color: Theme.of(context).colorScheme.primary,
                      borderColor: Colors.white,
                      borderWidth: 2,
                    ),
                    animationDuration: 800,
                    name: 'Net Revenue',
                  ),
                  SplineSeries<dynamic, DateTime>(
                    dataSource: reports,
                    xValueMapper: (r, _) => r.salesDate as DateTime,
                    yValueMapper: (r, _) => r.totalDiscountsGiven,
                    color: Theme.of(context).colorScheme.error.withOpacity(0.6),
                    width: 1.5,
                    dashArray: const <double>[5, 4],
                    markerSettings: const MarkerSettings(isVisible: false),
                    animationDuration: 800,
                    name: 'Discounts',
                  ),
                ],
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.top,
                  textStyle:
                      TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  backgroundColor: Colors.transparent,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REVENUE BY SOURCE
// ─────────────────────────────────────────────
class _RevenueBySourceCard extends StatelessWidget {
  final HomeVM vm;
  const _RevenueBySourceCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final sources = vm.revenueBySource ?? [];
    if (sources.isEmpty) return const _EmptyState(message: 'No source data');

    final totalRev = sources.fold(0.0, (sum, s) => sum + s.totalRevenue);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: sources.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final pct = totalRev > 0 ? s.totalRevenue / totalRev : 0.0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.shop,
                            color: Theme.of(context).colorScheme.primary,
                            size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.orderSource,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          _formatEGP(s.totalRevenue),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        backgroundColor: Colors.grey.shade100,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.totalOrders} orders · avg ${_formatEGP(s.averageOrderValue)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (i < sources.length - 1)
                Divider(height: 1, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CUSTOMER SEGMENTS GRID
// ─────────────────────────────────────────────
class _CustomerSegmentsGrid extends StatelessWidget {
  final HomeVM vm;
  const _CustomerSegmentsGrid({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SegmentPanel(
                label: 'Loyal',
                count: vm.loyalCustomers?.length ?? 0,
                icon: Iconsax.heart,
                children: (vm.loyalCustomers ?? [])
                    .map((c) => _CustomerRow(
                          name: c.fullName,
                          detail: '${c.orderCount} orders',
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SegmentPanel(
                label: 'VIP',
                count: vm.vipCustomers?.length ?? 0,
                icon: Iconsax.star,
                children: (vm.vipCustomers ?? [])
                    .map((c) => _CustomerRow(
                          name: c.fullName,
                          detail: _formatEGP(c.totalLifetimeSpend),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SegmentPanel(
                label: 'At Risk',
                count: vm.atRiskCustomers?.length ?? 0,
                icon: Iconsax.warning_2,
                children: (vm.atRiskCustomers ?? [])
                    .map((c) => _CustomerRow(
                          name: c.fullName,
                          detail: '${c.daysSinceLastOrder}d ago',
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SegmentPanel(
                label: 'Discount',
                count: vm.discountSeekers?.length ?? 0,
                icon: Iconsax.tag,
                children: (vm.discountSeekers ?? [])
                    .map((c) => _CustomerRow(
                          name: c.fullName,
                          detail: '-${_formatEGP(c.totalDiscountsReceived)}',
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SegmentPanel extends StatefulWidget {
  final String label;
  final int count;
  final IconData icon;
  final List<Widget> children;

  const _SegmentPanel({
    required this.label,
    required this.count,
    required this.icon,
    required this.children,
  });

  @override
  State<_SegmentPanel> createState() => _SegmentPanelState();
}

class _SegmentPanelState extends State<_SegmentPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(widget.icon,
                      color: Theme.of(context).colorScheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${widget.count} customers',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Iconsax.arrow_up_2_copy
                        : Iconsax.arrow_down_1_copy,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && widget.children.isNotEmpty) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            ...widget.children.take(5),
            if (widget.children.length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    '+${widget.children.length - 5} more',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final String name;
  final String detail;

  const _CustomerRow({required this.name, required this.detail});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: cs.tertiary.withOpacity(0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: cs.tertiary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            detail,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Widget _buildTopRegions(BuildContext context, HomeVM vm) {
  final cs = Theme.of(context).colorScheme;
  final regions = vm.governoratePerformance ?? [];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header
      const _SectionLabel("TOP REGIONS"),
      const SizedBox(height: 12),

      // Content
      if (regions.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No regional data available',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        )
      else
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: regions.map((gov) => _RegionChip(gov: gov)).toList(),
          ),
        ),
    ],
  );
}

class _RegionChip extends StatelessWidget {
  final GovernorateAnalytics gov;
  const _RegionChip({required this.gov});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Governorate name
            Text(
              gov.governorate,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),

            // Orders
            Row(
              children: [
                Icon(Iconsax.receipt, size: 11, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${gov.totalOrders} orders',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Revenue
            Row(
              children: [
                Icon(Iconsax.money_recive,
                    size: 11, color: cs.primary),
                const SizedBox(width: 4),
                Text(
                  '${PriceHelper.formatNumber(gov.totalRevenue)} EGP',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Avg delivery
            Row(
              children: [
                Icon(Iconsax.truck, size: 11, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Avg delivery: ${PriceHelper.formatNumber(gov.averageDelivery)} EGP',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────
//  DAILY REVENUE TABLE
// ─────────────────────────────────────────────
class _DailyRevenueTable extends StatelessWidget {
  final HomeVM vm;
  const _DailyRevenueTable({required this.vm});

  @override
  Widget build(BuildContext context) {
    final reports = _last30Days(vm.dailyRevenueReport ?? []);
    if (reports.isEmpty) return const _EmptyState(message: 'No revenue data');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Date',
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Orders',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Discounts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Net Revenue',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          ...reports.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final date = r.salesDate as DateTime;
            final formattedDate =
                "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(formattedDate,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          r.numberOfOrders.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatEGP(r.totalDiscountsGiven),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatEGP(r.netRevenue),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < reports.length - 1)
                  Divider(height: 1, color: Colors.grey.shade100),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────
List<dynamic> _last30Days(List<dynamic> reports) {
  final cutoff = DateTime.now().subtract(const Duration(days: 30));
  return reports
      .where((r) => (r.salesDate as DateTime).isAfter(cutoff))
      .toList();
}

String _formatEGP(double amount) {
  if (amount >= 1000000) return 'EGP ${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return 'EGP ${(amount / 1000).toStringAsFixed(1)}K';
  return 'EGP ${amount.toStringAsFixed(0)}';
}


/// Says which dashboard sections couldn't be loaded, with a retry.
class _PartialDataBanner extends StatelessWidget {
  const _PartialDataBanner({required this.sections, required this.onRetry});

  final Set<String> sections;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Some figures couldn't be loaded: ${sections.join(', ')}.",
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
