import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/core/theme/app_theme.dart';
import 'package:warsha_app/core/widgets/app_button.dart';
import 'package:warsha_app/core/widgets/app_fields.dart';
import 'package:warsha_app/core/widgets/app_image.dart';
import 'package:warsha_app/core/widgets/app_text.dart';

/// An image chosen on this device, not uploaded yet.
class PickedImage {
  const PickedImage(this.bytes, this.name);

  final Uint8List bytes;
  final String name;
}

const _imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

/// Opens the system file picker for one image.
Future<PickedImage?> pickImage() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
  final file = result?.files.single;
  if (file?.bytes == null) return null;
  return PickedImage(file!.bytes!, file.name);
}

/// Opens the system file picker for several images.
Future<List<PickedImage>> pickImages() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true, allowMultiple: true);
  return [
    for (final f in result?.files ?? const <PlatformFile>[])
      if (f.bytes != null) PickedImage(f.bytes!, f.name),
  ];
}

/// Image preview with Choose / Replace / Remove. On web and desktop an image
/// can also be dropped onto it.
///
/// Shows [picked] when set, else the saved image at [url], else a prompt.
class ImagePickerField extends StatelessWidget {
  const ImagePickerField({
    super.key,
    required this.onPicked,
    this.picked,
    this.url,
    this.onRemove,
    this.errorText,
    this.height = 220,
    this.label = 'Image',
  });

  final PickedImage? picked;
  final String? url;
  final ValueChanged<PickedImage> onPicked;

  /// Clears the picked / saved image; hidden when null.
  final VoidCallback? onRemove;
  final String? errorText;
  final double height;
  final String label;

  Future<void> _choose() async {
    final image = await pickImage();
    if (image != null) onPicked(image);
  }

  Future<void> _dropped(DropDoneDetails details) async {
    for (final file in details.files) {
      final ext = file.name.split('.').last.toLowerCase();
      if (!_imageExtensions.contains(ext)) continue;
      onPicked(PickedImage(await file.readAsBytes(), file.name));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = picked != null || (url != null && url!.isNotEmpty);
    final border = errorText != null ? AppStatusColors.errorText : AppColors.line;

    final preview = picked != null
        ? ClipRRect(
            borderRadius: AppRadius.inputBorderRadius,
            child: Image.memory(picked!.bytes, fit: BoxFit.cover, width: double.infinity, height: height),
          )
        : AppNetworkImage(url, height: height, width: double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropTarget(
          onDragDone: _dropped,
          child: Semantics(
            button: true,
            label: hasImage ? 'Replace $label' : 'Choose $label',
            child: InkWell(
              onTap: _choose,
              borderRadius: AppRadius.inputBorderRadius,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: AppRadius.inputBorderRadius,
                  border: Border.all(color: border, width: hasImage ? 1 : 1.5),
                ),
                child: hasImage
                    ? preview
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.gallery_add_copy, size: 36, color: AppColors.burgundy),
                          SizedBox(height: AppSpacing.s8),
                          AppText.label('Click to choose an image'),
                          AppText.caption('or drop it here · JPG, PNG or WebP'),
                        ],
                      ),
              ),
            ),
          ),
        ),
        FieldError(errorText),
        if (hasImage) ...[
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            children: [
              AppButton.secondary(label: 'Replace', icon: Iconsax.gallery_edit_copy, compact: true, onPressed: _choose),
              if (onRemove != null)
                AppButton.text(label: 'Remove', icon: Iconsax.trash_copy, compact: true, onPressed: onRemove),
            ],
          ),
        ],
      ],
    );
  }
}
