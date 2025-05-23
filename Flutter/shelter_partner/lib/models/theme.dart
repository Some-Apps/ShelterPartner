import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: const Color(0xFF36618E),
  primaryColorLight: const Color(0xFFBBDEFB),
  primaryColorDark: const Color(0xFF1976D2),
  canvasColor: const Color(0xFFF8F9FF),
  scaffoldBackgroundColor: const Color(0xFFF8F9FF),
  cardColor: const Color(0xFFF8F9FF),
  dividerColor: const Color(0x1F191C20),
  focusColor: const Color(0x1F000000),
  hoverColor: const Color(0x0A000000),
  highlightColor: const Color(0x66BCBCBC),
  splashColor: const Color(0x66C8C8C8),
  splashFactory: InkRipple.splashFactory,
  unselectedWidgetColor: const Color(0x8A000000),
  disabledColor: const Color(0x61000000),
  secondaryHeaderColor: const Color(0xFFE3F2FD),
  hintColor: const Color(0x99000000),
  visualDensity: VisualDensity.compact,
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  typography: Typography.material2021(),
  // Define your color scheme
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF36618E),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD1E4FF),
    onPrimaryContainer: Color(0xFF001D36),
    secondary: Color(0xFF535F70),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD7E3F7),
    onSecondaryContainer: Color(0xFF101C2B),
    tertiary: Color(0xFF6B5778),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFF2DAFF),
    onTertiaryContainer: Color(0xFF251431),
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF8F9FF),
    onSurface: Color(0xFF191C20),
    surfaceContainerHighest: Color(0xFFDEE3EB),
    onSurfaceVariant: Color(0xFF43474E),
    outline: Color(0xFF73777F),
    outlineVariant: Color(0xFFC3C7CF),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF2E3135),
    onInverseSurface: Color(0xFFEFF0F7),
    inversePrimary: Color(0xFFA0CAFD),
    surfaceTint: Color(0xFF36618E),
  ),
  // Define your text theme
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 96,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.5,
      color: Color(0xFF191C20),
    ),
    displayMedium: TextStyle(
      fontSize: 60,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
      color: Color(0xFF191C20),
    ),
    displaySmall: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w400,
      color: Color(0xFF191C20),
    ),
    headlineLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: Color(0xFF191C20),
    ),
    headlineMedium: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: Color(0xFF191C20),
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      color: Color(0xFF191C20),
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: Color(0xFF191C20),
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: Color(0xFF191C20),
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color(0xFF191C20),
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: Color(0xFF191C20),
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: Color(0xFF191C20),
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: Color(0xFF191C20),
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.25,
      color: Color(0xFF191C20),
    ),
    labelMedium: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.5,
      color: Color(0xFF191C20),
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.5,
      color: Color(0xFF191C20),
    ),
  ),
  // Define your icon theme
  iconTheme: const IconThemeData(
    color: Color(0xDD000000),
  ),
  primaryIconTheme: const IconThemeData(
    color: Colors.white,
  ),

  // Define your button theme
  buttonTheme: ButtonThemeData(
    height: 36,
    minWidth: 88,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2),
    ),
    buttonColor: const Color(0xFF36618E),
    alignedDropdown: false,
    layoutBehavior: ButtonBarLayoutBehavior.padded,
  ),
  // Additional theme customizations can be added here
  timePickerTheme: const TimePickerThemeData(
    hourMinuteTextStyle: TextStyle(fontSize: 36.0),
  ),
  dialogTheme: DialogThemeData(backgroundColor: const Color(0xFFF8F9FF)),
  tabBarTheme: TabBarThemeData(indicatorColor: Colors.white),
);

final ThemeData darkTheme = ThemeData(
  // Define your dark theme similarly
  brightness: Brightness.dark,
  timePickerTheme: const TimePickerThemeData(
    hourMinuteTextStyle: TextStyle(fontSize: 36.0),
  ),
  // Add your dark theme properties here
);
