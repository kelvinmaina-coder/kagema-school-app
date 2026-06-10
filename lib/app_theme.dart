import 'package:flutter/material.dart';
import 'dart:ui';

class GeminiThemeExtension extends ThemeExtension<GeminiThemeExtension> {
  final LinearGradient? primaryGradient;
  final LinearGradient? glowingBorderGradient;
  final List<BoxShadow>? glowingShadows;

  const GeminiThemeExtension({
    this.primaryGradient, 
    this.glowingBorderGradient,
    this.glowingShadows,
  });

  @override
  GeminiThemeExtension copyWith({
    LinearGradient? primaryGradient, 
    LinearGradient? glowingBorderGradient,
    List<BoxShadow>? glowingShadows,
  }) {
    return GeminiThemeExtension(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      glowingBorderGradient: glowingBorderGradient ?? this.glowingBorderGradient,
      glowingShadows: glowingShadows ?? this.glowingShadows,
    );
  }

  @override
  GeminiThemeExtension lerp(ThemeExtension<GeminiThemeExtension>? other, double t) {
    if (other is! GeminiThemeExtension) return this;
    return GeminiThemeExtension(
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t),
      glowingBorderGradient: LinearGradient.lerp(glowingBorderGradient, other.glowingBorderGradient, t),
      glowingShadows: other.glowingShadows,
    );
  }

  Widget buildCreativeBackground({required Widget child, bool isDark = false}) {
    return Stack(
      children: [
        Container(color: isDark ? const Color(0xFF0F0C0B) : const Color(0xFFFAF9F6)),
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: const Color(0xFF4285F4).withOpacity(isDark ? 0.15 : 0.1)
            ),
          ),
        ),
        BackdropFilter(filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70), child: child),
      ],
    );
  }

  Widget buildGlowContainer({
    required Widget child,
    double borderRadius = 24,
    double borderThickness = 2,
    Color? backgroundColor,
    EdgeInsets? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: glowingBorderGradient,
        boxShadow: glowingShadows,
      ),
      child: Container(
        margin: EdgeInsets.all(borderThickness),
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? (backgroundColor == null ? Colors.white.withOpacity(0.8) : backgroundColor),
          borderRadius: BorderRadius.circular(borderRadius - borderThickness),
        ),
        child: child,
      ),
    );
  }
}

class AppTheme {
  static const Color primaryWarm = Color(0xFFD84315);
  static const Color aiBlue = Color(0xFF4285F4);
  static const Color aiPurple = Color(0xFF9B72CB);
  static const Color aiPink = Color(0xFFD96570);

  static const LinearGradient aiGlowGradient = LinearGradient(
    colors: [aiBlue, aiPurple, aiPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryWarm,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryWarm),
    extensions: [
      const GeminiThemeExtension(
        primaryGradient: LinearGradient(colors: [primaryWarm, Color(0xFFFF7043)]),
        glowingBorderGradient: aiGlowGradient,
        glowingShadows: [
          BoxShadow(color: Color(0x304285F4), blurRadius: 10, spreadRadius: 1),
          BoxShadow(color: Color(0x309B72CB), blurRadius: 20, spreadRadius: -2),
        ],
      ),
    ],
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryWarm,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryWarm, brightness: Brightness.dark),
    extensions: [
      const GeminiThemeExtension(
        primaryGradient: LinearGradient(colors: [primaryWarm, Color(0xFFFF7043)]),
        glowingBorderGradient: aiGlowGradient,
        glowingShadows: [
          BoxShadow(color: Color(0x604285F4), blurRadius: 15, spreadRadius: 2),
          BoxShadow(color: Color(0x609B72CB), blurRadius: 30, spreadRadius: -2),
        ],
      ),
    ],
  );
}
