import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

/// One column of an Excel export: its header and how to read a row's value.
///
/// [value] may return a number, a [DateTime], a string or null (blank cell).
/// Numbers stay numbers so Excel can sum and sort them; [money] adds the EGP
/// format.
class ExcelColumn<T> {
  const ExcelColumn(this.header, this.value, {this.money = false});

  final String header;
  final Object? Function(T row) value;
  final bool money;
}

const _moneyFormat = r'#,##0.00 "EGP"';
const _dateFormat = 'dd mmm yyyy hh:mm AM/PM';

/// Saves [rows] as `<fileName>_<yyyy-MM-dd>.xlsx` through the browser.
Future<void> saveExcel<T>({
  required String fileName,
  required String sheetName,
  required List<T> rows,
  required List<ExcelColumn<T>> columns,
}) async {
  final bytes = buildExcel(sheetName: sheetName, rows: rows, columns: columns);
  final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
  await FileSaver.instance.saveFile(
    name: '${fileName}_$stamp.xlsx',
    bytes: bytes,
    mimeType: MimeType.microsoftExcel,
  );
}

/// A one-sheet workbook of [rows]. The header row is bold, frozen and has
/// filter buttons.
Uint8List buildExcel<T>({
  required String sheetName,
  required List<T> rows,
  required List<ExcelColumn<T>> columns,
}) {
  final workbook = Workbook();
  try {
    final sheet = workbook.worksheets[0]..name = sheetName;

    for (var c = 0; c < columns.length; c++) {
      sheet.getRangeByIndex(1, c + 1).setText(columns[c].header);
    }
    sheet.getRangeByIndex(1, 1, 1, columns.length).cellStyle
      ..bold = true
      ..backColor = '#F3E9EC';

    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < columns.length; c++) {
        final cell = sheet.getRangeByIndex(r + 2, c + 1);
        switch (columns[c].value(rows[r])) {
          case num n:
            cell.setNumber(n.toDouble());
            if (columns[c].money) cell.numberFormat = _moneyFormat;
          case DateTime d:
            cell
              ..setDateTime(d.toLocal())
              ..numberFormat = _dateFormat;
          case String s when s.trim().isNotEmpty && s.trim() != '—':
            cell.setText(s.trim());
          default:
            break;
        }
      }
    }

    sheet.getRangeByName('A2').freezePanes();
    sheet.autoFilters.filterRange = sheet.getRangeByIndex(1, 1, rows.length + 1, columns.length);
    for (var c = 1; c <= columns.length; c++) {
      sheet.autoFitColumn(c);
    }

    return Uint8List.fromList(workbook.saveAsStream());
  } finally {
    workbook.dispose();
  }
}
