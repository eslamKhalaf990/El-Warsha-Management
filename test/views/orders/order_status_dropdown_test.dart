import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/models/orderModel.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/views/orders/order_status_control.dart';

Widget host(OrderModel order) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 160, height: 30, child: OrderStatusDropdown(order: order)),
        ),
      ),
    );

void main() {
  testWidgets('offers only the current and allowed next statuses', (tester) async {
    await tester.pumpWidget(host(OrderModel(
      orderId: 1,
      status: OrderStatus.processing,
      allowedNextStatuses: const [OrderStatus.shipped, OrderStatus.cancelled],
      orderItems: const [],
    )));

    await tester.tap(find.byType(DropdownButton<OrderStatus>));
    await tester.pumpAndSettle();

    final offered = tester
        .widgetList<DropdownMenuItem<OrderStatus>>(find.byType(DropdownMenuItem<OrderStatus>))
        .map((i) => i.value)
        .toSet();
    expect(offered, {OrderStatus.processing, OrderStatus.shipped, OrderStatus.cancelled});
  });

  testWidgets('final orders show a read-only badge', (tester) async {
    await tester.pumpWidget(host(OrderModel(
      orderId: 1,
      status: OrderStatus.completed,
      orderItems: const [],
    )));

    expect(find.byKey(const Key('orderStatusBadge')), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.byType(DropdownButton<OrderStatus>), findsNothing);
  });

  testWidgets('unknown status shows a badge', (tester) async {
    await tester.pumpWidget(host(OrderModel(orderId: 1, orderItems: const [])));
    expect(find.text('Unknown'), findsOneWidget);
  });
}
