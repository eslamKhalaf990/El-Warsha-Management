import 'json_read.dart';

/// One size/color of a product, with its own stock (backend: ProductVariantDto).
class ProductVariant {
  final int id;
  final int productId;
  final String? size;
  final String? color;
  final String? colorAr;
  final String? colorHex;
  final String? sku;

  /// The variant's own price; null when it sells at the product's price.
  final double? sellingPrice;

  /// Price before discount (own price, else the product's).
  final double price;

  /// Price after the product discount.
  final double totalPrice;
  final int quantity;
  final String? imageUrl;

  const ProductVariant({
    required this.id,
    required this.productId,
    this.size,
    this.color,
    this.colorAr,
    this.colorHex,
    this.sku,
    this.sellingPrice,
    required this.price,
    required this.totalPrice,
    required this.quantity,
    this.imageUrl,
  });

  bool get inStock => quantity > 0;

  /// "M / Black", "M" or "Black".
  String get label => [size, color].where((s) => s != null && s.isNotEmpty).join(' / ');

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: readInt(json['id']) ?? 0,
        productId: readInt(json['productId']) ?? 0,
        size: readStringOrNull(json['size']),
        color: readStringOrNull(json['color']),
        colorAr: readStringOrNull(json['colorAr']),
        colorHex: readStringOrNull(json['colorHex']),
        sku: readStringOrNull(json['sku']),
        sellingPrice: readDoubleOrNull(json['sellingPrice']),
        price: readDouble(json['price']),
        totalPrice: readDouble(json['totalPrice']),
        quantity: readInt(json['quantity']) ?? 0,
        imageUrl: readStringOrNull(json['imageUrl']),
      );
}

/// Body of POST / PUT `products/{id}/variants`.
class ProductVariantRequest {
  final String? size;
  final String? color;
  final String? colorAr;
  final String? colorHex;
  final String? sku;
  final double? sellingPrice;
  final int quantity;

  const ProductVariantRequest({
    this.size,
    this.color,
    this.colorAr,
    this.colorHex,
    this.sku,
    this.sellingPrice,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'size': size,
        'color': color,
        'colorAr': colorAr,
        'colorHex': colorHex,
        'sku': sku,
        'sellingPrice': sellingPrice,
        'quantity': quantity,
      };
}
