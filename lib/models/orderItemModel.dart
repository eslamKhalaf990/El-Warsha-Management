import 'json_read.dart';

class OrderItemModel {
  final int productId;
  final String productName;

  /// The ordered size/color; null for products without variants.
  final int? variantId;
  final String? size;
  final String? color;

  /// Quantity as stored on the server for an existing order.
  final int quantity;
  final double unitPrice;

  /// Quantity being entered on the "add order" screen.
  int quantityToOrder = 1;

  /// Quantity being edited on the "update order" screen.
  int orderedQuantity = 1;

  /// The product's per-unit discount, for live totals on the order forms.
  /// Not part of the API response; the backend applies it itself.
  double unitDiscount = 0;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.variantId,
    this.size,
    this.color,
  });

  /// "M / Black", or empty for products without variants.
  String get variantLabel => [size, color].where((s) => s != null && s.isNotEmpty).join(' / ');

  /// Product name with its size/color, for order lines.
  String get displayName => variantLabel.isEmpty ? productName : '$productName ($variantLabel)';

  /// True when this line is for the same product and size/color.
  bool sameLineAs(OrderItemModel other) => productId == other.productId && variantId == other.variantId;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final item = OrderItemModel(
      productId: readInt(json['productId']) ?? 0,
      productName: readString(json['productName']),
      quantity: readInt(json['quantity']) ?? 0,
      unitPrice: readDouble(json['unitPrice']),
      variantId: readInt(json['variantId']),
      size: readStringOrNull(json['size']),
      color: readStringOrNull(json['color']),
    );
    item.orderedQuantity = item.quantity > 0 ? item.quantity : 1;
    return item;
  }
}
