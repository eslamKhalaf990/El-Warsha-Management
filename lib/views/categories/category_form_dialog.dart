import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/view_models/category_v_m.dart';

/// Opens the add form, or the edit form for [category]. Resolves to true
/// when something was saved.
Future<bool> openCategoryForm(BuildContext context, {CategoryModel? category}) async {
  context.read<CategoryVM>().clearError();
  final saved = await showFormDialog<bool>(
    context,
    draft: () => FormDraft(
      text: {'name': category?.name, 'description': category?.description},
      values: {'imageUrl': category?.imageUrl},
    ),
    dialog: _CategoryFormDialog(category: category),
  );
  return saved == true;
}

class _CategoryFormDialog extends StatelessWidget {
  const _CategoryFormDialog({this.category});

  final CategoryModel? category;

  Future<void> _save(BuildContext context) async {
    final vm = context.read<CategoryVM>();
    final draft = context.read<FormDraft>();
    final request = CategoryRequest(
      name: draft.text('name'),
      description: draft.text('description'),
      imageUrl: draft.value<String>('imageUrl'),
    );
    final image = draft.value<PickedImage>('image');
    final ok = category == null
        ? await vm.add(request, image: image?.bytes, imageName: image?.name)
        : await vm.update(category!.categoryId, request, image: image?.bytes, imageName: image?.name);
    if (!context.mounted) return;
    if (ok) Navigator.pop(context, true);
    reportResult(
      context,
      ok: ok,
      errorMessage: vm.errorMessage,
      success: category == null ? 'Category added.' : 'Category updated.',
      fieldError: vm.fieldError,
      fields: const ['name', 'description'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryVM>();
    final draft = context.watch<FormDraft>();
    final savedUrl = draft.value<String>('imageUrl');

    return FormDialog(
      title: category == null ? 'New category' : 'Edit category',
      icon: Iconsax.category_2_copy,
      saveLabel: category == null ? 'Add category' : 'Save changes',
      saving: vm.isSaving,
      onSave: () => _save(context),
      children: [
        AppTextField(
          label: 'Name',
          required: true,
          icon: Iconsax.tag_copy,
          controller: draft.controller('name'),
          errorText: vm.fieldError('name'),
          maxLength: CategoryVM.nameMaxLength,
          autofocus: true,
          onChanged: (_) => vm.clearError(),
          onSubmitted: (_) => _save(context),
        ),
        AppTextField(
          label: 'Description',
          icon: Iconsax.note_text_copy,
          helperText: 'Shown under the category name in the store.',
          controller: draft.controller('description'),
          errorText: vm.fieldError('description'),
          maxLength: CategoryVM.descriptionMaxLength,
          maxLines: 3,
          onChanged: (_) => vm.clearError(),
        ),
        ImagePickerField(
          label: 'category image',
          height: 160,
          picked: draft.value<PickedImage>('image'),
          url: savedUrl == null ? null : CategoryModel(categoryId: 0, name: '', imageUrl: savedUrl).imageFullUrl,
          onPicked: (image) => draft.set('image', image),
          onRemove: () => draft
            ..set('image', null)
            ..set('imageUrl', null),
        ),
      ],
    );
  }
}
