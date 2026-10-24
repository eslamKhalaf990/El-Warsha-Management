import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:warsha_app/models/orderModel.dart';

// This is the main function that does the work
Future<void> exportToExcel(List<OrderModel> orders) async {
  final Workbook workbook = Workbook();
  final Worksheet sheet = workbook.worksheets[0];
  sheet.name = 'Orders';

  final List<String> headers = [
    'Order ID',
    'Status',
    'Customer Name',
    'Customer Primary Phone',
    'Customer Secondary Phone',
    'Customer Address',
    'Customer Governorate',
    'Down Payment',
    'Discount',
    'Delivery',
    'Order Date',
    'Payment Method',
    'Order Source',
    'Item Count',
    'Total Price',
    'Item Summary',
    'Notes'
  ];

  // Write headers
  for (int i = 0; i < headers.length; i++) {
    sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
  }

  // Style the header
  final Style headerStyle = workbook.styles.add('headerStyle');
  headerStyle.bold = true;
  headerStyle.fontSize = 12;
  sheet.getRangeByIndex(1, 1, 1, headers.length).cellStyle = headerStyle;
  // 6. Add the order data
  for (int i = 0; i < orders.length; i++) {
    final order = orders[i];
    final int rowIndex = i + 2; // +1 for 1-based index, +1 to skip header

    sheet.getRangeByName('A$rowIndex').setValue(order.orderId ?? 'N/A');
    sheet.getRangeByName('B$rowIndex').setText(order.status?.label ?? 'Unknown');

    sheet.getRangeByName('C$rowIndex').setText(order.customer?.fullName ?? 'N/A');
    sheet.getRangeByName('D$rowIndex').setText(order.customer?.phone ?? 'N/A');
    sheet.getRangeByName('E$rowIndex').setText(order.customer?.secondaryPhone ?? 'N/A');
    sheet.getRangeByName('F$rowIndex').setText(order.customer?.address ?? 'N/A');
    sheet.getRangeByName('G$rowIndex').setText(order.customer?.governorate ?? 'N/A');

    const String egpFormat = r'#,##0.00 " EGP "';

    sheet.getRangeByName('H$rowIndex')
      ..setNumber(order.downPayment ?? 0.0)
      ..numberFormat = egpFormat;

    sheet.getRangeByName('I$rowIndex')
      ..setNumber(order.discount)
      ..numberFormat = egpFormat;

    sheet.getRangeByName('J$rowIndex')
      ..setNumber(order.delivery)
      ..numberFormat = egpFormat;


    if (order.orderDate != null) {
      sheet.getRangeByName('K$rowIndex')
        ..setDateTime(order.orderDate!)
        ..numberFormat = 'mm-dd-yyyy hh:mm AM/PM';
    } else {
      sheet.getRangeByName('I$rowIndex').setText('N/A');
    }

    sheet.getRangeByName('L$rowIndex').setText(order.paymentMethod ?? 'N/A');
    sheet.getRangeByName('M$rowIndex').setText(order.orderSource ?? 'N/A');

    sheet.getRangeByName('N$rowIndex').setNumber(order.orderItems.length.toDouble());

    sheet.getRangeByName('O$rowIndex')
      ..setNumber(order.totalPrice ?? 0.0)
      ..numberFormat = egpFormat;

    final String itemSummary = order.orderItems
        .map((item) => '${item.productName} (x${item.quantity})')
        .join(', ');

    sheet.getRangeByName('P$rowIndex').setText(itemSummary);
    sheet.getRangeByName('Q$rowIndex').setText(order.notes ?? '');
  }
  sheet.getRangeByName('A1:D1').autoFitColumns();
  final List<int> bytes = workbook.saveAsStream();

  workbook.dispose();
  await FileSaver.instance.saveFile(
    name: "customer_orders.xlsx",
    bytes: Uint8List.fromList(bytes),
    mimeType: MimeType.microsoftExcel,
  );
}