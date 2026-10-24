import 'package:flutter/material.dart';
import 'package:warsha_app/models/orderModel.dart';

class UpdatePaymentDetails extends ChangeNotifier {
  final TextEditingController downPayment = TextEditingController();
  final TextEditingController paymentMethod = TextEditingController();
  final TextEditingController discount = TextEditingController();
  final TextEditingController notes = TextEditingController();
  final TextEditingController platformSource = TextEditingController();
  final TextEditingController delivery = TextEditingController();

  double _basePrice = 0;

  UpdatePaymentDetails() {

    // Listen for changes
    downPayment.addListener(_onFieldChanged);
    discount.addListener(_onFieldChanged);
    delivery.addListener(_onFieldChanged);
    notes.addListener(_onFieldChanged);
  }

  double get basePrice => _basePrice;

  set basePrice(double value) {
    _basePrice = value;
    notifyListeners();
  }


  void loadPayment(OrderModel existingOrder) {
    downPayment.text = (existingOrder.downPayment ?? 0).toString();
    paymentMethod.text = existingOrder.paymentMethod ?? "-";
    // Only the extra discount is editable; product discounts are re-applied
    // by the backend, so showing the total here would apply them twice.
    discount.text = existingOrder.extraDiscount.toString();
    platformSource.text = existingOrder.orderSource ?? "-";
    delivery.text = existingOrder.delivery.toString();
    notes.text = existingOrder.notes ?? "-";

    notifyListeners();
  }

  double get totalPrice {
    final double discountValue = double.tryParse(discount.text) ?? 0;
    final double downPaymentValue = double.tryParse(downPayment.text) ?? 0;
    final double deliveryValue = double.tryParse(delivery.text) ?? 0;

    return (_basePrice - discountValue - downPaymentValue) + deliveryValue;
  }

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
    downPayment.clear();
    paymentMethod.clear();
    discount.clear();
    platformSource.clear();
    delivery.clear();
    notes.clear();
    notifyListeners();
  }
}
