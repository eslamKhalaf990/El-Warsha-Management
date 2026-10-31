import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/analytics.dart';

/// What the trend chart plots. One measure at a time: money and order counts
/// never share an axis.
enum TrendMeasure {
  netSales('Net sales'),
  grossProfit('Gross profit'),
  orders('Orders');

  const TrendMeasure(this.label);

  final String label;

  double of(TrendPoint p) => switch (this) {
        TrendMeasure.netSales => p.netSales,
        TrendMeasure.grossProfit => p.grossProfit,
        TrendMeasure.orders => p.orders.toDouble(),
      };

  String format(num v) => this == TrendMeasure.orders ? Fmt.count(v.round(), 'order') : Fmt.money(v);
}

/// One measure over time as an area line with a crosshair tooltip. One series,
/// so no legend: the panel title and the measure picker name it. Empty days,
/// weeks or months come from the backend as zeros, so gaps read as gaps.
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.trend, required this.measure});

  final SalesTrend? trend;
  final TrendMeasure measure;

  @override
  Widget build(BuildContext context) {
    final points = trend?.points ?? const [];
    if (points.every((p) => p.orders == 0)) {
      return const SizedBox(height: 240, child: Center(child: AppText.bodySmall('No sales in this period.', color: AppColors.muted)));
    }
    final axisText = Theme.of(context).textTheme.labelSmall;
    final granularity = trend!.granularity;
    final label = granularity == 'month' ? DateFormat('MMM yy') : DateFormat('d MMM');
    String pointLabel(DateTime d) => switch (granularity) {
          'week' => 'Week of ${Fmt.shortDate(d)}',
          'month' => DateFormat('MMMM yyyy').format(d),
          _ => Fmt.date(d),
        };
    return SizedBox(
      height: 260,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        primaryXAxis: DateTimeAxis(
          labelStyle: axisText,
          dateFormat: label,
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          intervalType: switch (granularity) {
            'month' => DateTimeIntervalType.months,
            _ => DateTimeIntervalType.days,
          },
        ),
        primaryYAxis: NumericAxis(
          labelStyle: axisText,
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: const MajorGridLines(width: 1, color: AppColors.line),
          axisLabelFormatter: (a) => ChartAxisLabel(
            measure == TrendMeasure.orders ? Fmt.number(a.value) : Fmt.moneyCompact(a.value).replaceAll(' EGP', ''),
            axisText,
          ),
        ),
        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          lineColor: AppColors.muted,
          lineDashArray: const [4, 4],
          builder: (context, details) {
            final i = details.pointIndex;
            if (i == null || i < 0 || i >= points.length) return const SizedBox.shrink();
            final p = points[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.caption(pointLabel(p.start), color: AppColors.white.withValues(alpha: 0.7)),
                  AppText.label(measure.format(measure.of(p)), color: AppColors.white),
                  if (measure != TrendMeasure.orders)
                    AppText.caption(Fmt.count(p.orders, 'order'), color: AppColors.white.withValues(alpha: 0.7)),
                ],
              ),
            );
          },
        ),
        series: <CartesianSeries<TrendPoint, DateTime>>[
          AreaSeries<TrendPoint, DateTime>(
            name: measure.label,
            dataSource: points,
            xValueMapper: (p, _) => p.start,
            yValueMapper: (p, _) => measure.of(p),
            color: AppChartColors.single.withValues(alpha: 0.08),
            borderColor: AppChartColors.single,
            borderWidth: 2,
            markerSettings: MarkerSettings(
              isVisible: points.length <= 60,
              width: 8,
              height: 8,
              color: AppChartColors.single,
              borderColor: AppColors.white,
              borderWidth: 2,
            ),
            animationDuration: 600,
          ),
        ],
      ),
    );
  }
}

/// Orders per weekday as columns, Saturday first, each labelled with its count.
class WeekdayChart extends StatelessWidget {
  const WeekdayChart({super.key, required this.days});

  final List<WeekdaySales> days;

  @override
  Widget build(BuildContext context) {
    if (days.every((d) => d.orders == 0)) {
      return const SizedBox(height: 200, child: Center(child: AppText.bodySmall('No orders in this period.', color: AppColors.muted)));
    }
    final axisText = Theme.of(context).textTheme.labelSmall;
    return SizedBox(
      height: 220,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        primaryXAxis: CategoryAxis(
          labelStyle: axisText,
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
        ),
        primaryYAxis: const NumericAxis(isVisible: false, majorGridLines: MajorGridLines(width: 0)),
        tooltipBehavior: TooltipBehavior(enable: true, color: AppColors.ink, format: 'point.x · point.y orders'),
        series: <CartesianSeries<WeekdaySales, String>>[
          ColumnSeries<WeekdaySales, String>(
            name: 'Orders',
            dataSource: days,
            xValueMapper: (d, _) => d.weekday.length > 3 ? d.weekday.substring(0, 3) : d.weekday,
            yValueMapper: (d, _) => d.orders,
            color: AppChartColors.single,
            width: 0.6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            dataLabelSettings: DataLabelSettings(isVisible: true, textStyle: axisText),
            animationDuration: 600,
          ),
        ],
      ),
    );
  }
}
