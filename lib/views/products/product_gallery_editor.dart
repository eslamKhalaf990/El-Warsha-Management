import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/product_image.dart';
import 'package:warsha_app/services/product_images_service.dart';

/// Opens the gallery editor for a product. Resolves to the gallery as it is
/// when the dialog closes.
Future<List<ProductImage>?> showProductGalleryEditor(
    BuildContext context, {required int productId, required String productName, String? coverUrl}) {
  return showDialog<List<ProductImage>>(
    context: context,
    builder: (_) => ProductGalleryEditor(productId: productId, productName: productName, coverUrl: coverUrl),
  );
}

/// Extra images shown after the cover in the store's product gallery:
/// upload new ones, pick from the library, reorder and remove.
class ProductGalleryEditor extends StatefulWidget {
  const ProductGalleryEditor({super.key, required this.productId, required this.productName, this.coverUrl});

  final int productId;
  final String productName;
  final String? coverUrl;

  @override
  State<ProductGalleryEditor> createState() => _ProductGalleryEditorState();
}

class _ProductGalleryEditorState extends State<ProductGalleryEditor> {
  List<ProductImage> _images = [];
  bool _busy = true;
  String? _error;

  ProductImagesService get _service => context.read<ProductImagesService>();

  @override
  void initState() {
    super.initState();
    _run(() async => _images = await _service.list(widget.productId));
  }

  /// Runs [action] with a spinner and shows any API error in the dialog.
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
    if (result == null) return;
    await _run(() async {
      for (final file in result.files) {
        if (file.bytes == null) continue;
        _images = [..._images, await _service.upload(widget.productId, file.bytes!, file.name)];
      }
    });
  }

  Future<void> _pickFromLibrary() async {
    List<String> library = [];
    await _run(() async => library = await _service.library());
    if (!mounted || library.isEmpty) return;
    final filename = await showDialog<String>(
      context: context,
      builder: (_) => _LibraryPicker(filenames: library),
    );
    if (filename == null) return;
    await _run(() async => _images = [..._images, await _service.addFromLibrary(widget.productId, filename)]);
  }

  Future<void> _move(int index, int by) async {
    final target = index + by;
    if (target < 0 || target >= _images.length) return;
    final ids = _images.map((i) => i.id).toList();
    ids.insert(target, ids.removeAt(index));
    await _run(() async => _images = await _service.reorder(widget.productId, ids));
  }

  Future<void> _remove(ProductImage image) => _run(() async {
        await _service.remove(widget.productId, image.id);
        _images = _images.where((i) => i.id != image.id).toList();
      });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text("Gallery · ${widget.productName}"),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Customers swipe through the cover first, then these images in this order.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (widget.coverUrl != null && widget.coverUrl!.isNotEmpty && widget.coverUrl != "-")
                  _Thumb(url: imageFullUrl(widget.coverUrl!), label: "Cover"),
                for (var i = 0; i < _images.length; i++)
                  _Thumb(
                    url: _images[i].fullUrl,
                    label: "${i + 1}",
                    actions: [
                      _ThumbAction(Iconsax.arrow_left_2, "Move earlier", _busy || i == 0 ? null : () => _move(i, -1)),
                      _ThumbAction(Iconsax.trash, "Remove", _busy ? null : () => _remove(_images[i]), danger: true),
                      _ThumbAction(Iconsax.arrow_right_3, "Move later",
                          _busy || i == _images.length - 1 ? null : () => _move(i, 1)),
                    ],
                  ),
              ],
            ),
            if (!_busy && _images.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text("No extra images yet.", style: TextStyle(color: Colors.grey)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _busy ? null : _pickFromLibrary,
          icon: const Icon(Iconsax.gallery),
          label: const Text("From library"),
        ),
        TextButton.icon(
          onPressed: _busy ? null : _upload,
          icon: const Icon(Iconsax.document_upload),
          label: const Text("Upload images"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _images),
          child: const Text("Done"),
        ),
      ],
    );
  }
}

class _ThumbAction {
  const _ThumbAction(this.icon, this.tooltip, this.onPressed, {this.danger = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool danger;
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.label, this.actions = const []});

  final String url;
  final String label;
  final List<_ThumbAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Stack(
              children: [
                Image.network(
                  url,
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 140,
                    height: 140,
                    color: Colors.grey.shade100,
                    child: const Icon(Iconsax.image, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final a in actions)
                  IconButton(
                    tooltip: a.tooltip,
                    onPressed: a.onPressed,
                    icon: Icon(a.icon, size: 18, color: a.danger && a.onPressed != null ? Colors.redAccent : null),
                  ),
              ],
            )
          else
            const SizedBox(height: 48),
        ],
      ),
    );
  }
}

/// Grid of every image in the library. Pops the chosen file name.
class _LibraryPicker extends StatelessWidget {
  const _LibraryPicker({required this.filenames});
  final List<String> filenames;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text("Choose from library"),
      content: SizedBox(
        width: 640,
        height: 480,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: filenames.length,
          itemBuilder: (context, i) => InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.pop(context, filenames[i]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageFullUrl('/images/${filenames[i]}'),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade100,
                  child: const Icon(Iconsax.image, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
      ],
    );
  }
}
