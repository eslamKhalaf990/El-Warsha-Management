import 'package:flutter/material.dart';
import 'package:warsha_app/models/orderItemModel.dart';
import 'package:warsha_app/models/orderModel.dart';
import 'package:warsha_app/models/order_totals.dart';

class PaymentProvider extends ChangeNotifier {
  final TextEditingController downPayment = TextEditingController();
  final TextEditingController paymentMethod = TextEditingController();
  final TextEditingController discount = TextEditingController();
  final TextEditingController platformSource = TextEditingController();
  final TextEditingController delivery = TextEditingController();
  final TextEditingController notes = TextEditingController();

  PaymentProvider() {

    // Listen for changes
    downPayment.addListener(_onFieldChanged);
    discount.addListener(_onFieldChanged);
    delivery.addListener(_onFieldChanged);
    notes.addListener(_onFieldChanged);
  }

  void loadPayment(OrderModel existingOrder) {
    downPayment.text = existingOrder.downPayment.toString();
    paymentMethod.text = existingOrder.paymentMethod ??"-";
    discount.text ="0.0";
    platformSource.text = existingOrder.orderSource ?? "-";
    delivery.text = existingOrder.delivery.toString();
    notes.text = existingOrder.notes ?? "-";

    notifyListeners();
  }

  /// Live totals for [items] with the amounts typed in this form, using the
  /// backend's formula (product discounts + this extra discount).
  OrderTotals totalsFor(List<OrderItemModel> items) => OrderTotals.compute(
        items: items,
        quantityOf: (item) => item.quantityToOrder,
        extraDiscount: double.tryParse(discount.text) ?? 0,
        delivery: double.tryParse(delivery.text) ?? 0,
        downPayment: double.tryParse(downPayment.text) ?? 0,
      );

  void _onFieldChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    downPayment.dispose();
    paymentMethod.dispose();
    discount.dispose();
    platformSource.dispose();
    delivery.dispose();
    notes.dispose();
    super.dispose();
  }

  void clearPaymentDetails (){
    downPayment.clear();
    paymentMethod.clear();
    discount.clear();
    platformSource.clear();
    delivery.clear();
    notes.clear();
    notifyListeners();
  }
}
