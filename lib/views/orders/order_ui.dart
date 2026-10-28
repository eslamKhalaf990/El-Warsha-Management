import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/models/order_totals.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';
import 'package:warsha_app/view_models/add_order_v_m.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';

/// One color per status, used by the status dropdown and badge.
Color orderStatusColor(OrderStatus? status) => switch (status) {
      OrderStatus.pending => Colors.yellow.shade800,
      OrderStatus.processing => Colors.blue.shade300,
      OrderStatus.shipped => Colors.purple.shade300,
      OrderStatus.completed => Colors.green.shade400,
      OrderStatus.cancelled => Colors.red.shade300,
      null => Colors.grey.shade500,
    };

void showOrderMessage(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.grey,
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Shows [error] in a snackbar, unless it is a validation failure whose every
/// field the form already shows next to its input ([isShownField]).
void showOrderError(
  BuildContext context,
  ApiException? error, {
  bool Function(String field)? isShownField,
}) {
  if (error == null) return;
  if (error.isValidation && error.details.isNotEmpty && isShownField != null) {
    final unshown = error.details.where((d) => !isShownField(d.field)).toList();
    if (unshown.isEmpty) return;
    showOrderMessage(context, unshown.first.message, isError: true);
    return;
  }
  showOrderMessage(context, error.message, isError: true);
}

/// Fields the add/update order forms show inline.
bool isOrderFormField(String field) =>
    const {'customerId', 'paymentMethod', 'orderSource', 'downPayment', 'discount', 'delivery'}
        .contains(field) ||
    RegExp(r'^items\[\d+\]\.quantity$').hasMatch(field);

/// Stock and bank balances change with every order change.
void refreshAfterOrderChange(BuildContext context) {
  context.read<AccountingVM>().initAccounting();
  context.read<ProductVM>().fetch();
  context.read<AddOrderVM>().fetchGovernorateCounts();
}

/// Subtotal → amount due breakdown, as the backend calculates it.
class OrderTotalsView extends StatelessWidget {
  final OrderTotals totals;

  const OrderTotalsView(this.totals, {super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.tertiary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row('Subtotal', totals.subtotal),
        _row(
          totals.productDiscount > 0 && totals.extraDiscount > 0
              ? 'Discount (products ${_money(totals.productDiscount)} + extra ${_money(totals.extraDiscount)})'
              : 'Discount',
          -totals.totalDiscount,
        ),
        _row('Delivery', totals.delivery),
        const Divider(),
        _row('Grand total', totals.grandTotal, bold: true),
        _row('Down payment', -totals.downPayment),
        const Divider(),
        _row('Amount due', totals.amountDue, bold: true, color: accent, size: 17),
      ],
    );
  }

  static String _money(double v) => (v == 0 ? 0.0 : v).toStringAsFixed(2);

  Widget _row(String label, double value, {bool bold = false, Color? color, double size = 14}) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 8),
          Text('${_money(value)} EGP', style: style),
        ],
      ),
    );
  }
}
