import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/behavior.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

/// What the daily chart plots, one measure at a time.
enum ActivityMeasure {
  visitors('Visitors'),
  productViews('Product views'),
  cartAdds('Cart adds'),
  orders('Orders');

  const ActivityMeasure(this.labelEn);

  /// English; shown through [label] in the current language.
  final String labelEn;
  String get label => tr(labelEn);

  int of(BehaviorDay d) => switch (this) {
        ActivityMeasure.visitors => d.visitors,
        ActivityMeasure.productViews => d.productViews,
        ActivityMeasure.cartAdds => d.cartAdds,
        ActivityMeasure.orders => d.orders,
      };
}

/// One measure per day as columns, with a tooltip per day. Days without any
/// tracked activity are missing from the backend's list, so they are filled
/// with zeros here to keep gaps visible.
class DailyActivityChart extends StatelessWidget {
  const DailyActivityChart({super.key, required this.days, required this.from, required this.to, required this.measure});

  final List<BehaviorDay> days;
  final DateTime from;
  final DateTime to;
  final ActivityMeasure measure;

  static List<BehaviorDay> filled(List<BehaviorDay> days, DateTime from, DateTime to) {
    final byDay = {for (final d in days) DateTime(d.date.year, d.date.month, d.date.day): d};
    final out = <BehaviorDay>[];
    for (var day = DateTime(from.year, from.month, from.day); !day.isAfter(to); day = DateTime(day.year, day.month, day.day + 1)) {
      out.add(byDay[day] ?? BehaviorDay(date: day));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final points = filled(days, from, to);
    if (points.every((p) => measure.of(p) == 0)) {
      return SizedBox(height: 220, child: Center(child: AppText.bodySmall(tr('Nothing tracked in this period.'), color: AppColors.muted)));
    }
    final axisText = Theme.of(context).textTheme.labelSmall;
    return SizedBox(
      height: 240,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        primaryXAxis: DateTimeAxis(
          labelStyle: axisText,
          dateFormat: Fmt.dateFormat('d MMM'),
          intervalType: DateTimeIntervalType.days,
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
        ),
        primaryYAxis: NumericAxis(
          labelStyle: axisText,
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: const MajorGridLines(width: 1, color: AppColors.line),
          axisLabelFormatter: (a) => ChartAxisLabel(Fmt.number(a.value), axisText),
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          builder: (data, point, series, pointIndex, seriesIndex) {
            final d = points[pointIndex];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.caption(Fmt.date(d.date), color: AppColors.white.withValues(alpha: 0.7)),
                  AppText.label('${Fmt.number(measure.of(d))} ${measure.label.toLowerCase()}', color: AppColors.white),
                ],
              ),
            );
          },
        ),
        series: <CartesianSeries<BehaviorDay, DateTime>>[
          ColumnSeries<BehaviorDay, DateTime>(
            name: measure.label,
            dataSource: points,
            xValueMapper: (d, _) => d.date,
            yValueMapper: (d, _) => measure.of(d),
            color: AppChartColors.single,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            animationDuration: 400,
          ),
        ],
      ),
    );
  }
}
