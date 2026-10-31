import 'package:flutter/widgets.dart';

/// Window size classes. Layouts switch on these, never on raw widths.
///
/// - compact (< 600): phones. Bottom navigation, cards instead of tables.
/// - medium (600–1023): tablets, small windows. Navigation rail.
/// - expanded (≥ 1024): desktop / web. Full sidebar, tables, side panels.
abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 1024;
  static const double wide = 1440;

  /// Widest a reading column (forms, details) should get.
  static const double formMaxWidth = 960;
  static const double contentMaxWidth = 1440;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isCompact => screenWidth < Breakpoints.medium;
  bool get isMedium => screenWidth >= Breakpoints.medium && screenWidth < Breakpoints.expanded;
  bool get isExpanded => screenWidth >= Breakpoints.expanded;

  /// Page padding that grows with the window.
  double get pagePadding => isCompact ? 16 : (isExpanded ? 32 : 24);
}
