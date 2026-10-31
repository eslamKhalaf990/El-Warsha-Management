import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart' show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/core/theme/app_theme.dart';

/// A network image with the brand's placeholder and error look.
///
/// Photos are decoded at the size they're shown, not their full camera size:
/// a 3000 px photo held at full size takes ~25 MB, so a grid of them pushed
/// each other out of Flutter's image cache and went blank (re-downloaded)
/// whenever they scrolled back into view.
///
/// On the web the bytes are fetched and decoded by Flutter (HttpGet). The
/// default (HtmlImage) wraps a browser <img> as a lazy GPU texture that paints
/// black for a moment each time a photo scrolls back on screen.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(this.url, {super.key, this.width, this.height, this.radius = AppRadius.input, this.fit = BoxFit.cover});

  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  /// Decode width in physical pixels for a [w] × [h] box. The longer side,
  /// with headroom so [BoxFit.cover] can crop a wide or tall photo without
  /// upscaling it.
  static int? _decodeWidth(BuildContext context, double w, double h) {
    final side = math.max(w.isFinite ? w : 0, h.isFinite ? h : 0);
    if (side <= 0) return null;
    return (side * MediaQuery.devicePixelRatioOf(context) * 1.5).round();
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.blush,
      alignment: Alignment.center,
      child: const Icon(Iconsax.gallery_copy, color: AppColors.muted),
    );

    Widget image(int? decodeWidth) => CachedNetworkImage(
          imageUrl: url!,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: decodeWidth,
          imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, __) => placeholder,
          errorWidget: (_, __, ___) => placeholder,
        );

    final Widget child;
    if (url == null || url!.isEmpty) {
      child = placeholder;
    } else if (width != null && width!.isFinite && height != null) {
      // Fixed size (thumbnails): no LayoutBuilder, so it also works where
      // the parent measures intrinsic sizes.
      child = image(_decodeWidth(context, width!, height!));
    } else {
      child = LayoutBuilder(
        builder: (context, c) => image(_decodeWidth(context, width ?? c.maxWidth, height ?? c.maxHeight)),
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}
