import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/ui/async_list_body.dart';
import 'package:warsha_app/view_models/category_v_m.dart';
import 'package:warsha_app/views/categories/category_widget.dart';
import 'package:warsha_app/views/categories/crud_categories.dart';

class Categories extends StatelessWidget {
  const Categories({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryVM = context.watch<CategoryVM>();

    return Column(
      children: [
        const CRUDCategory(),
        Expanded(
          child: AsyncListBody(
            vm: categoryVM,
            items: categoryVM.categories,
            query: categoryVM.query,
            onRefresh: categoryVM.fetch,
            emptyText: "No categories yet.",
            itemBuilder: (_, category) => CategoryWidget(category: category),
          ),
        ),
      ],
    );
  }
}
