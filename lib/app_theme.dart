import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Brand Colors
  static const Color greenDeep = Color(0xFF0D3320);
  static const Color greenMid = Color(0xFF1A5C38);
  static const Color greenFresh = Color(0xFF2D8A55);
  static const Color greenLime = Color(0xFF6FD08C);
  static const Color greenGlow = Color(0xFF9EF5B4);
  static const Color earth = Color(0xFFC8A96E);
  static const Color earthLight = Color(0xFFF0DDB0);
  static const Color cream = Color(0xFFFAF6EE);
  static const Color charcoal = Color(0xFF1C1C1C);
  static const Color textMuted = Color(0xFF6B7C6E);
  static const Color accentOrange = Color(0xFFE85D26);
  static const Color dangerRed = Color(0xFFD94040);
  static const Color warningAmber = Color(0xFFF5A623);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: greenFresh,
          primary: greenDeep,
          secondary: greenFresh,
          tertiary: earth,
          surface: cream,
          background: cream,
          onPrimary: greenLime,
          onSecondary: Colors.white,
          onSurface: charcoal,
          error: dangerRed,
        ),
        scaffoldBackgroundColor: cream,
        fontFamily: 'DMSans',
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: greenDeep,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          titleTextStyle: TextStyle(
            fontFamily: 'DMSerifDisplay',
            fontSize: 20,
            color: greenDeep,
            fontWeight: FontWeight.w400,
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0x1A2D8A55), width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: greenDeep,
            foregroundColor: greenLime,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            textStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: greenMid,
            side: const BorderSide(color: Color(0x402D8A55), width: 1.5),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            textStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: greenFresh,
            textStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0x1A2D8A55), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0x1A2D8A55), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: greenFresh, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: dangerRed, width: 1.5),
          ),
          labelStyle: const TextStyle(color: textMuted, fontFamily: 'DMSans'),
          hintStyle: const TextStyle(color: Color(0x802D8A55), fontFamily: 'DMSans'),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0x0D2D8A55),
          selectedColor: greenFresh,
          labelStyle: const TextStyle(fontSize: 12, fontFamily: 'DMSans', fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          side: const BorderSide(color: Color(0x1A2D8A55)),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0x1A2D8A55),
          space: 1,
          thickness: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: greenDeep,
          unselectedItemColor: textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0x1A2D8A55),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: greenDeep);
            }
            return const IconThemeData(color: textMuted);
          }),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: greenDeep,
              );
            }
            return const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              color: textMuted,
            );
          }),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: greenFresh,
          brightness: Brightness.dark,
          primary: greenLime,
          secondary: greenFresh,
          surface: const Color(0xFF0D2018),
          background: const Color(0xFF080F0B),
          onPrimary: greenDeep,
          onSurface: cream,
          error: dangerRed,
        ),
        scaffoldBackgroundColor: const Color(0xFF080F0B),
        fontFamily: 'DMSans',
      );
}

// Text Styles
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: 40,
    fontWeight: FontWeight.w400,
    color: AppTheme.greenDeep,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: 32,
    fontWeight: FontWeight.w400,
    color: AppTheme.greenDeep,
    height: 1.15,
  );

  static const TextStyle headingLarge = TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: 26,
    fontWeight: FontWeight.w400,
    color: AppTheme.greenDeep,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTheme.greenDeep,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppTheme.charcoal,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppTheme.textMuted,
    height: 1.6,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppTheme.greenFresh,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppTheme.textMuted,
  );
}
