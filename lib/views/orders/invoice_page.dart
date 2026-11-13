import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/order_model.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

/// Opens the printable invoice of [order].
void openInvoice(BuildContext context, OrderModel order) {
  final api = context.read<ApiClient>();
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => InvoicePage(
          orderId: order.orderId!,
          pdf: api.getBytes('invoice/pdf/${order.orderId}')),
    ),
  );
}

/// The order's PDF invoice with a print / save button. [pdf] is started by
/// the caller once, so rebuilding the page doesn't download it again.
class InvoicePage extends StatelessWidget {
  const InvoicePage({super.key, required this.orderId, required this.pdf});

  final int orderId;
  final Future<Uint8List> pdf;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: pdf,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
                icon: const DirectionalIcon(Iconsax.arrow_left_copy),
                tooltip: tr('Back'),
                onPressed: () => Navigator.pop(context)),
            title: Text(tr('Invoice #{0}', [orderId])),
            actions: [
              if (bytes != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.s16),
                  child: AppButton.primary(
                    label: tr('Print or save'),
                    icon: Iconsax.printer_copy,
                    compact: true,
                    onPressed: () => Printing.layoutPdf(
                        name: 'invoice-$orderId.pdf',
                        onLayout: (_) async => bytes),
                  ),
                ),
            ],
          ),
          body: switch (snapshot) {
            AsyncSnapshot(hasError: true, :final error) => ErrorView(
                message: error is ApiException
                    ? error.message
                    : tr('The invoice couldn\'t be created.'),
                onRetry: () => Navigator.pop(context),
                retryLabel: tr('Go back'),
              ),
            AsyncSnapshot(:final data?) =>
              PdfViewer.data(data, sourceName: 'invoice-$orderId.pdf'),
            _ => const LoadingView(),
          },
        );
      },
    );
  }
}
