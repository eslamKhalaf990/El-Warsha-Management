import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/services/products_service.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/utils/image_helper.dart';
import 'package:warsha_app/view_models/user_v_m.dart';

/// A picked library image: [filename] to assign, [url] is the full image URL
class LibraryImage {
  final String filename;
  final String url;
  LibraryImage(this.filename, this.url);
}

/// Shows all images in the shared library and returns the one the user picks
Future<LibraryImage?> showImageLibraryDialog(BuildContext context, {String? currentImage}) {
  return showDialog<LibraryImage>(
    context: context,
    builder: (_) => _ImageLibraryDialog(currentImage: currentImage),
  );
}

class _ImageLibraryDialog extends StatefulWidget {
  const _ImageLibraryDialog({this.currentImage});
  final String? currentImage;

  @override
  State<_ImageLibraryDialog> createState() => _ImageLibraryDialogState();
}

class _ImageLibraryDialogState extends State<_ImageLibraryDialog> {
  List<LibraryImage> _images = [];
  bool _isLoading = true;
  String? _error;
  String _search = "";
  String? _selected;

  @override
  void initState() {
    super.initState();
    // Preselect the product's current image ("/images/abc.jpg" -> "abc.jpg")
    final current = widget.currentImage;
    if (current != null && current.startsWith("/images/")) {
      _selected = current.substring("/images/".length);
    }
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final response = await context
          .read<ProductService>()
          .getLibraryImages(context.read<UserViewModel>().token);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _images = data
            .map((e) => LibraryImage(e['filename'], ImageHelper.fullUrl(e['url'])))
            .toList();
      } else {
        _error = "Failed to load images (${response.statusCode})";
      }
    } catch (e) {
      _error = "Failed to load images";
      debugPrint("Error loading library images: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _images
        .where((img) => img.filename.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: Constants.BORDER_RADIUS_20),
      child: SizedBox(
        width: 900,
        height: 650,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const DefaultText(txt: "Choose product image", size: 18),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.close_circle),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Iconsax.search_normal, size: 18),
                  hintText: "Search by file name",
                  border: OutlineInputBorder(borderRadius: Constants.BORDER_RADIUS_10),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 15),
              Expanded(child: _buildGrid(filtered)),
              const SizedBox(height: 15),
              Row(
                children: [
                  DefaultText(txt: "${_images.length} images"),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _selected == null
                        ? null
                        : () {
                            final picked = _images.firstWhere(
                              (img) => img.filename == _selected,
                              orElse: () => LibraryImage(_selected!, ImageHelper.fullUrl("/images/$_selected")),
                            );
                            Navigator.pop(context, picked);
                          },
                    child: const Text("Use this image"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<LibraryImage> images) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: DefaultText(txt: _error!));
    }
    if (images.isEmpty) {
      return const Center(child: DefaultText(txt: "No images found"));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final img = images[index];
        final isSelected = img.filename == _selected;
        return InkWell(
          borderRadius: Constants.BORDER_RADIUS_15,
          onTap: () => setState(() => _selected = img.filename),
          onDoubleTap: () => Navigator.pop(context, img),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: Constants.BORDER_RADIUS_15,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade200,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    img.url,
                    fit: BoxFit.cover,
                    cacheWidth: 320, // decode small thumbnails, not full-size photos
                    errorBuilder: (context, _, __) =>
                        const Icon(Iconsax.image, color: Colors.grey),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
