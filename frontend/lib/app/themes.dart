import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle getInterTextStyle({
  required bool isDark,
  double fontSize = 16.0,
  FontWeight fontWeight = FontWeight.bold,
  Color? color,
}) {
  final defaultColor = isDark ? Colors.white : Colors.black;

  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? defaultColor,
  );
}

TextStyle getDeliusTextStyle({
  required bool isDark,
  double fontSize = 16.0,
  FontWeight fontWeight = FontWeight.bold,
  Color? color,
}) {
  final defaultColor = isDark ? Colors.white : Colors.black;

  return GoogleFonts.delius(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? defaultColor,
  );
}

// ==================== Light Theme ====================
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  colorScheme: ColorScheme.light(
    primary: Colors.blue,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
    secondary: Colors.blueAccent,
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    color: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(
      color: Colors.black,
    ), // Contrast with white background
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: ThemeData.light().textTheme.copyWith(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
    bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.blue,
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.blue,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.blue,
      side: const BorderSide(color: Colors.blue),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.grey),
    hintStyle: const TextStyle(color: Colors.grey),
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    margin: const EdgeInsets.all(8),
  ),
  dividerTheme: const DividerThemeData(
    color: Colors.grey,
    thickness: 1,
    space: 16,
  ),
);

// ==================== Dark Theme ====================
final ThemeData darkTheme = ThemeData(
  scaffoldBackgroundColor: Colors.black87,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: Colors.blue,
    surface: Colors.black,
    brightness: Brightness.dark,
  ),
  primarySwatch: Colors.blueGrey,
  primaryColor: Colors.blue,
  appBarTheme: AppBarTheme(
    color: Colors.grey[900],
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: ThemeData.dark().textTheme.copyWith(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
    bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.blueGrey,
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueGrey,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.blueGrey,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.blueGrey,
      side: const BorderSide(color: Colors.blueGrey),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.grey),
    hintStyle: const TextStyle(color: Colors.grey),
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    margin: const EdgeInsets.all(8),
  ),
  dividerTheme: const DividerThemeData(
    color: Colors.grey,
    thickness: 1,
    space: 16,
  ),
);
