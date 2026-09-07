import 'package:flutter/material.dart';

class CoolColors {
  static const skyTop = Color(0xFF7EC8E3);
  static const skyBottom = Color(0xFFFFF3C4);
  static const ink = Color(0xFF2D3142);
  static const inkSoft = Color(0xFF4F5D75);
  static const card = Color(0xFFFFFDF8);
  static const coral = Color(0xFFFF8A5B);
  static const sun = Color(0xFFFFD93D);
  static const leaf = Color(0xFF6BCB77);
  static const grape = Color(0xFFA78BFA);
  static const sky = Color(0xFF4CC9F0);
  static const rose = Color(0xFFFF6B6B);
}

class CoolTheme {
  static ThemeData data() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CoolColors.sky,
        brightness: Brightness.light,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: base.textTheme.apply(
        fontFamily: 'Fredoka',
        bodyColor: CoolColors.ink,
        displayColor: CoolColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: CoolColors.ink,
        centerTitle: false,
      ),
    );
  }

  static TextStyle kid({
    double size = 20,
    FontWeight weight = FontWeight.w600,
    Color color = CoolColors.ink,
    double height = 1.2,
  }) {
    return TextStyle(
      fontFamily: 'Fredoka',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }
}

Color parseHexColor(String hex) {
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}
