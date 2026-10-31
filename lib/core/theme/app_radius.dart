import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double small = 6.0;
  static const double input = 8.0;
  static const double card = 12.0;
  static const double pill = 99.0;

  static const BorderRadius smallBorderRadius = BorderRadius.all(Radius.circular(small));
  static const BorderRadius inputBorderRadius = BorderRadius.all(Radius.circular(input));
  static const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius pillBorderRadius = BorderRadius.all(Radius.circular(pill));
}
