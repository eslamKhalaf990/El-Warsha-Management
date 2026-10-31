import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/core/export/excel_export.dart';
import 'package:warsha_app/core/format/formatters.dart';
import 'package:warsha_app/core/widgets/feedback.dart';

/// A header button that saves [rows] as an Excel file and reports how many
/// were exported. [rows] is read on tap, so it exports every row the page's
/// filters match, not only the page on screen.
class ExportExcelButton<T> extends StatelessWidget {
  const ExportExcelButton({
    super.key,
    required this.rows,
    required this.columns,
    required this.fileName,
    required this.sheetName,
    required this.noun,
  });

  final List<T> Function() rows;
  final List<ExcelColumn<T>> columns;
  final String fileName;
  final String sheetName;

  /// Singular, for "12 customers exported."
  final String noun;

  Future<void> _export(BuildContext context) async {
    final data = rows();
    if (data.isEmpty) return showInfo(context, 'There are no ${noun}s to export.');
    try {
      await saveExcel(fileName: fileName, sheetName: sheetName, rows: data, columns: columns);
      if (context.mounted) showSuccess(context, '${Fmt.count(data.length, noun)} exported.');
    } catch (_) {
      if (context.mounted) showError(context, "The Excel file couldn't be created.");
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Export to Excel',
        icon: const Icon(Iconsax.document_download_copy),
        onPressed: () => _export(context),
      );
}
