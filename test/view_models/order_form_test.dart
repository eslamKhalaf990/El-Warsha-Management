import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/models/customerModel.dart';
import 'package:warsha_app/models/orderItemModel.dart';
import 'package:warsha_app/services/orders_service.dart';
import 'package:warsha_app/view_models/order_v_m.dart';

final customer = CustomerModel(
  customerId: 7, fullName: 'Sara', governorate: 'القاهرة', secondaryPhone: '', city: '', phone: '01001234567', address: '');

OrderItemModel item({double price = 100, int qty = 2, double unitDiscount = 0}) =>
    OrderItemModel(productId: 1, productName: 'Ring', quantity: 10, unitPrice: price)
      ..quantityToOrder = qty
      ..unitDiscount = unitDiscount;

OrderForm form({
  CustomerModel? who,
  List<OrderItemModel>? items,
  String payment = 'Cash',
  String source = 'Instagram',
  String down = '',
  String delivery = '50',
  String discount = '',
}) =>
    OrderForm(
      customer: who,
      items: items ?? [item()],
      quantityOf: (i) => i.quantityToOrder,
      paymentMethod: payment,
      orderSource: source,
      downPayment: down,
      delivery: delivery,
      discount: discount,
    );

void main() {
  var calls = 0;
  final vm = OrderVM(OrdersService(ApiClient(
    baseUrl: 'http://api.test/',
    client: MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    }),
  )));

  test('missing customer, items, payment method and source are all reported', () {
    final errors = vm.validateOrder(form(items: [], payment: '-', source: ' '));
    expect(errors.keys, containsAll(['customerId', 'items', 'paymentMethod', 'orderSource']));
  });

  test('amounts must be numbers of 0 or more; comma decimals work', () {
    final errors = vm.validateOrder(form(who: customer, down: 'abc', delivery: '-1', discount: '10,5'));
    expect(errors['downPayment'], 'Down payment must be a number.');
    expect(errors['delivery'], "Delivery can't be negative.");
    expect(errors.containsKey('discount'), isFalse);
  });

  test('discount and down payment are checked against the total', () {
    // 2 × 100 + 50 delivery = 250
    expect(vm.validateOrder(form(who: customer, discount: '300'))['discount'],
        "Discount can't be more than the order total.");
    expect(vm.validateOrder(form(who: customer, down: '260'))['downPayment'],
        "Down payment can't be more than the order total.");
    expect(vm.validateOrder(form(who: customer, down: '250')), isEmpty);
  });

  test('checkOrder exposes errors per field without calling the server', () {
    expect(vm.checkOrder(form()), isFalse);
    expect(vm.fieldError('customerId'), 'Choose a customer.');
    expect(calls, 0);

    expect(vm.checkOrder(form(who: customer)), isTrue);
    expect(vm.lastError, isNull);
  });

  test('the request carries typed amounts and the bank account', () {
    final f = form(who: customer, down: '100', discount: '5,5');
    expect(f.needsBankAccount, isTrue);

    final json = f.toRequest(bankAccountId: 3).toJson();
    expect(json['customerId'], 7);
    expect(json['downPayment'], 100);
    expect(json['discount'], 5.5);
    expect(json['bankAccountId'], 3);
    expect((json['items'] as List).single, {'productId': 1, 'quantity': 2, 'unitPrice': 100.0});
  });
}
