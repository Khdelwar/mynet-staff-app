import 'package:flutter/material.dart';

/// The ERP's look (mynet-erp `resources/css/app.css`, `components/ui/*`):
/// MyNet green accent, slate greys, white cards with a thin border, 6px
/// buttons, the charcoal sidebar colours, Inter + Noto Sans Bengali.
/// Every colour the app draws comes from here, so one change keeps the
/// app and the web the same.
abstract final class ErpColors {
  // Accent = Tailwind emerald (ERP default theme colour).
  static const accent50 = Color(0xFFECFDF5);
  static const accent100 = Color(0xFFD1FAE5);
  static const accent200 = Color(0xFFA7F3D0);
  static const accent300 = Color(0xFF6EE7B7);
  static const accent400 = Color(0xFF34D399);
  static const accent600 = Color(0xFF059669);
  static const accent700 = Color(0xFF047857);
  static const accent800 = Color(0xFF065F46);
  static const accent900 = Color(0xFF064E3B);

  // Slate (page, borders, text).
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  // ERP sidebar (charcoal), used for the dark theme.
  static const sidebarBg = Color(0xFF1C1E22);
  static const sidebarSurface = Color(0xFF292D32);
  static const sidebarBorder = Color(0xFF303338);
  static const sidebarText = Color(0xFFE8EAED);
  static const sidebarMuted = Color(0xFF9299A3);
  static const darkPage = Color(0xFF17191D);

  // Status (x-ui.badge / x-ui.alert).
  static const rose700 = Color(0xFFBE123C);
  static const rose600 = Color(0xFFE11D48);
}

const _latin = 'Inter';
const _bangla = ['NotoSansBengali'];

/// ERP menu sections (`components/page-hero.blade.php`): each has a soft
/// tint, a ring and a strong colour. Feature tiles use their section's tone.
enum ErpSection {
  overview(
    Color(0xFFA7F3D0),
    Color(0xFFECFDF5),
    Color(0xFF6EE7B7),
    Color(0xFF047857),
  ),
  billing(
    Color(0xFFA7F3D0),
    Color(0xFFECFDF5),
    Color(0xFF6EE7B7),
    Color(0xFF047857),
  ),
  approvals(
    Color(0xFFFDE68A),
    Color(0xFFFFFBEB),
    Color(0xFFFCD34D),
    Color(0xFF92400E),
  ),
  customers(
    Color(0xFFDDD6FE),
    Color(0xFFF5F3FF),
    Color(0xFFC4B5FD),
    Color(0xFF6D28D9),
  ),
  resellers(
    Color(0xFFFDE68A),
    Color(0xFFFFFBEB),
    Color(0xFFFCD34D),
    Color(0xFF92400E),
  ),
  accounts(
    Color(0xFF99F6E4),
    Color(0xFFF0FDFA),
    Color(0xFF5EEAD4),
    Color(0xFF0F766E),
  ),
  hr(
    Color(0xFFFECDD3),
    Color(0xFFFFF1F2),
    Color(0xFFFDA4AF),
    Color(0xFFBE123C),
  ),
  tickets(
    Color(0xFFFED7AA),
    Color(0xFFFFF7ED),
    Color(0xFFFDBA74),
    Color(0xFFC2410C),
  ),
  network(
    Color(0xFFC7D2FE),
    Color(0xFFEEF2FF),
    Color(0xFFA5B4FC),
    Color(0xFF4338CA),
  ),
  sms(
    Color(0xFFBAE6FD),
    Color(0xFFF0F9FF),
    Color(0xFF7DD3FC),
    Color(0xFF0369A1),
  ),
  inventory(
    Color(0xFFD9F99D),
    Color(0xFFF7FEE7),
    Color(0xFFBEF264),
    Color(0xFF3F6212),
  ),
  system(
    Color(0xFFE2E8F0),
    Color(0xFFF8FAFC),
    Color(0xFFCBD5E1),
    Color(0xFF475569),
  );

  const ErpSection(this.tint, this.tintEnd, this.ring, this.strong);

  /// Gradient start (Tailwind -200), gradient end (-50), border (-300),
  /// icon and label colour (-700/-800).
  final Color tint;
  final Color tintEnd;
  final Color ring;
  final Color strong;

  /// Colours for the current theme: dark mode keeps the hue on charcoal.
  ({Color bg, Color bgEnd, Color border, Color fg, Color chip}) of(
    BuildContext context,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (!dark) {
      return (
        bg: tint,
        bgEnd: tintEnd,
        border: ring,
        fg: strong,
        chip: Colors.white,
      );
    }
    return (
      bg: Color.alphaBlend(strong.withValues(alpha: 0.35), ErpColors.sidebarBg),
      bgEnd: ErpColors.sidebarBg,
      border: strong.withValues(alpha: 0.6),
      fg: ring,
      chip: ErpColors.sidebarSurface,
    );
  }
}

ThemeData erpTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  final page = dark ? ErpColors.darkPage : ErpColors.slate50;
  final surface = dark ? ErpColors.sidebarBg : Colors.white;
  final border = dark ? ErpColors.sidebarBorder : ErpColors.slate200;
  final inputBorder = dark ? ErpColors.sidebarBorder : ErpColors.slate300;
  final text = dark ? ErpColors.sidebarText : ErpColors.slate800;
  final strong = dark ? Colors.white : ErpColors.slate900;
  final muted = dark ? ErpColors.sidebarMuted : ErpColors.slate500;
  final primary = dark ? ErpColors.accent400 : ErpColors.accent700;
  final onPrimary = dark ? ErpColors.accent900 : Colors.white;

  final scheme =
      ColorScheme.fromSeed(
        seedColor: ErpColors.accent700,
        brightness: brightness,
      ).copyWith(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: dark ? ErpColors.accent900 : ErpColors.accent100,
        onPrimaryContainer: dark ? ErpColors.accent200 : ErpColors.accent900,
        secondary: dark ? ErpColors.slate300 : ErpColors.slate600,
        surface: surface,
        onSurface: text,
        onSurfaceVariant: muted,
        surfaceContainerLowest: page,
        surfaceContainerLow: dark ? ErpColors.sidebarBg : ErpColors.slate50,
        surfaceContainer: dark ? ErpColors.sidebarSurface : ErpColors.slate100,
        surfaceContainerHigh: dark
            ? ErpColors.sidebarSurface
            : ErpColors.slate100,
        surfaceContainerHighest: dark
            ? ErpColors.sidebarBorder
            : ErpColors.slate100,
        outline: inputBorder,
        outlineVariant: border,
        error: dark ? const Color(0xFFFDA4AF) : ErpColors.rose700,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: _latin,
    fontFamilyFallback: _bangla,
  );

  TextStyle? t(TextStyle? s, {FontWeight? w, Color? c, double? size}) =>
      s?.copyWith(
        fontFamily: _latin,
        fontFamilyFallback: _bangla,
        fontWeight: w,
        color: c,
        fontSize: size,
        letterSpacing: 0,
      );

  final tt = base.textTheme;
  final textTheme = tt.copyWith(
    headlineMedium: t(
      tt.headlineMedium,
      w: FontWeight.w700,
      c: strong,
      size: 26,
    ),
    headlineSmall: t(tt.headlineSmall, w: FontWeight.w600, c: strong, size: 22),
    titleLarge: t(tt.titleLarge, w: FontWeight.w600, c: strong, size: 18),
    titleMedium: t(tt.titleMedium, w: FontWeight.w600, c: strong, size: 16),
    titleSmall: t(tt.titleSmall, w: FontWeight.w600, c: text, size: 14),
    bodyLarge: t(tt.bodyLarge, c: text, size: 15),
    bodyMedium: t(tt.bodyMedium, c: text, size: 14),
    bodySmall: t(tt.bodySmall, c: muted, size: 12.5),
    labelLarge: t(tt.labelLarge, w: FontWeight.w500, size: 14),
    labelMedium: t(tt.labelMedium, w: FontWeight.w500, size: 12.5),
    labelSmall: t(tt.labelSmall, w: FontWeight.w600, size: 11.5),
  );

  // ERP: rounded-md (6px) buttons and inputs, rounded-lg (8px) cards.
  const r6 = BorderRadius.all(Radius.circular(6));
  const r8 = BorderRadius.all(Radius.circular(8));
  OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: r6,
    borderSide: BorderSide(color: c, width: w),
  );
  final buttonText = textTheme.labelLarge?.copyWith(
    fontWeight: FontWeight.w600,
  );

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: page,
    dividerColor: border,
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: strong,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      titleTextStyle: textTheme.titleMedium?.copyWith(fontSize: 17),
      iconTheme: IconThemeData(color: dark ? text : ErpColors.slate600),
      shape: Border(bottom: BorderSide(color: border)),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: r8,
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: muted,
      titleTextStyle: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: strong,
      ),
      subtitleTextStyle: textTheme.bodySmall,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: primary,
        foregroundColor: onPrimary,
        disabledBackgroundColor: primary.withValues(alpha: 0.45),
        disabledForegroundColor: onPrimary.withValues(alpha: 0.85),
        shape: const RoundedRectangleBorder(borderRadius: r6),
        textStyle: buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48),
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: onPrimary,
        shape: const RoundedRectangleBorder(borderRadius: r6),
        textStyle: buttonText,
      ),
    ),
    // ERP "secondary" button: white, slate-300 border, slate-700 text.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: surface,
        foregroundColor: dark ? text : ErpColors.slate700,
        side: BorderSide(color: inputBorder),
        shape: const RoundedRectangleBorder(borderRadius: r6),
        textStyle: buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        shape: const RoundedRectangleBorder(borderRadius: r6),
        textStyle: buttonText,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: field(inputBorder),
      enabledBorder: field(inputBorder),
      disabledBorder: field(border),
      focusedBorder: field(dark ? ErpColors.accent400 : ErpColors.accent600, 2),
      errorBorder: field(scheme.error),
      focusedErrorBorder: field(scheme.error, 2),
      labelStyle: textTheme.bodyMedium?.copyWith(color: muted),
      floatingLabelStyle: textTheme.bodyMedium?.copyWith(
        color: dark ? ErpColors.accent300 : ErpColors.accent700,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: ErpColors.slate400),
      prefixIconColor: muted,
      suffixIconColor: muted,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: dark ? ErpColors.accent900 : ErpColors.accent50,
      side: BorderSide(color: border),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      labelStyle: textTheme.labelMedium?.copyWith(color: text),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: dark ? ErpColors.accent200 : ErpColors.accent800,
      ),
      checkmarkColor: dark ? ErpColors.accent200 : ErpColors.accent700,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: surface,
        selectedBackgroundColor: dark
            ? ErpColors.accent900
            : ErpColors.accent50,
        selectedForegroundColor: dark
            ? ErpColors.accent200
            : ErpColors.accent800,
        side: BorderSide(color: inputBorder),
        shape: const RoundedRectangleBorder(borderRadius: r6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: dark ? ErpColors.accent900 : ErpColors.accent100,
      indicatorShape: const RoundedRectangleBorder(borderRadius: r8),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? (dark ? ErpColors.accent200 : ErpColors.accent800)
              : muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelMedium?.copyWith(
          color: states.contains(WidgetState.selected)
              ? (dark ? ErpColors.accent200 : ErpColors.accent800)
              : muted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: muted,
      indicatorColor: primary,
      dividerColor: border,
      labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: textTheme.labelLarge,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: r8),
      titleTextStyle: textTheme.titleMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: r8,
        side: BorderSide(color: border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ErpColors.slate900,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      actionTextColor: ErpColors.accent300,
      shape: const RoundedRectangleBorder(borderRadius: r8),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: border,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      side: BorderSide(color: inputBorder, width: 1.5),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? primary : null,
      ),
    ),
  );
}
