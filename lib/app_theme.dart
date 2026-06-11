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
      glowingBorderGradient:
          glowingBorderGradient ?? this.glowingBorderGradient,
      glowingShadows: glowingShadows ?? this.glowingShadows,
    );
  }

  @override
  GeminiThemeExtension lerp(
      ThemeExtension<GeminiThemeExtension>? other, double t) {
    if (other is! GeminiThemeExtension) return this;
    return GeminiThemeExtension(
      primaryGradient:
          LinearGradient.lerp(primaryGradient, other.primaryGradient, t),
      glowingBorderGradient: LinearGradient.lerp(
          glowingBorderGradient, other.glowingBorderGradient, t),
      glowingShadows: BoxShadow.lerpList(glowingShadows, other.glowingShadows, t),
    );
  }

  Widget buildCreativeBackground({required Widget child, bool isDark = false}) {
    return Stack(
      children: [
        Container(
            color: isDark ? const Color(0xFF0F0C0B) : const Color(0xFFFAF9F6)),
        Positioned(
          top: -150,
          right: -100,
          child: _BlurredBlob(
            color: const Color(0xFFD84315)
                .withOpacity(isDark ? 0.25 : 0.15),
            size: 500,
          ),
        ),
        Positioned(
          bottom: -200,
          left: -150,
          child: _BlurredBlob(
            color: const Color(0xFF3F51B5)
                .withOpacity(isDark ? 0.2 : 0.1),
            size: 600,
          ),
        ),
        Positioned(
          top: 300,
          left: -50,
          child: _BlurredBlob(
            color: const Color(0xFF009688)
                .withOpacity(isDark ? 0.15 : 0.05),
            size: 300,
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
          child: child,
        ),
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
          color: backgroundColor ??
              (backgroundColor == null
                  ? Colors.white.withOpacity(0.8)
                  : backgroundColor),
          borderRadius: BorderRadius.circular(borderRadius - borderThickness),
        ),
        child: child,
      ),
    );
  }
}

class _BlurredBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurredBlob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Color(0xCCFFFFFF),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24))),
        ),
        extensions: [
          const GeminiThemeExtension(
            primaryGradient:
                LinearGradient(colors: [primaryWarm, Color(0xFFFF7043)]),
            glowingBorderGradient: aiGlowGradient,
            glowingShadows: [
              BoxShadow(
                  color: Color(0x204285F4), blurRadius: 20, spreadRadius: 1),
            ],
          ),
        ],
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: primaryWarm,
        colorScheme: ColorScheme.fromSeed(
            seedColor: primaryWarm, brightness: Brightness.dark),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Color(0xB3242424),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24))),
        ),
        extensions: [
          const GeminiThemeExtension(
            primaryGradient:
                LinearGradient(colors: [primaryWarm, Color(0xFFFF7043)]),
            glowingBorderGradient: aiGlowGradient,
            glowingShadows: [
              BoxShadow(
                  color: Color(0x40D84315), blurRadius: 25, spreadRadius: 2),
            ],
          ),
        ],
      );
}
