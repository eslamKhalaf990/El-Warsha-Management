import 'package:flutter/material.dart';

enum _Variant { headline, title, titleSmall, price, body, bodySmall, label, caption }

/// Text in one of the theme's styles. Screens use this instead of raw
/// [Text] + inline [TextStyle], so type stays consistent.
class AppText extends StatelessWidget {
  const AppText.headline(this.text, {super.key, this.color, this.weight, this.maxLines, this.align})
      : _variant = _Variant.headline;
  const AppText.title(this.text, {super.key, this.color, this.weight, this.maxLines, this.align})
      : _variant = _Variant.title;
  const AppText.titleSmall(this.text, {super.key, this.color, this.weight, this.maxLines, this.align})
      : _variant = _Variant.titleSmall;
  const AppText.price(this.text, {super.key, this.color, this.weight, this.maxLines, this.align})
      : _variant = _Variant.price;
  const AppText.body(this.text, {super.key, this.color, this.weight, this.maxLines, this.align})
      : _variant = _Variant.body;
  const AppText.bodySmall(this.text, {super.key, this.color, this.weight, this.maxLines, this.align})
      : _variant = _Variant.bodySmall;
  const AppText.label(this.text, {super.key, this.color, this.weight, this.maxLines, this.align})
      : _variant = _Variant.label;
  const AppText.caption(this.text, {super.key, this.color, this.weight, this.maxLines, this.align})
      : _variant = _Variant.caption;

  final String text;
  final _Variant _variant;
  final Color? color;
  final FontWeight? weight;
  final int? maxLines;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final base = switch (_variant) {
      _Variant.headline => t.headlineMedium,
      _Variant.title => t.titleLarge,
      _Variant.titleSmall => t.titleSmall,
      _Variant.price => t.titleMedium,
      _Variant.body => t.bodyLarge,
      _Variant.bodySmall => t.bodySmall,
      _Variant.label => t.labelLarge,
      _Variant.caption => t.labelSmall,
    };
    return Text(
      text,
      style: base?.copyWith(color: color, fontWeight: weight),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      textAlign: align,
    );
  }
}
