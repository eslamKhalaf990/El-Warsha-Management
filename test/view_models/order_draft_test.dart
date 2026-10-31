import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/models/customer_model.dart';
import 'package:warsha_app/models/order_item_model.dart';
import 'package:warsha_app/models/order_model.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/models/product_variant.dart';
import 'package:warsha_app/view_models/order_draft.dart';

ProductModel product(String id, {String price = '100', String discount = '0'}) => ProductModel.get(
      name: 'Ring $id',
      id: id,
      productDescription: '',
      buyingPrice: '50',
      sellingPrice: price,
      discount: discount,
      totalPrice: price,
      category: 'Rings',
      categoryId: '1',
      quantity: '10',
      image: '-',
    );

CustomerModel customer() => CustomerModel(
      customerId: 7,
      fullName: 'Mona',
      governorate: 'القاهرة',
      secondaryPhone: '',
      city: '',
      phone: '01012345678',
      address: '',
    );

void main() {
  test('adding the same product twice grows one line', () {
    final d = OrderDraft()..addLine(product('1'))..addLine(product('1'), quantity: 2);

    expect(d.items, hasLength(1));
    expect(d.items.single.quantityToOrder, 3);
  });

  test('each size / color is its own line, priced by the variant', () {
    const m = ProductVariant(id: 1, productId: 1, size: 'M', price: 120, totalPrice: 120, quantity: 3);
    const l = ProductVariant(id: 2, productId: 1, size: 'L', price: 130, totalPrice: 130, quantity: 3);
    final d = OrderDraft()
      ..addLine(product('1'), variant: m)
      ..addLine(product('1'), variant: l);

    expect(d.items.map((i) => (i.size, i.unitPrice)), [('M', 120.0), ('L', 130.0)]);
  });

  test('quantity below 1 removes the line', () {
    final d = OrderDraft()..addLine(product('1'));
    d.setQuantity(0, 0);
    expect(d.items, isEmpty);
  });

  test('totals use product discounts and typed amounts', () {
    final d = OrderDraft()..addLine(product('1', discount: '10'), quantity: 2);
    d.controller('delivery').text = '50';
    d.controller('discount').text = '20';
    d.controller('downPayment').text = '100';

    final t = d.totals;
    expect(t.subtotal, 200);
    expect(t.grandTotal, 200 - 20 - 20 + 50);
    expect(t.amountDue, 210 - 100);
  });

  test('picking a customer fills an empty delivery, then follows later picks', () {
    final d = OrderDraft()..selectCustomer(customer(), deliveryPrice: 60);
    expect(d.text('delivery'), '60');

    d.selectCustomer(customer(), deliveryPrice: 80);
    expect(d.text('delivery'), '80');

    d.set('deliveryAuto', false); // typed by hand
    d.selectCustomer(customer(), deliveryPrice: 90);
    expect(d.text('delivery'), '80');
  });

  test('editing starts from the order and is not dirty until changed', () {
    final order = OrderModel(
      orderId: 5,
      customer: customer(),
      delivery: 40,
      notes: '-',
      orderSource: 'facebook',
      paymentMethod: 'cash',
      orderItems: [
        OrderItemModel(productId: 1, productName: 'Ring', quantity: 2, unitPrice: 100)..orderedQuantity = 2,
      ],
    );
    final d = OrderDraft(order: order, unitDiscounts: {1: 5});

    expect(d.isEdit, isTrue);
    expect(d.text('notes'), '');
    expect(d.items.single.quantityToOrder, 2);
    expect(d.items.single.unitDiscount, 5);
    expect(d.isDirty, isFalse);

    d.setQuantity(0, 3);
    expect(d.isDirty, isTrue);
  });
}
