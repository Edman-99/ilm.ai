import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ai_stock_analyzer/l10n/app_strings.dart';

/// Переключаемая тема: light / dark.
class AppColors {
  const AppColors._({
    required this.bg,
    required this.surface,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.green,
    required this.red,
    required this.accent,
    required this.yellow,
    required this.gold,
    required this.cardHover,
    required this.cardActive,
    required this.isDark,
  });

  static const light = AppColors._(
    bg: Color(0xFFF7F7F8),
    surface: Colors.white,
    card: Colors.white,
    border: Color(0xFFE5E5E5),
    textPrimary: Color(0xFF0A0A0A),
    textSecondary: Color(0xFF737373),
    green: Color(0xFF16A34A),
    red: Color(0xFFDC2626),
    accent: Color(0xFF0A0A0A),
    yellow: Color(0xFFD97706),
    gold: Color(0xFFEEB501),
    cardHover: Color(0xFFF5F5F5),
    cardActive: Color(0xFFF0F0F0),
    isDark: false,
  );

  static const dark = AppColors._(
    bg: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF0A0A0A),
    border: Color(0xFF333333),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF999999),
    green: Color(0xFF22C55E),
    red: Color(0xFFEF4444),
    accent: Color(0xFFFFFFFF),
    yellow: Color(0xFFFBBF24),
    gold: Color(0xFFF3CC50),
    cardHover: Color(0xFF141414),
    cardActive: Color(0xFF1A1A1A),
    isDark: true,
  );

  final Color bg;
  final Color surface;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color green;
  final Color red;
  final Color accent;
  final Color yellow;
  final Color gold;
  final Color cardHover;
  final Color cardActive;
  final bool isDark;

  Color scoreColor(int score) {
    if (score >= 65) return green;
    if (score >= 45) return yellow;
    return red;
  }
}

class ThemeNotifier extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;
  AppColors get colors => _isDark ? AppColors.dark : AppColors.light;

  String _locale = 'en';
  String get locale => _locale;
  AppStrings get strings => _locale == 'ru' ? AppStrings.ru : AppStrings.en;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void toggleLocale() {
    _locale = _locale == 'ru' ? 'en' : 'ru';
    notifyListeners();
  }

  ThemeData get themeData {
    final c = colors;
    final base = _isDark ? ThemeData.dark() : ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      colorScheme: (_isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: c.accent,
        surface: c.surface,
        onSurface: c.textPrimary,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: c.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: c.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: c.textPrimary),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        bodySmall: textTheme.bodySmall?.copyWith(color: c.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(color: c.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.isDark ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerColor: c.border,
    );
  }
}

/// Layout constants.
class AppLayout {
  AppLayout._();

  // Breakpoints
  static const double breakpointWide = 960;
  static const double breakpointTablet = 640;

  // Border radius
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;

  // Spacing
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceM = 12;
  static const double spaceL = 16;
  static const double spaceXL = 24;
  static const double spaceXXL = 32;

  // Max widths
  static const double maxWidthNarrow = 520;
  static const double maxWidthMedium = 680;
  static const double maxWidthWide = 1140;
}

/// Доступ к цветам и строкам через InheritedWidget.
class AppThemeScope extends InheritedWidget {
  const AppThemeScope({
    required this.colors,
    required this.onToggle,
    required this.strings,
    required this.locale,
    required this.onToggleLocale,
    required super.child,
    super.key,
  });

  final AppColors colors;
  final VoidCallback onToggle;
  final AppStrings strings;
  final String locale;
  final VoidCallback onToggleLocale;

  static AppThemeScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppThemeScope>()!;
  }

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) =>
      colors.isDark != oldWidget.colors.isDark ||
      locale != oldWidget.locale;
}
