import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/views/orders/order_actions.dart';
import 'package:warsha_app/models/order_model.dart';
import 'package:warsha_app/models/order_status.dart';

Widget host(OrderModel order) => MaterialApp(home: Scaffold(body: Center(child: OrderStatusControl(order: order))));

void main() {
  testWidgets('offers only the moves the backend allows', (tester) async {
    await tester.pumpWidget(host(OrderModel(
      orderId: 1,
      status: OrderStatus.processing,
      allowedNextStatuses: const [OrderStatus.shipped, OrderStatus.cancelled],
      orderItems: const [],
    )));

    await tester.tap(find.text('Processing'));
    await tester.pumpAndSettle();

    expect(find.text('Mark as Shipped'), findsOneWidget);
    expect(find.text('Cancel order'), findsOneWidget);
    expect(find.text('Mark as Completed'), findsNothing);
  });

  testWidgets('final orders show a read-only badge', (tester) async {
    await tester.pumpWidget(host(OrderModel(orderId: 1, status: OrderStatus.completed, orderItems: const [])));

    expect(find.byKey(const Key('orderStatusBadge')), findsOneWidget);
    expect(find.byType(PopupMenuButton<OrderStatus>), findsNothing);
  });

  testWidgets('unknown status shows a badge', (tester) async {
    await tester.pumpWidget(host(OrderModel(orderId: 1, orderItems: const [])));
    expect(find.text('Unknown'), findsOneWidget);
  });
}
