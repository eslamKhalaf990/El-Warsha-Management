import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/utils/default_text.dart';

class PDFViewPage extends StatefulWidget {
  const PDFViewPage({super.key, required this.pdfPath});
  final String pdfPath;

  @override
  State<PDFViewPage> createState() => _PDFViewPageState();
}

class _PDFViewPageState extends State<PDFViewPage> {
  Uint8List? pdfBytes;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      // Invoices are admin-only, so they go through ApiClient to carry the token.
      final bytes = await context.read<ApiClient>().getBytes(widget.pdfPath);
      if (mounted) setState(() => pdfBytes = bytes);
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  // 2. Create a function to handle the printing logic
  Future<void> _printPdf() async {
    // Check if the PDF bytes are loaded
    if (pdfBytes != null) {
      // Use the Printing.layoutPdf function to print the PDF
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const DefaultText(txt: "Invoice", size: 16, bold: true,),

        actions: [
          // We only want to show the print button if the PDF has been loaded
          if (pdfBytes != null)
            Row(
              children: [
                const DefaultText(txt: "Save & Print", size: 16, bold: true,),
                const SizedBox(width: 5,),
                IconButton(
                  icon: const Icon(Iconsax.printer),
                  tooltip: 'Print PDF',
                  onPressed: _printPdf,
                ),
              ],
            ),
        ],
      ),
      body: pdfBytes != null
          ? PdfViewer.data(
        pdfBytes!,
        sourceName: widget.pdfPath, // It's good practice to provide a sourceName
      )
          : error != null
          ? Center(child: Text(error!))
          : const Center(child: CircularProgressIndicator()),
    );
  }
}