import 'package:flutter/material.dart';
import 'package:warsha_app/core/widgets/widgets.dart';

/// Live price, profit and margin from what is typed in the pricing fields.
class PricingSummary extends StatelessWidget {
  const PricingSummary({super.key, required this.buying, required this.selling, required this.discount});

  final String buying;
  final String selling;
  final String discount;

  static double _n(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final cost = _n(buying);
    final price = _n(selling) - _n(discount);
    final profit = price - cost;
    final margin = price > 0 ? profit / price * 100 : 0.0;
    final loss = profit < 0;

    return AppCard(
      variant: AppCardVariant.ivory,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
      child: Column(
        children: [
          InfoRow(label: 'Customer pays', value: Fmt.money(price), bold: true),
          InfoRow(
            label: 'Profit per piece',
            value: '${Fmt.money(profit)}  (${margin.toStringAsFixed(0)}%)',
            valueColor: loss ? AppStatusColors.errorText : AppStatusColors.successText,
          ),
          if (loss)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.s4),
              child: InlineBanner(message: 'This price is below cost: every sale loses money.', tone: Tone.error),
            ),
        ],
      ),
    );
  }
}
