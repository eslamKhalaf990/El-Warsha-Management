import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/views/products/product_widget.dart';

class ProductList extends StatelessWidget {
  const ProductList({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<ProductVM>(context);

    return FutureBuilder<List<ProductModel>>(
      future: Provider.of<ProductVM>(context).allProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 200.0),
              child: SpinKitChasingDots(color: Theme.of(context).colorScheme.secondary, size: 30,),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.data!.isNotEmpty) {
          final query = Provider.of<ProductVM>(context).searchController.text.toLowerCase();
          final filteredProducts = snapshot.data!.where((product) {
            final name = product.name.toLowerCase();
            final sku = product.sku?.toLowerCase() ?? "";
            return name.contains(query) || sku.contains(query);
          }).take(30).toList();
          return Expanded(
            child: ListView.builder(
              itemCount: filteredProducts.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                return ProductWidget(
                  product: filteredProducts[index],
                );
              },
            ),
          );
        } else {
          return const Center(
            child: Text("No products yet!"),
          );
        }
      },
    );
  }
}