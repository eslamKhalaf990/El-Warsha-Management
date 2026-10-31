import 'package:flutter/material.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/order_totals.dart';

/// Subtotal → amount due, as the backend calculates it.
class OrderTotalsView extends StatelessWidget {
  const OrderTotalsView(this.totals, {super.key});

  final OrderTotals totals;

  @override
  Widget build(BuildContext context) {
    final t = totals;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InfoRow(label: 'Subtotal', value: Fmt.money(t.subtotal)),
        if (t.productDiscount > 0) InfoRow(label: 'Product discounts', value: '− ${Fmt.money(t.productDiscount)}'),
        if (t.extraDiscount > 0) InfoRow(label: 'Extra discount', value: '− ${Fmt.money(t.extraDiscount)}'),
        InfoRow(label: 'Delivery', value: t.delivery > 0 ? Fmt.money(t.delivery) : 'Free'),
        const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.s8), child: Divider()),
        InfoRow(label: 'Total', value: Fmt.money(t.grandTotal), bold: true),
        if (t.downPayment > 0) InfoRow(label: 'Paid upfront', value: '− ${Fmt.money(t.downPayment)}'),
        const SizedBox(height: AppSpacing.s8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
          decoration: const BoxDecoration(color: AppColors.blush, borderRadius: AppRadius.inputBorderRadius),
          child: Row(
            children: [
              const Expanded(child: AppText.label('To collect', color: AppColors.deepWine)),
              AppText.title(Fmt.money(t.amountDue), color: AppColors.burgundy),
            ],
          ),
        ),
      ],
    );
  }
}
