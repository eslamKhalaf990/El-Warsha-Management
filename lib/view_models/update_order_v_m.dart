import 'package:flutter/cupertino.dart';
import 'package:warsha_app/models/orderItemModel.dart';
import 'package:warsha_app/models/orderModel.dart';

import '../models/customerModel.dart' show CustomerModel;

class UpdateOrderVM extends ChangeNotifier {
  OrderModel orderModel = OrderModel(orderItems: []);

  bool isLoading = false;

  UpdateOrderVM();
  
  void loadOrder(OrderModel existingOrder) {

    // Create a new OrderModel with the same data
    orderModel = OrderModel(
      orderItems: List<OrderItemModel>.from(existingOrder.orderItems),
      orderSource: existingOrder.orderSource,
      downPayment: existingOrder.downPayment,
      paymentMethod: existingOrder.paymentMethod,
      delivery: existingOrder.delivery,
      customer: existingOrder.customer,
      orderId: existingOrder.orderId,
      discount: existingOrder.discount,
      extraDiscount: existingOrder.extraDiscount,
      grandTotal: existingOrder.grandTotal,
      allowedNextStatuses: existingOrder.allowedNextStatuses,
      totalPrice: existingOrder.totalPrice,
      orderDate: existingOrder.orderDate,
      status: existingOrder.status,
      notes: existingOrder.notes,
    );
    notifyListeners();
  }

  void clearOrder() {
    orderModel = OrderModel(orderItems: []);
    notifyListeners();
  }

  set addCustomer(CustomerModel value) {
    orderModel = orderModel.copyWith(customer: value);
    notifyListeners();
  }

  set addToOrderItems(OrderItemModel value) {
    // This adds the item to the list
    final updatedList = List<OrderItemModel>.from(orderModel.orderItems);
    updatedList.add(value);
    orderModel = orderModel.copyWith(orderItems: updatedList);
    notifyListeners();
  }

  set removeFromOrderItems(int productId) {
    // Removes the item from the list
    final updatedList = List<OrderItemModel>.from(orderModel.orderItems);
    updatedList.removeWhere((item) => item.productId == productId);
    orderModel = orderModel.copyWith(orderItems: updatedList);
    notifyListeners();
  }

  set incrementItemQuantity(int index) {
    final item = orderModel.orderItems[index];
    item.orderedQuantity++;
    notifyListeners();
  }

  set decrementItemQuantity(int index) {
    final item = orderModel.orderItems[index];
    if (item.orderedQuantity > 1) {
      item.orderedQuantity--;
    } else {
      // If quantity is 1, decrementing removes it
      removeFromOrderItems = item.productId;
    }
    notifyListeners();
  }

  double getTotalPrice() {
    double itemsTotal = 0.0;
    itemsTotal = orderModel.orderItems.fold(0, (sum, item) {
      final unitPrice = item.unitPrice;
      return sum + unitPrice * (item.orderedQuantity);
    });
    return itemsTotal;
  }

  @override
  void dispose() {
    // You no longer have a search controller here
    super.dispose();
  }
}
