import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:flutter/material.dart';
import 'package:warsha_app/models/customerModel.dart';
import 'package:warsha_app/models/order_governorate_count.dart';

import 'package:warsha_app/models/orderItemModel.dart';
import 'package:warsha_app/models/orderModel.dart';
import 'package:warsha_app/services/orders_service.dart';

/// The order being built on the add-order screen, plus orders per
/// governorate for the orders page.
class AddOrderVM extends ChangeNotifier with AsyncViewModel {
  final OrdersService _orderService;

  // This is the "cart" or "builder" object for the new order
  OrderModel orderModel = OrderModel(orderItems: []);

  List<GovernorateCountPerOrder> _governorateCounts = [];

  AddOrderVM(this._orderService);

  List<GovernorateCountPerOrder> get governorateCounts => List.unmodifiable(_governorateCounts);

  Future<bool> fetchGovernorateCounts() =>
      load(() async => _governorateCounts = await _orderService.countsByGovernorate());

  void clearOrder() {
    orderModel = OrderModel(orderItems: []); // Reset to a new, empty model
    notify();
  }

  set addCustomer(CustomerModel value) {
    orderModel = orderModel.copyWith(customer: value);
    notify();
  }

  set addToOrderItems(OrderItemModel value) {
    // This adds the item to the list
    final updatedList = List<OrderItemModel>.from(orderModel.orderItems);
    updatedList.add(value);
    orderModel = orderModel.copyWith(orderItems: updatedList);
    notify();
  }

  set removeFromOrderItems(OrderItemModel line) {
    // Removes the line (same product and size/color) from the list
    final updatedList = List<OrderItemModel>.from(orderModel.orderItems);
    updatedList.removeWhere((item) => item.sameLineAs(line));
    orderModel = orderModel.copyWith(orderItems: updatedList);
    notify();
  }

  set incrementItemQuantity(int index) {
    final item = orderModel.orderItems[index];
    item.quantityToOrder++;
    notify();
  }

  set decrementItemQuantity(int index) {
    final item = orderModel.orderItems[index];
    if (item.quantityToOrder > 1) {
      item.quantityToOrder--;
    } else {
      // If quantity is 1, decrementing removes it
      removeFromOrderItems = item;
    }
    notify();
  }

}
