import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/analysis.dart';

/// Daily net revenue as an area line with a crosshair tooltip. One series,
/// so no legend: the panel title names it.
class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key, required this.days});

  final List<DailySales> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox(height: 240, child: Center(child: AppText.bodySmall('No sales in this period.', color: AppColors.muted)));
    }
    final axisText = Theme.of(context).textTheme.labelSmall;
    final sorted = [...days]..sort((a, b) => a.salesDate.compareTo(b.salesDate));
    return SizedBox(
      height: 260,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        primaryXAxis: DateTimeAxis(
          labelStyle: axisText,
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          intervalType: DateTimeIntervalType.days,
        ),
        primaryYAxis: NumericAxis(
          labelStyle: axisText,
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: const MajorGridLines(width: 1, color: AppColors.line),
          axisLabelFormatter: (a) => ChartAxisLabel(Fmt.moneyCompact(a.value).replaceAll(' EGP', ''), axisText),
        ),
        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          lineColor: AppColors.muted,
          lineDashArray: const [4, 4],
          tooltipSettings: const InteractiveTooltip(color: AppColors.ink, format: 'point.x · EGP point.y'),
        ),
        series: <CartesianSeries<DailySales, DateTime>>[
          AreaSeries<DailySales, DateTime>(
            name: 'Net revenue',
            dataSource: sorted,
            xValueMapper: (d, _) => d.salesDate,
            yValueMapper: (d, _) => d.netRevenue,
            color: AppChartColors.single.withValues(alpha: 0.08),
            borderColor: AppChartColors.single,
            borderWidth: 2,
            markerSettings: const MarkerSettings(
              isVisible: true,
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
