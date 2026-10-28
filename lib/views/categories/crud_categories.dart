import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/deafualt_form_field.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/category_v_m.dart';
import 'package:warsha_app/views/categories/add_category.dart';

class CRUDCategory extends StatefulWidget {
  const CRUDCategory({super.key});

  @override
  State<CRUDCategory> createState() => _CRUDCategoryState();
}

class _CRUDCategoryState extends State<CRUDCategory> {
  late final _searchController = TextEditingController(text: context.read<CategoryVM>().query);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 700;

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchField(context),
                  const SizedBox(height: 15),
                  _buildAddButton(context, isFullWidth: true),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(child: _buildSearchField(context)),
                  const SizedBox(width: 15),
                  _buildAddButton(context, isFullWidth: false),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return DefaultForm(
      title: 'Search Category by Name',
      controller: _searchController,
      numberOfLines: 1,
      onChanged: context.read<CategoryVM>().search,
    );
  }

  Widget _buildAddButton(BuildContext context, {required bool isFullWidth}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddCategory(),
          ),
        );
      },
      borderRadius: Constants.BORDER_RADIUS_50,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
        decoration: BoxDecoration(
          borderRadius: Constants.BORDER_RADIUS_50,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.add_circle_copy,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            const DefaultText(
              txt: "Add Category",
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}
