import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/models/orderItemModel.dart';
import 'package:warsha_app/models/orderModel.dart';
import 'package:warsha_app/models/order_totals.dart';

OrderItemModel item(double price, int qty, {double unitDiscount = 0}) =>
    OrderItemModel(productId: 1, productName: 'p', quantity: qty, unitPrice: price)
      ..quantityToOrder = qty
      ..unitDiscount = unitDiscount;

void main() {
  test('compute follows the backend formula', () {
    final totals = OrderTotals.compute(
      items: [item(100, 2, unitDiscount: 10), item(50, 1)],
      quantityOf: (i) => i.quantityToOrder,
      extraDiscount: 5,
      delivery: 40,
      downPayment: 100,
    );

    expect(totals.subtotal, 250);
    expect(totals.productDiscount, 20);
    expect(totals.totalDiscount, 25);
    expect(totals.grandTotal, 265); // 250 − 25 + 40
    expect(totals.amountDue, 165);
  });

  test('compute uses the quantity the form edits', () {
    final line = item(10, 1)..orderedQuantity = 3;
    final totals = OrderTotals.compute(items: [line], quantityOf: (i) => i.orderedQuantity);
    expect(totals.subtotal, 30);
  });

  test('ofOrder prefers the backend figures and splits the discount', () {
    final order = OrderModel(
      discount: 30,
      extraDiscount: 10,
      delivery: 50,
      grandTotal: 220,
      downPayment: 20,
      totalPrice: 200,
      orderItems: [item(100, 2)],
    );

    final totals = OrderTotals.ofOrder(order);
    expect(totals.subtotal, 200);
    expect(totals.productDiscount, 20);
    expect(totals.extraDiscount, 10);
    expect(totals.grandTotal, 220);
    expect(totals.amountDue, 200);
  });

  test('ofOrder computes missing totals', () {
    final totals = OrderTotals.ofOrder(OrderModel(
      discount: 10,
      delivery: 5,
      downPayment: 15,
      orderItems: [item(10, 3)],
    ));
    expect(totals.grandTotal, 25);
    expect(totals.amountDue, 10);
  });
}
