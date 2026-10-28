import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/utils/default_button.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/category_v_m.dart';

/// Add a category, or edit [category] when given.
class AddCategory extends StatefulWidget {
  const AddCategory({super.key, this.category});

  final CategoryModel? category;

  @override
  State<AddCategory> createState() => _AddCategoryState();
}

class _AddCategoryState extends State<AddCategory> {
  late final _nameController = TextEditingController(text: widget.category?.name);
  late final _descriptionController = TextEditingController(text: widget.category?.description);

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    // Errors from a previous visit don't belong to this form.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoryVM>().clearError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = context.read<CategoryVM>();
    final request = CategoryRequest(name: _nameController.text, description: _descriptionController.text);
    final ok = _isEdit ? await vm.update(widget.category!.categoryId, request) : await vm.add(request);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      showSuccess(context, _isEdit ? 'Category updated.' : 'Category added.');
    } else if (vm.fieldError('name') == null && vm.fieldError('description') == null) {
      // Not about a field (network, server...): say it in a snackbar.
      showError(context, vm.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryVM = context.watch<CategoryVM>();

    return Scaffold(
      appBar: AppBar(
        title: DefaultText(txt: _isEdit ? "Edit Category" : "Add New Category", bold: true, size: 20),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Category Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 25),
              DefaultCategoryForm(
                title: "Category Name *",
                controller: _nameController,
                icon: Iconsax.category_copy,
                errorText: categoryVM.fieldError('name'),
                maxLength: CategoryVM.nameMaxLength,
                onChanged: (_) => categoryVM.clearError(),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 15),
              DefaultCategoryForm(
                title: "Description (optional)",
                controller: _descriptionController,
                icon: Iconsax.note_text,
                errorText: categoryVM.fieldError('description'),
                maxLength: CategoryVM.descriptionMaxLength,
                maxLines: 3,
                onChanged: (_) => categoryVM.clearError(),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2,
                    child: DefaultButton(
                      onTap: _save,
                      isValid: !categoryVM.isSaving,
                      isLoading: categoryVM.isSaving,
                      title: _isEdit ? "Save Changes" : "Save Category",
                      margin: EdgeInsets.zero,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DefaultCategoryForm extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final IconData icon;
  final String? errorText;
  final int? maxLength;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const DefaultCategoryForm({
    super.key,
    required this.title,
    required this.controller,
    required this.icon,
    this.errorText,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(maxLines > 1 ? 15 : 25);
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: title,
        errorText: errorText,
        errorMaxLines: 2,
        counterText: '',
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade200),
          borderRadius: radius,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 1.5),
          borderRadius: radius,
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
          borderRadius: radius,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
          borderRadius: radius,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Icon(icon, color: Theme.of(context).colorScheme.tertiary),
        ),
      ),
    );
  }
}
