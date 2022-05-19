// ignore: avoid_classes_with_only_static_members
import 'package:flutter/material.dart';

class StreamAppColors {
  static const blue = Color(0xFF005fff);
  static const springGreen = Color(0xFF33e984);
  static const aquamarine = Color(0xFF76fff1);
  static const darkGrey = Color(0xFFb3b3b3);
  static const darkSlateGrey = Color(0xFF202426);
  static const snow = Color(0xFFfcfcfc);
}

class AppTheme {
  static final light = ThemeData.light().copyWith(
    colorScheme: const ColorScheme.light(
      secondary: StreamAppColors.aquamarine,
      primary: StreamAppColors.blue,
    ),
    appBarTheme:
        ThemeData.light().appBarTheme.copyWith(color: StreamAppColors.blue),
    disabledColor: Colors.grey.shade400,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static final dark = ThemeData.dark().copyWith(
    colorScheme: const ColorScheme.dark(
      secondary: StreamAppColors.springGreen,
      primary: StreamAppColors.aquamarine,
    ),
    appBarTheme:
        ThemeData.dark().appBarTheme.copyWith(color: StreamAppColors.blue),
    disabledColor: Colors.grey.shade400,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
