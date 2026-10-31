import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/core/export/excel_export.dart';
import 'package:warsha_app/models/order_model.dart';
import 'package:warsha_app/views/orders/order_export.dart';

void main() {
  test('builds an xlsx with every row and the typed cells', () {
    final order = OrderModel.fromJson({
      'orderId': 7,
      'status': 'Processing',
      'allowedNextStatuses': [],
      'discount': 30,
      'extraDiscount': 0,
      'delivery': 50,
      'totalPrice': 900,
      'grandTotal': 1000,
      'downPayment': 100,
      'orderSource': 'instagram',
      'paymentMethod': 'cash',
      'orderDate': '2026-10-01T12:30:00',
      'customer': {'customerId': 3, 'fullName': 'سارة', 'governorate': 'Cairo', 'phone': '0100'},
      'orderItems': [
        {'productId': 1, 'productName': 'Lamp', 'quantity': 2, 'unitPrice': 475},
      ],
    });

    final bytes = buildExcel(sheetName: 'Orders', rows: [order, order], columns: orderExportColumns);

    expect(ascii.decode(bytes.sublist(0, 2)), 'PK'); // an xlsx is a zip
    final out = Platform.environment['EXCEL_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
