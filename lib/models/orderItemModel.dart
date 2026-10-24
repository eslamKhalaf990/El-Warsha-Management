import 'json_read.dart';

class OrderItemModel {
  final int productId;
  final String productName;

  /// Quantity as stored on the server for an existing order.
  final int quantity;
  final double unitPrice;

  /// Quantity being entered on the "add order" screen.
  int quantityToOrder = 1;

  /// Quantity being edited on the "update order" screen.
  int orderedQuantity = 1;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final item = OrderItemModel(
      productId: readInt(json['productId']) ?? 0,
      productName: readString(json['productName']),
      quantity: readInt(json['quantity']) ?? 0,
      unitPrice: readDouble(json['unitPrice']),
    );
    item.orderedQuantity = item.quantity > 0 ? item.quantity : 1;
    return item;
  }
}
