// import 'dart:convert';
//
// import 'package:flutter/cupertino.dart';
// import 'package:warsha_app/models/customer_model.dart';
// import 'package:warsha_app/models/order_governorate_count.dart';
//
// import 'package:warsha_app/models/order_model.dart';
// import 'package:warsha_app/order_upgrading/models/orderItemModel.dart';
// import 'package:warsha_app/order_upgrading/models/orderModel.dart';
// import 'package:warsha_app/services/orders_service.dart';
// import 'package:warsha_app/view_models/user_v_m.dart';
//
// class AddOrderVM extends ChangeNotifier {
//   final OrdersService _orderService;
//   final UserViewModel _userViewModel;
//   final TextEditingController searchController = TextEditingController();
//   OrderModel orderModel = OrderModel();
//
//   bool isLoading = false;
//   String deletedOrder = "";
//
//   Future<List<OrderModel>>? allOrders;
//   Future<List<GovernorateCountPerOrder>>? allCounts;
//
//   AddOrderVM(this._orderService, this._userViewModel) {
//     initAllOrders();
//     searchController.addListener(() {
//       notifyListeners();
//     });
//   }
//
//   void initAllOrders () {
//     allOrders = getAllOrders();
//     allCounts = getGovernorateCounts();
//     notifyListeners();
//   }
//
//   Future<List<OrderModel>> getAllOrders() async {
//     List<OrderModel> orders = [];
//     try {
//       isLoading = true;
//
//       final response = await _orderService.getAllOrders(_userViewModel.token);
//       if (response.statusCode == 200) {
//         final ordersData = jsonDecode(response.body);
//         final List<dynamic> data = ordersData;
//         orders = data.map((item) => OrderModel.fromJson(item)).toList();
//       } else {
//         debugPrint("Failed to fetch orders: ${response.statusCode}");
//       }
//     } catch (e) {
//       debugPrint("Error fetching orders: $e");
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//     return orders;
//   }
//
//
//   Future<List<GovernorateCountPerOrder>> getGovernorateCounts() async {
//     debugPrint("getGovernorateCounts called");
//     List<GovernorateCountPerOrder> governorateCounts = [];
//     try {
//       final response = await _orderService.getGovernorateCounts(_userViewModel.token);
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = jsonDecode(response.body);
//         governorateCounts = data.map((item) => GovernorateCountPerOrder.fromJson(item)).toList();
//       } else {
//         debugPrint("Failed to fetch governorate counts: ${response.statusCode}");
//       }
//     } catch (e) {
//       debugPrint("Error fetching governorate counts: $e");
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//     return governorateCounts;
//   }
//
//
//   Future<String> deleteOrderByID(String orderID) async {
//     String state = "";
//     try {
//       isLoading = true;
//       deletedOrder = orderID;
//       notifyListeners();
//
//       final response = await _orderService.deleteOrder(orderID, _userViewModel.token);
//       if (response.statusCode == 204) {
//         state = "deleted";
//
//       } else {
//         state = "not_deleted";
//         debugPrint("Failed to delete your order: ${response.statusCode}");
//       }
//     } catch (e) {
//       debugPrint("Error deleting your order: $e");
//     } finally {
//       isLoading = false;
//       deletedOrder = "";
//       notifyListeners();
//     }
//     return state;
//   }
//
//   // Future<String> addOrder({
//   //   required String customerID,
//   //   required String delivery,
//   //   required String discount,
//   //   required String notes,
//   //   required String orderSource,
//   //   required String paymentMethod,
//   //   required String downPayment,
//   //   required List<OrderItemModel> orderItems,
//   // }) async {
//   //   String status = "";
//   //   try {
//   //     isLoading = true;
//   //     notifyListeners();
//   //
//   //     // OrderModel orderModel = OrderModel.add(customerID: customerID, orderItems: orderItems,
//   //     //     orderSource: orderSource,
//   //     //     downPayment: downPayment,
//   //     //     paymentMethod: paymentMethod,
//   //     //     delivery: delivery, discount: discount, notes: notes);
//   //
//   //     // final response = await _orderService.addOrder(orderModel,_userViewModel.token);
//   //     //
//   //     // if (response.statusCode == 200 || response.statusCode == 201) {
//   //     //   status = "order_added";
//   //     // } else {
//   //     //   status = "order_not_added";
//   //     // }
//   //   } catch (e) {
//   //     status = "order_not_added";
//   //     print(e);
//   //   } finally {
//   //     isLoading = false;
//   //     notifyListeners();
//   //   }
//   //
//   //   return status;
//   // }
//
//   void clearOrder() {
//     orderModel = OrderModel();
//   }
//
//   void loadOrder(OrderModel existingOrder) {
//     // orderModel = OrderModel.get(
//     //   orderItems: existingOrder.orderItems,
//     //   orderSource: existingOrder.orderSource,
//     //   downPayment: existingOrder.downPayment,
//     //   paymentMethod: existingOrder.paymentMethod,
//     //   delivery: existingOrder.delivery,
//     //   customer: existingOrder.customer,
//     //   discount: existingOrder.discount,
//     //   orderID: existingOrder.orderId,
//     //   totalPrice: existingOrder.totalPrice,
//     //   orderDate: existingOrder.orderDate,
//     //   status: existingOrder.status, notes: existingOrder.notes,
//     // );
//     notifyListeners();
//   }
//
//   set addCustomer(CustomerModel value) {
//     // orderModel.customer = value;
//     notifyListeners();
//   }
//
//   set addToOrderItems(OrderItemsModel value) {
//     orderModel.orderItems.add(value);
//     notifyListeners();
//   }
//
//   set removeFromOrderItems(String productId) {
//     orderModel.orderItems.removeWhere((item) => item.productId == productId);
//     notifyListeners();
//   }
//
//   set incrementItemQuantity(int index) {
//     orderModel.orderItems[index].quantityToOrder++;
//     notifyListeners();
//   }
//
//   set decrementItemQuantity(int index) {
//     if(orderModel.orderItems[index].quantityToOrder > 1){
//       orderModel.orderItems[index].quantityToOrder--;
//       notifyListeners();
//     }
//     else {
//       orderModel.orderItems.remove(orderModel.orderItems[index]);
//       notifyListeners();
//     }
//   }
//
//   double getTotalPrice (){
//     double itemsTotal = 0.0;
//
//     itemsTotal = orderModel.orderItems.fold(0, (sum, item) {
//       final unitPrice = item.unitPrice ?? 0;
//       return sum + unitPrice * (item.quantityToOrder);
//     });
//
//     return itemsTotal;
//   }
//
//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:warsha_app/models/customerModel.dart';
import 'package:warsha_app/models/order_governorate_count.dart';

import 'package:warsha_app/models/orderItemModel.dart';
import 'package:warsha_app/models/orderModel.dart';
import 'package:warsha_app/services/orders_service.dart';
import 'package:warsha_app/core/network/api_exception.dart';

class AddOrderVM extends ChangeNotifier {
  final OrdersService _orderService;

  // This is the "cart" or "builder" object for the new order
  OrderModel orderModel =
      OrderModel(orderItems: []); // Start with an empty list
  Future<List<GovernorateCountPerOrder>>? allCounts;
  final TextEditingController searchController = TextEditingController();

  AddOrderVM(this._orderService) {
    searchController.addListener(() {
      notifyListeners();
    });

    allCounts = getGovernorateCounts();
  }

  Future<List<GovernorateCountPerOrder>> getGovernorateCounts() async {
    debugPrint("getGovernorateCounts called");
    List<GovernorateCountPerOrder> governorateCounts = [];
    try {
      governorateCounts = await _orderService.countsByGovernorate();
    } on ApiException catch (e) {
      debugPrint("Error fetching governorate counts: $e");
    } finally {
      notifyListeners();
    }
    return governorateCounts;
  }

  void clearOrder() {
    orderModel = OrderModel(orderItems: []); // Reset to a new, empty model
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
    item.quantityToOrder++;
    notifyListeners();
  }

  set decrementItemQuantity(int index) {
    final item = orderModel.orderItems[index];
    if (item.quantityToOrder > 1) {
      item.quantityToOrder--;
    } else {
      // If quantity is 1, decrementing removes it
      removeFromOrderItems = item.productId;
    }
    notifyListeners();
  }


  @override
  void dispose() {
    // You no longer have a search controller here
    searchController.dispose();
    super.dispose();
  }
}
