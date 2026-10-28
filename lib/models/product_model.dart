import 'package:warsha_app/models/json_read.dart';
import 'package:warsha_app/models/product_image.dart';
import 'package:warsha_app/models/product_variant.dart';

class ProductModel {
  String name;
  String nameAr = '';
  late String id;
  String productDescription;
  String descriptionAr = '';
  String sellingPrice;
  String buyingPrice;
  String discount;
  String totalPrice;
  String category;
  String categoryId;
  String quantity;
  String image;
  String? sku;

  /// Active sizes/colors; empty for products without variants.
  List<ProductVariant> variants = const [];

  bool get hasVariants => variants.isNotEmpty;

  /// Extra gallery images after the cover [image], in display order.
  List<ProductImage> images = const [];

  ProductModel.add({
    required this.name,
    required this.productDescription,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.discount,
    required this.totalPrice,
    required this.category,
    required this.quantity,
    required this.categoryId,
    required this.image,
    this.sku,
  });

  ProductModel.get({
    required this.name,
    required this.id,
    required this.productDescription,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.discount,
    required this.totalPrice,
    required this.category,
    required this.categoryId,
    required this.quantity,
    required this.image,
    this.sku,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final product = ProductModel.get(
      name: readString(json['name']),
      id: readString(json['id'] ?? json['productID']),
      productDescription: readString(json['description']),
      sellingPrice: readString(json['sellingPrice'], '0'),
      buyingPrice: readString(json['buyingPrice'], '0'),
      discount: readString(json['discount'], '0'),
      totalPrice: readString(json['totalPrice'], '0'),
      category: readString(json['categoryName']),
      categoryId: readString(json['categoryId']),
      quantity: readString(json['quantity'], '0'),
      sku: readStringOrNull(json['sku']),
      image: readString(json['imageUrl'], '-'),
    );
    product.nameAr = readString(json['nameAr']);
    product.descriptionAr = readString(json['descriptionAr']);
    product.variants = readList(json['variants']).map(ProductVariant.fromJson).toList();
    product.images = readList(json['images']).map(ProductImage.fromJson).toList();
    return product;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'productDescription': productDescription,
      'buyingPrice': buyingPrice.toString(),
      'sellingPrice': sellingPrice.toString(),
      'quantity': quantity,
      'categoryName': category,
      'categoryId': categoryId,
      'sku': sku,
    };
  }
}

/// What the product form holds, as typed. [ProductVM] validates and parses it.
class ProductForm {
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final String buyingPrice;
  final String sellingPrice;
  final String discount;
  final String quantity;
  final int? categoryId;

  const ProductForm({
    required this.name,
    this.nameAr = '',
    this.description = '',
    this.descriptionAr = '',
    required this.buyingPrice,
    required this.sellingPrice,
    this.discount = '',
    this.quantity = '',
    this.categoryId,
  });
}
