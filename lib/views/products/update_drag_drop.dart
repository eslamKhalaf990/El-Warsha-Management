import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/controllers/update_drag_drop.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/utils/image_helper.dart';
import 'package:warsha_app/views/products/image_library_dialog.dart';

class UpdateDragDropImageUpload extends StatefulWidget {
  const UpdateDragDropImageUpload({super.key, required this.productImage});
  final String productImage;

  @override
  State<UpdateDragDropImageUpload> createState() => _UpdateDragDropImageUploadState();
}

class _UpdateDragDropImageUploadState extends State<UpdateDragDropImageUpload> {
  final bool _dragging = false;

  @override
  void initState() {
    super.initState();
    Provider.of<UpdateDragDropController>(context, listen: false).loadFromUrl(ImageHelper.fullUrl(widget.productImage));
  }

  Future<void> _chooseFromLibrary(UpdateDragDropController drop) async {
    final picked = await showImageLibraryDialog(
      context,
      currentImage: drop.libraryFilename != null
          ? "/images/${drop.libraryFilename}"
          : widget.productImage,
    );
    if (picked != null) {
      await drop.selectFromLibrary(picked.filename, picked.url);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<UpdateDragDropController>(
      builder: (context, drop, child) => Stack(
        children: [
          Container(
            width: double.infinity,
            height: 500,
            margin: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              borderRadius: Constants.BORDER_RADIUS_20,
              color: _dragging
                  ? Colors.grey.withAlpha(100)
                  : Theme.of(context).colorScheme.tertiary.withAlpha(20),
            ),
            child: drop.droppedBytes == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const DefaultText(
                  txt: "Drop your image here\nor",
                ),
                const SizedBox(height: 5),
                ElevatedButton.icon(
                  style: ButtonStyle(
                    elevation: WidgetStateProperty.all(0),
                    padding:
                    WidgetStateProperty.all(const EdgeInsets.all(15)),
                  ),
                  onPressed: () async {
                    FilePickerResult? result =
                    await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true, // so we can get bytes on web
                    );

                    if (result != null &&
                        result.files.single.bytes != null) {
                      drop.updateDropFile(
                        result.files.single.bytes!,
                        result.files.single.name,
                      );
                    }
                  },
                  icon: const Icon(
                    Iconsax.document_upload,
                    // color: Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                  label: const DefaultText(
                    txt: 'Browse Images',
                    // color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _chooseFromLibrary(drop),
                  icon: const Icon(Iconsax.gallery, size: 20),
                  label: const DefaultText(txt: 'Choose from library'),
                ),
              ],
            )
                : Stack(
              children: [
                !drop.isLoading ? ClipRRect(
                  borderRadius: Constants.BORDER_RADIUS_20,
                  child: Image.memory(
                    drop.droppedBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ) : const Center(child: DefaultText(txt: "Loading...")),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: ElevatedButton.icon(
                    onPressed: () => _chooseFromLibrary(drop),
                    icon: const Icon(Iconsax.gallery, size: 18),
                    label: const DefaultText(txt: 'Choose from library'),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: () {
                      drop.clear();
                    },
                    icon: const Icon(
                      Iconsax.close_circle,
                      size: 30,
                    ),
                    color: Colors.red.shade300,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
