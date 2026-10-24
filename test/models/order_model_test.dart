import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/models/orderModel.dart';
import 'package:warsha_app/models/order_status.dart';

void main() {
  group('OrderModel.fromJson', () {
    test('reads a full OrderResponse', () {
      final order = OrderModel.fromJson({
        'orderId': 7,
        'status': 'Processing',
        'allowedNextStatuses': ['Shipped', 'Cancelled'],
        'discount': 30,
        'extraDiscount': 10,
        'delivery': 50,
        'totalPrice': 900,
        'amountDue': 900,
        'grandTotal': 1000,
        'downPayment': 100,
        'notes': 'call first',
        'orderSource': 'Instagram',
        'paymentMethod': 'Cash',
        'orderDate': '2026-10-01T12:30:00',
        'customer': {
          'customerId': 3,
          'fullName': 'سارة',
          'governorate': 'Cairo',
          'phone': '0100',
        },
        'orderItems': [
          {'productId': 1, 'productName': 'Lamp', 'quantity': 2, 'unitPrice': 475},
        ],
      });

      expect(order.orderId, 7);
      expect(order.status, OrderStatus.processing);
      expect(order.allowedNextStatuses, [OrderStatus.shipped, OrderStatus.cancelled]);
      expect(order.discount, 30);
      expect(order.extraDiscount, 10);
      expect(order.delivery, 50);
      expect(order.amountDue, 900);
      expect(order.grandTotal, 1000);
      expect(order.downPayment, 100);
      expect(order.orderDate, DateTime(2026, 10, 1, 12, 30));
      expect(order.customer?.customerId, 3);
      expect(order.customer?.fullName, 'سارة');
      expect(order.orderItems.single.quantity, 2);
      expect(order.orderItems.single.orderedQuantity, 2);
      expect(order.orderItems.single.unitPrice, 475);
    });

    test('missing fields fall back to defaults instead of throwing', () {
      final order = OrderModel.fromJson({});

      expect(order.orderId, isNull);
      expect(order.status, isNull);
      expect(order.allowedNextStatuses, isEmpty);
      expect(order.discount, 0);
      expect(order.extraDiscount, 0);
      expect(order.delivery, 0);
      expect(order.amountDue, isNull);
      expect(order.orderDate, isNull);
      expect(order.customer, isNull);
      expect(order.orderItems, isEmpty);
    });

    test('accepts numbers sent as strings', () {
      final order = OrderModel.fromJson({
        'orderId': '12',
        'discount': '5.5',
        'delivery': '40',
        'amountDue': '120.25',
        'orderItems': [
          {'productId': '4', 'quantity': '3', 'unitPrice': '19.99'},
        ],
      });

      expect(order.orderId, 12);
      expect(order.discount, 5.5);
      expect(order.delivery, 40);
      expect(order.amountDue, 120.25);
      final item = order.orderItems.single;
      expect(item.productId, 4);
      expect(item.quantity, 3);
      expect(item.unitPrice, 19.99);
      expect(item.productName, '');
    });

    test('unknown status becomes null and unknown next statuses are dropped', () {
      final order = OrderModel.fromJson({
        'status': 'Lost in transit',
        'allowedNextStatuses': ['Completed', 'Teleported', 42],
      });

      expect(order.status, isNull);
      expect(order.allowedNextStatuses, [OrderStatus.completed]);
    });

    test('prefers amountDue over totalPrice', () {
      expect(OrderModel.fromJson({'amountDue': 80, 'totalPrice': 999}).amountDue, 80);
      expect(OrderModel.fromJson({'totalPrice': 999}).amountDue, 999);
    });

    test('skips malformed order items', () {
      final order = OrderModel.fromJson({
        'orderItems': [
          'oops',
          {'productId': 1, 'quantity': 0},
        ],
      });

      expect(order.orderItems, hasLength(1));
      // A zero quantity still edits as 1.
      expect(order.orderItems.single.orderedQuantity, 1);
    });
  });

  group('OrderStatus', () {
    test('parses labels, names and the US spelling of cancelled', () {
      expect(OrderStatus.tryParse('Shipped'), OrderStatus.shipped);
      expect(OrderStatus.tryParse(' pending '), OrderStatus.pending);
      expect(OrderStatus.tryParse('CANCELED'), OrderStatus.cancelled);
      expect(OrderStatus.tryParse(null), isNull);
      expect(OrderStatus.tryParse(3), isNull);
    });

    test('editable and final states follow the backend lifecycle', () {
      expect(OrderStatus.values.where((s) => s.isEditable),
          [OrderStatus.pending, OrderStatus.processing]);
      expect(OrderStatus.values.where((s) => s.isFinal),
          [OrderStatus.completed, OrderStatus.cancelled]);
    });
  });
}
