import 'orderItemModel.dart';
import 'orderModel.dart';

/// The backend's order pricing (OrderPricing) for display:
///
///   subtotal   = Σ unitPrice × quantity
///   discount   = product discounts + extra discount
///   grandTotal = subtotal − discount + delivery
///   amountDue  = grandTotal − downPayment
class OrderTotals {
  final double subtotal;
  final double productDiscount;
  final double extraDiscount;
  final double delivery;
  final double downPayment;
  final double grandTotal;
  final double amountDue;

  const OrderTotals._({
    required this.subtotal,
    required this.productDiscount,
    required this.extraDiscount,
    required this.delivery,
    required this.downPayment,
    required this.grandTotal,
    required this.amountDue,
  });

  double get totalDiscount => productDiscount + extraDiscount;

  /// Live totals for a form that is still being edited. [quantityOf] picks the
  /// quantity field the form edits (`quantityToOrder` or `orderedQuantity`).
  factory OrderTotals.compute({
    required List<OrderItemModel> items,
    required int Function(OrderItemModel item) quantityOf,
    double extraDiscount = 0,
    double delivery = 0,
    double downPayment = 0,
  }) {
    double subtotal = 0;
    double productDiscount = 0;
    for (final item in items) {
      subtotal += item.unitPrice * quantityOf(item);
      productDiscount += item.unitDiscount * quantityOf(item);
    }
    final grandTotal = subtotal - productDiscount - extraDiscount + delivery;
    return OrderTotals._(
      subtotal: _round(subtotal),
      productDiscount: _round(productDiscount),
      extraDiscount: _round(extraDiscount),
      delivery: _round(delivery),
      downPayment: _round(downPayment),
      grandTotal: _round(grandTotal),
      amountDue: _round(grandTotal - downPayment),
    );
  }

  /// Totals of a saved order, preferring the figures the backend calculated.
  factory OrderTotals.ofOrder(OrderModel order) {
    final subtotal = order.orderItems.fold<double>(0, (sum, i) => sum + i.unitPrice * i.quantity);
    final downPayment = order.downPayment ?? 0;
    final grandTotal = order.grandTotal ?? subtotal - order.discount + order.delivery;
    return OrderTotals._(
      subtotal: _round(subtotal),
      productDiscount: _round(order.discount - order.extraDiscount),
      extraDiscount: _round(order.extraDiscount),
      delivery: _round(order.delivery),
      downPayment: _round(downPayment),
      grandTotal: _round(grandTotal),
      amountDue: _round(order.amountDue ?? grandTotal - downPayment),
    );
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;
}
