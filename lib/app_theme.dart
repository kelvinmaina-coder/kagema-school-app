import 'package:flutter/material.dart';
import 'dart:ui';

/// Google Gemini-inspired theme extension for AI-centric visual effects.
class GeminiThemeExtension extends ThemeExtension<GeminiThemeExtension> {
  final LinearGradient? primaryGradient;
  final LinearGradient? surfaceGradient;
  final LinearGradient? glowingBorderGradient;
  final LinearGradient? meshGradient;
  final Color? glowColor;
  final Color? hoverGlow;
  final Color? surfaceSubtle;
  final List<BoxShadow>? cardShadows;
  final List<BoxShadow>? glowingShadows;

  const GeminiThemeExtension({
    this.primaryGradient,
    this.surfaceGradient,
    this.glowingBorderGradient,
    this.meshGradient,
    this.glowColor,
    this.hoverGlow,
    this.surfaceSubtle,
    this.cardShadows,
    this.glowingShadows,
  });

  @override
  GeminiThemeExtension copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? surfaceGradient,
    LinearGradient? glowingBorderGradient,
    LinearGradient? meshGradient,
    Color? glowColor,
    Color? hoverGlow,
    Color? surfaceSubtle,
    List<BoxShadow>? cardShadows,
    List<BoxShadow>? glowingShadows,
  }) {
    return GeminiThemeExtension(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      surfaceGradient: surfaceGradient ?? this.surfaceGradient,
      glowingBorderGradient: glowingBorderGradient ?? this.glowingBorderGradient,
      meshGradient: meshGradient ?? this.meshGradient,
      glowColor: glowColor ?? this.glowColor,
      hoverGlow: hoverGlow ?? this.hoverGlow,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      cardShadows: cardShadows ?? this.cardShadows,
      glowingShadows: glowingShadows ?? this.glowingShadows,
    );
  }

  @override
  GeminiThemeExtension lerp(ThemeExtension<GeminiThemeExtension>? other, double t) {
    if (other is! GeminiThemeExtension) return this;
    return GeminiThemeExtension(
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t),
      surfaceGradient: LinearGradient.lerp(surfaceGradient, other.surfaceGradient, t),
      glowingBorderGradient: LinearGradient.lerp(glowingBorderGradient, other.glowingBorderGradient, t),
      meshGradient: LinearGradient.lerp(meshGradient, other.meshGradient, t),
      glowColor: Color.lerp(glowColor, other.glowColor, t),
      hoverGlow: Color.lerp(hoverGlow, other.hoverGlow, t),
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t),
      cardShadows: other.cardShadows,
      glowingShadows: other.glowingShadows,
    );
  }

  /// A creative background wrapper that adds dynamic gradients and depth
  Widget buildCreativeBackground({required Widget child, bool isDark = false}) {
    return Stack(
      children: [
        // Base Background
        Container(color: isDark ? const Color(0xFF0F0C0B) : const Color(0xFFFAF9F6)),
        
        // Animated-like Mesh Gradients (Static for now but visually rich)
        Positioned(
          top: -100,
          right: -100,
          child: _BlurredCircle(
            color: const Color(0xFF4285F4).withOpacity(isDark ? 0.15 : 0.1),
            size: 400,
          ),
        ),
        Positioned(
          bottom: -150,
          left: -100,
          child: _BlurredCircle(
            color: const Color(0xFF9B72CB).withOpacity(isDark ? 0.2 : 0.15),
            size: 500,
          ),
        ),
        Positioned(
          top: 200,
          left: -50,
          child: _BlurredCircle(
            color: const Color(0xFFD96570).withOpacity(isDark ? 0.1 : 0.05),
            size: 300,
          ),
        ),

        // Content
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
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
          color: backgroundColor ?? (backgroundColor == null ? Colors.white.withOpacity(0.8) : backgroundColor),
          borderRadius: BorderRadius.circular(borderRadius - borderThickness),
        ),
        child: child,
      ),
    );
  }
}

class _BlurredCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _BlurredCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class AppTheme {
  static const Color primaryWarm = Color(0xFFD84315); // Deep Orange
  static const Color aiBlue = Color(0xFF4285F4);
  static const Color aiPurple = Color(0xFF9B72CB);
  static const Color aiPink = Color(0xFFD96570);

  static const LinearGradient aiGlowGradient = LinearGradient(
    colors: [aiBlue, aiPurple, aiPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryWarm,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryWarm,
        primary: primaryWarm,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.transparent, // Let the custom background shine
      
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: aiPurple, width: 2)),
      ),

      extensions: [
        const GeminiThemeExtension(
          primaryGradient: LinearGradient(colors: [primaryWarm, Color(0xFFFF7043)]),
          glowingBorderGradient: aiGlowGradient,
          meshGradient: LinearGradient(
            colors: [Color(0xFFFFF8F1), Color(0xFFF0E4FF), Color(0xFFE3F2FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          glowingShadows: [
            BoxShadow(color: Color(0x304285F4), blurRadius: 10, spreadRadius: 1),
            BoxShadow(color: Color(0x309B72CB), blurRadius: 20, spreadRadius: -2),
          ],
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryWarm,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: primaryWarm,
        surface: const Color(0xFF241F1C),
      ),
      scaffoldBackgroundColor: Colors.transparent,

      cardTheme: CardThemeData(
        color: const Color(0xFF2D2622).withOpacity(0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

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
}
