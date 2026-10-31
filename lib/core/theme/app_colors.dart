import 'package:flutter/material.dart';

/// The store's brand palette (warsha_commerce), so the ERP looks like the
/// same company.
abstract final class AppColors {
  static const Color burgundy = Color(0xFF6D1A2E);
  static const Color deepWine = Color(0xFF4A0F1E);
  static const Color blush = Color(0xFFF7EBEC);
  static const Color ivory = Color(0xFFFFFAF6);
  static const Color champagne = Color(0xFFC9A66B);
  static const Color ink = Color(0xFF2B1A1E);
  static const Color muted = Color(0xFF8A737A);
  static const Color line = Color(0xFFEADDD9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;
}

/// Text / background pairs for status pills, banners and money in/out.
abstract final class AppStatusColors {
  static const Color warningText = Color(0xFF7A5A1C);
  static const Color warningBackground = Color(0xFFF3E5C8);

  static const Color successText = Color(0xFF2F6A44);
  static const Color successBackground = Color(0xFFDCEBE0);

  static const Color infoText = Color(0xFF2D5A7B);
  static const Color infoBackground = Color(0xFFDDE9F2);

  static const Color neutralText = Color(0xFF777777);
  static const Color neutralBackground = Color(0xFFEEEEEE);

  static const Color errorText = Color(0xFFB3261E);
  static const Color errorBackground = Color(0xFFFCE8E6);
}

/// Chart colors. [series] is a categorical order checked for colour-blind
/// separation and contrast on white; use it in this order, never cycled.
/// One-series charts use [single].
abstract final class AppChartColors {
  static const Color single = AppColors.burgundy;
  static const List<Color> series = [
    Color(0xFFB03A58),
    Color(0xFF0A84B0),
    Color(0xFFB98318),
    Color(0xFF7552B8),
    Color(0xFF2E8B57),
  ];
}
