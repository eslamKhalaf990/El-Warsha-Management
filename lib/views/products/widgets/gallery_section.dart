import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/product_image.dart';
import 'package:warsha_app/view_models/product_gallery_v_m.dart';

/// The extra images shown after the cover in the store, on the edit page.
class GallerySection extends StatelessWidget {
  const GallerySection({super.key});

  Future<void> _upload(BuildContext context) async {
    final vm = context.read<ProductGalleryVM>();
    final files = await pickImages();
    if (files.isEmpty) return;
    final ok = await vm.upload([for (final f in files) (bytes: f.bytes, name: f.name)]);
    if (context.mounted) reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: '${Fmt.count(files.length, 'image')} added.');
  }

  Future<void> _fromLibrary(BuildContext context) async {
    final vm = context.read<ProductGalleryVM>();
    if (!await vm.loadLibrary() || !context.mounted) {
      if (context.mounted) showError(context, vm.errorMessage!);
      return;
    }
    final filename = await showDialog<String>(
      context: context,
      builder: (_) => _LibraryPicker(filenames: vm.library ?? const []),
    );
    if (filename == null) return;
    final ok = await vm.addFromLibrary(filename);
    if (context.mounted) reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: 'Image added.');
  }

  Future<void> _remove(BuildContext context, ProductImage image) async {
    final vm = context.read<ProductGalleryVM>();
    final ok = await vm.remove(image);
    if (context.mounted && !ok) showError(context, vm.errorMessage!);
  }

  Future<void> _move(BuildContext context, int index, int by) async {
    final vm = context.read<ProductGalleryVM>();
    final ok = await vm.move(index, by);
    if (context.mounted && !ok) showError(context, vm.errorMessage!);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductGalleryVM>();
    final images = vm.images;

    return FormSection(
      title: 'Gallery',
      subtitle: 'Shown after the cover, in this order.',
      icon: Iconsax.gallery_copy,
      trailing: MenuAnchor(
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(Iconsax.document_upload_copy, size: 18),
            onPressed: () => _upload(context),
            child: const Text('Upload images'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Iconsax.gallery_copy, size: 18),
            onPressed: () => _fromLibrary(context),
            child: const Text('From library'),
          ),
        ],
        builder: (context, menu, _) => AppButton.secondary(
          label: 'Add',
          icon: Iconsax.add_copy,
          compact: true,
          onPressed: vm.isBusy ? null : () => menu.isOpen ? menu.close() : menu.open(),
        ),
      ),
      children: [
        if (vm.isBusy) const LinearProgressIndicator(minHeight: 2),
        if (vm.loadFailed)
          InlineBanner(message: vm.errorMessage!, tone: Tone.error, actionLabel: 'Retry', onAction: vm.fetch)
        else if (vm.hasLoaded && images.isEmpty)
          const AppText.bodySmall('No extra images. The store shows the cover only.', color: AppColors.muted)
        else
          Wrap(
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s12,
            children: [
              for (var i = 0; i < images.length; i++)
                _Thumb(
                  url: images[i].fullUrl,
                  position: i + 1,
                  onEarlier: vm.isBusy || i == 0 ? null : () => _move(context, i, -1),
                  onLater: vm.isBusy || i == images.length - 1 ? null : () => _move(context, i, 1),
                  onRemove: vm.isBusy ? null : () => _remove(context, images[i]),
                ),
            ],
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.position, this.onEarlier, this.onLater, this.onRemove});

  final String url;
  final int position;
  final VoidCallback? onEarlier;
  final VoidCallback? onLater;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    IconButton action(IconData icon, String tip, VoidCallback? onTap, {Color? color}) => IconButton(
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          icon: Icon(icon, color: color),
          onPressed: onTap,
        );
    return SizedBox(
      width: 112,
      child: Column(
        children: [
          Stack(
            children: [
              AppNetworkImage(url, width: 112, height: 112),
              PositionedDirectional(top: 6, start: 6, child: StatusPill(label: '$position', tone: Tone.brand)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              action(Iconsax.arrow_left_2_copy, 'Move earlier', onEarlier),
              action(Iconsax.trash_copy, 'Remove', onRemove, color: AppStatusColors.errorText),
              action(Iconsax.arrow_right_3_copy, 'Move later', onLater),
            ],
          ),
        ],
      ),
    );
  }
}

class _LibraryPicker extends StatelessWidget {
  const _LibraryPicker({required this.filenames});

  final List<String> filenames;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Choose from library',
      icon: Iconsax.gallery_copy,
      maxWidth: 640,
      content: filenames.isEmpty
          ? const AppText.body('The library is empty. Upload images instead.', color: AppColors.muted)
          : SizedBox(
              width: 640,
              height: 420,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 120,
                  crossAxisSpacing: AppSpacing.s8,
                  mainAxisSpacing: AppSpacing.s8,
                ),
                itemCount: filenames.length,
                itemBuilder: (context, i) => InkWell(
                  borderRadius: AppRadius.inputBorderRadius,
                  onTap: () => Navigator.pop(context, filenames[i]),
                  child: AppNetworkImage(resolveImageUrl('/images/${filenames[i]}')),
                ),
              ),
            ),
      actions: [AppButton.text(label: 'Cancel', onPressed: () => Navigator.pop(context))],
    );
  }
}
