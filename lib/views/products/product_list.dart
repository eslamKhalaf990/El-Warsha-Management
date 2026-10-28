import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/ui/async_list_body.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/views/products/product_widget.dart';

class ProductList extends StatelessWidget {
  const ProductList({super.key});

  @override
  Widget build(BuildContext context) {
    final productVM = context.watch<ProductVM>();

    return Expanded(
      child: AsyncListBody(
        vm: productVM,
        items: productVM.products,
        query: productVM.query,
        onRefresh: productVM.fetch,
        emptyText: "No products yet.",
        itemBuilder: (_, product) => ProductWidget(product: product),
      ),
    );
  }
}
