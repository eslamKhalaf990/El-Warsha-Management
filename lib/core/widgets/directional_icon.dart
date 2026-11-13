import 'package:flutter/widgets.dart';

/// An arrow-like icon that points the other way in right-to-left (Arabic)
/// layouts, e.g. "back" points right in Arabic.
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon(this.icon, {super.key, this.size, this.color});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.flip(flipX: rtl, child: Icon(icon, size: size, color: color));
  }
}
