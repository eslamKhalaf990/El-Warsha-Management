import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

export 'app_colors.dart';
export 'app_radius.dart';
export 'app_spacing.dart';
export 'breakpoints.dart';

/// The ERP theme: the store's identity (burgundy on ivory, Cairo, pill
/// buttons, 12px line-bordered cards) plus what an admin app needs on top
/// (tables, navigation, dialogs, menus).
abstract final class AppTheme {
  static ThemeData light() {
    final textTheme = _textTheme();

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.burgundy,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.blush,
      onPrimaryContainer: AppColors.deepWine,
      secondary: AppColors.champagne,
      onSecondary: AppColors.ink,
      secondaryContainer: AppColors.blush,
      onSecondaryContainer: AppColors.deepWine,
      tertiary: AppColors.deepWine,
      onTertiary: AppColors.white,
      error: AppStatusColors.errorText,
      onError: AppColors.white,
      errorContainer: AppStatusColors.errorBackground,
      onErrorContainer: AppStatusColors.errorText,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: AppColors.ivory,
      surfaceContainer: AppColors.blush,
      surfaceContainerHigh: AppColors.blush,
      surfaceContainerHighest: AppColors.blush,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
    );

    const inputBorder = OutlineInputBorder(
      borderRadius: AppRadius.inputBorderRadius,
      borderSide: BorderSide(color: AppColors.line),
    );

    const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s12);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.ivory,
      canvasColor: AppColors.ivory,
      primaryColor: AppColors.burgundy,
      dividerColor: AppColors.line,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.burgundy,
        selectionColor: AppColors.burgundy.withValues(alpha: 0.18),
        selectionHandleColor: AppColors.burgundy,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.deepWine),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorderRadius,
          side: BorderSide(color: AppColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.burgundy,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.muted,
          minimumSize: const Size(88, 48),
          shape: const StadiumBorder(),
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.burgundy,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.muted,
          elevation: 0,
          shadowColor: AppColors.transparent,
          minimumSize: const Size(88, 48),
          shape: const StadiumBorder(),
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.burgundy,
          disabledForegroundColor: AppColors.muted,
          side: const BorderSide(color: AppColors.burgundy),
          minimumSize: const Size(88, 48),
          shape: const StadiumBorder(),
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.burgundy,
          disabledForegroundColor: AppColors.muted,
          minimumSize: const Size(64, 44),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.ink, minimumSize: const Size(40, 40)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.burgundy,
        foregroundColor: AppColors.white,
        elevation: 2,
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: 14),
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        labelStyle: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(color: AppColors.burgundy, fontWeight: FontWeight.w600),
        helperStyle: textTheme.labelSmall,
        errorMaxLines: 3,
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused) ? AppColors.burgundy : AppColors.muted,
        ),
        suffixIconColor: AppColors.muted,
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(borderSide: BorderSide(color: AppColors.line.withValues(alpha: 0.5))),
        focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: AppColors.burgundy, width: 1.5)),
        errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: AppStatusColors.errorText)),
        focusedErrorBorder:
            inputBorder.copyWith(borderSide: const BorderSide(color: AppStatusColors.errorText, width: 1.5)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyLarge,
        menuStyle: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.white),
          surfaceTintColor: WidgetStatePropertyAll(AppColors.transparent),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: AppRadius.cardBorderRadius)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        elevation: 4,
        textStyle: textTheme.bodyLarge,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorderRadius,
          side: BorderSide(color: AppColors.line),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.burgundy,
        disabledColor: AppColors.line,
        checkmarkColor: AppColors.white,
        labelStyle: textTheme.bodySmall,
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(color: AppColors.white),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
        side: const BorderSide(color: AppColors.line),
        elevation: 0,
        pressElevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.ink,
          selectedBackgroundColor: AppColors.burgundy,
          selectedForegroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.line),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.muted,
        selectedColor: AppColors.burgundy,
        selectedTileColor: AppColors.blush,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.labelSmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.inputBorderRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.deepWine,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: AppColors.white),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorderRadius),
        behavior: SnackBarBehavior.floating,
        width: 480,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(color: AppColors.ink, borderRadius: AppRadius.smallBorderRadius),
        textStyle: textTheme.bodySmall?.copyWith(color: AppColors.white),
        waitDuration: const Duration(milliseconds: 400),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.burgundy,
        linearTrackColor: AppColors.blush,
        circularTrackColor: AppColors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        indicatorColor: AppColors.blush,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected) ? AppColors.burgundy : AppColors.muted,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.burgundy : AppColors.muted,
            size: 22,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.blush,
        selectedIconTheme: const IconThemeData(color: AppColors.burgundy),
        unselectedIconTheme: const IconThemeData(color: AppColors.muted),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(color: AppColors.burgundy, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: textTheme.labelSmall,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: const WidgetStatePropertyAll(AppColors.ivory),
        headingTextStyle: textTheme.labelLarge?.copyWith(color: AppColors.muted),
        dataTextStyle: textTheme.bodySmall,
        dataRowColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? AppColors.blush.withValues(alpha: 0.5) : AppColors.white,
        ),
        dividerThickness: 1,
        horizontalMargin: AppSpacing.s16,
        columnSpacing: AppSpacing.s24,
        headingRowHeight: 48,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.burgundy : AppColors.white,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        side: const BorderSide(color: AppColors.line, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.burgundy : AppColors.muted,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.white : AppColors.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.burgundy : AppColors.line,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.transparent),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        rangeSelectionBackgroundColor: AppColors.blush,
      ),
    );
  }

  static TextTheme _textTheme() {
    TextStyle cairo(double size, FontWeight weight, [Color color = AppColors.ink, double? height]) =>
        GoogleFonts.cairo(fontSize: size, fontWeight: weight, color: color, height: height);
    return TextTheme(
      displayLarge: cairo(38, FontWeight.w700, AppColors.ink, 1.15),
      headlineMedium: cairo(26, FontWeight.w700, AppColors.deepWine),
      headlineSmall: cairo(22, FontWeight.w700, AppColors.deepWine),
      titleLarge: cairo(20, FontWeight.w600),
      titleMedium: cairo(16, FontWeight.w700),
      titleSmall: cairo(16, FontWeight.w600),
      bodyLarge: cairo(15, FontWeight.w400),
      bodyMedium: cairo(14, FontWeight.w400),
      bodySmall: cairo(13, FontWeight.w400),
      labelLarge: cairo(14, FontWeight.w600),
      labelMedium: cairo(13, FontWeight.w600),
      labelSmall: cairo(12, FontWeight.w400, AppColors.muted),
    );
  }
}
