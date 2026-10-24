import 'customerModel.dart';
import 'json_read.dart';
import 'orderItemModel.dart';
import 'order_status.dart';

/// An order as returned by the backend's OrderResponse.
class OrderModel {
  final int? orderId;
  OrderStatus? status;

  /// Statuses the backend allows next; empty once Completed or Cancelled.
  final List<OrderStatus> allowedNextStatuses;

  /// Total discount: product discounts + [extraDiscount].
  final double discount;

  /// Discount typed by staff on top of product discounts (what edit forms show).
  final double extraDiscount;
  final double delivery;
  final String? notes;

  /// Amount still to collect (grand total − down payment). Same as [amountDue].
  final double? totalPrice;

  /// Items total − discounts + delivery.
  final double? grandTotal;
  final double? downPayment;
  final String? orderSource;
  final String? paymentMethod;
  final DateTime? orderDate;
  final CustomerModel? customer;
  final List<OrderItemModel> orderItems;

  OrderModel({
    this.orderId,
    this.status,
    this.allowedNextStatuses = const [],
    this.discount = 0.0,
    this.extraDiscount = 0.0,
    this.delivery = 0.0,
    this.notes,
    this.totalPrice,
    this.grandTotal,
    this.downPayment,
    this.orderSource,
    this.paymentMethod,
    this.orderDate,
    this.customer,
    required this.orderItems,
  });

  double? get amountDue => totalPrice;

  OrderModel copyWith({
    CustomerModel? customer,
    List<OrderItemModel>? orderItems,
    double? discount,
    double? delivery,
    String? notes,
    double? totalPrice,
    double? downPayment,
    String? orderSource,
    String? paymentMethod,
    DateTime? orderDate,
    int? orderId,
    OrderStatus? status,
  }) {
    return OrderModel(
      customer: customer ?? this.customer,
      orderItems: orderItems ?? this.orderItems,
      discount: discount ?? this.discount,
      extraDiscount: extraDiscount,
      delivery: delivery ?? this.delivery,
      notes: notes ?? this.notes,
      totalPrice: totalPrice ?? this.totalPrice,
      grandTotal: grandTotal,
      downPayment: downPayment ?? this.downPayment,
      orderSource: orderSource ?? this.orderSource,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderDate: orderDate ?? this.orderDate,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      allowedNextStatuses: allowedNextStatuses,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final customer = readMap(json['customer']);
    final allowed = json['allowedNextStatuses'];
    return OrderModel(
      orderId: readInt(json['orderId']),
      status: OrderStatus.tryParse(json['status']),
      allowedNextStatuses: allowed is List
          ? allowed.map(OrderStatus.tryParse).whereType<OrderStatus>().toList()
          : const [],
      discount: readDouble(json['discount']),
      extraDiscount: readDouble(json['extraDiscount']),
      delivery: readDouble(json['delivery']),
      notes: readStringOrNull(json['notes']),
      totalPrice: readDoubleOrNull(json['amountDue'] ?? json['totalPrice']),
      grandTotal: readDoubleOrNull(json['grandTotal']),
      downPayment: readDoubleOrNull(json['downPayment']),
      orderSource: readStringOrNull(json['orderSource']),
      paymentMethod: readStringOrNull(json['paymentMethod']),
      orderDate: readDate(json['orderDate']),
      customer: customer == null ? null : CustomerModel.fromJson(customer),
      orderItems: readList(json['orderItems']).map(OrderItemModel.fromJson).toList(),
    );
  }
}
