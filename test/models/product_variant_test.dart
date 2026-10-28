import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/models/orderItemModel.dart';
import 'package:warsha_app/models/order_request.dart';
import 'package:warsha_app/models/product_model.dart';

void main() {
  test('product reads Arabic text and variants', () {
    final p = ProductModel.fromJson({
      'id': 5,
      'name': 'Tote bag',
      'nameAr': 'شنطة',
      'description': 'Canvas',
      'descriptionAr': 'قماش',
      'sellingPrice': 300.0,
      'buyingPrice': 100.0,
      'discount': 20.0,
      'totalPrice': 280.0,
      'categoryName': 'Bags',
      'categoryId': 1,
      'quantity': '7',
      'hasVariants': true,
      'variants': [
        {'id': 9, 'productId': 5, 'size': 'L', 'color': 'Black', 'sellingPrice': null,
         'price': 300.0, 'totalPrice': 280.0, 'quantity': 7, 'inStock': true},
      ],
    });

    expect(p.nameAr, 'شنطة');
    expect(p.descriptionAr, 'قماش');
    expect(p.hasVariants, isTrue);
    expect(p.variants.single.label, 'L / Black');
    expect(p.variants.single.sellingPrice, isNull);
  });

  test('product reads its gallery images in order', () {
    final p = ProductModel.fromJson({
      'id': 5, 'name': 'Tote', 'description': '', 'sellingPrice': 1, 'buyingPrice': 1, 'discount': 0,
      'totalPrice': 1, 'categoryName': 'Bags', 'categoryId': 1, 'quantity': '1',
      'imageUrl': '/images/cover.jpg',
      'images': [
        {'id': 3, 'imageUrl': '/images/b.jpg', 'sortOrder': 0},
        {'id': 4, 'imageUrl': 'https://cdn.example.com/c.jpg', 'sortOrder': 1},
      ],
    });
    expect(p.images.map((i) => i.id), [3, 4]);
    expect(p.images.first.fullUrl, endsWith('/images/b.jpg'));
    expect(p.images.first.fullUrl, startsWith('http'));
    expect(p.images.last.fullUrl, 'https://cdn.example.com/c.jpg');
  });

  test('older responses without the new fields still parse', () {
    final p = ProductModel.fromJson({
      'id': 1, 'name': 'Mug', 'description': '', 'sellingPrice': 50, 'buyingPrice': 20,
      'discount': 0, 'totalPrice': 50, 'categoryName': 'Home', 'categoryId': 2, 'quantity': '3',
    });
    expect(p.nameAr, '');
    expect(p.hasVariants, isFalse);
    expect(p.images, isEmpty);
  });

  test('order lines carry their size/color', () {
    final item = OrderItemModel.fromJson(
        {'productId': 5, 'productName': 'Tote bag', 'variantId': 9, 'size': 'L', 'color': 'Black',
         'quantity': 2, 'unitPrice': 300});
    expect(item.displayName, 'Tote bag (L / Black)');
    expect(item.sameLineAs(OrderItemModel(productId: 5, productName: '', quantity: 1, unitPrice: 0, variantId: 9)), isTrue);
    expect(item.sameLineAs(OrderItemModel(productId: 5, productName: '', quantity: 1, unitPrice: 0)), isFalse);

    expect(const OrderLineRequest(productId: 5, quantity: 2, variantId: 9).toJson()['variantId'], 9);
    expect(const OrderLineRequest(productId: 1, quantity: 1).toJson().containsKey('variantId'), isFalse);
  });
}
