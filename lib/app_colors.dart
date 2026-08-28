import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0A2647);
  static const Color primaryDark = Color(0xFF07111F);
  static const Color primaryDeep = Color(0xFF030813);
  static const Color secondary = Color(0xFFFF7B54);
  static const Color accent = Color(0xFF38EBD0);
  static const Color accentLight = Color(0xFFA9FFF2);
  static const Color surface = Color(0xFF07111F);
  static const Color surfaceSoft = Color(0xFF0D1D31);
  static const Color cardBg = Color(0xFF10233A);
  static const Color lightSurface = Color(0xFFF6FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF07111F);
  static const Color textMid = Color(0xFF587086);
  static const Color textMuted = Color(0xFF9DB0C1);
  static const Color textLight = Color(0xFFF7FCFF);
  static const Color borderColor = Color(0x2638EBD0);
  static const Color xpGold = Color(0xFFFFC857);
  static const Color success = Color(0xFF57E389);
  static const Color danger = Color(0xFFFF5A78);

  static const Color tileLight1 = Color(0xFFE8FBF7);
  static const Color tileLight2 = Color(0xFFFFEEE8);
  static const Color tileLight3 = Color(0xFFE9F0FF);

  static const Color gemOcean1 = Color(0xFF0A2647);
  static const Color gemOcean2 = Color(0xFF126E82);
  static const Color gemOcean3 = Color(0xFF1B4D5F);
  static const Color gemGreen1 = gemOcean1;
  static const Color gemGreen2 = gemOcean2;
  static const Color gemGreen3 = gemOcean3;
  static const Color mapBg = Color(0xFF10233A);

  static const Gradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDeep, primary, Color(0xFF126E82), secondary],
    stops: [0.0, 0.46, 0.78, 1.0],
  );

  static const Gradient sunriseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, Color(0xFFFFB067)],
  );

  static const Gradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF78FFF0)],
  );
}
