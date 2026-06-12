import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

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
            color: const Color(0xFFD84315).withOpacity(isDark ? 0.25 : 0.15),
            size: 500,
          ),
        ),
        Positioned(
          bottom: -200,
          left: -150,
          child: _BlurredBlob(
            color: const Color(0xFF3F51B5).withOpacity(isDark ? 0.2 : 0.1),
            size: 600,
          ),
        ),
        Positioned(
          top: 300,
          left: -50,
          child: _BlurredBlob(
            color: const Color(0xFF009688).withOpacity(isDark ? 0.15 : 0.05),
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

  /// THE "GROWING FRAME" FEATURE: Animated rotating gradient border with pulse
  Widget buildGlowContainer({
    required Widget child,
    double borderRadius = 24,
    double borderThickness = 2.5,
    Color? backgroundColor,
    EdgeInsets? padding,
  }) {
    return AnimatedGlowFrame(
      borderRadius: borderRadius,
      borderThickness: borderThickness,
      backgroundColor: backgroundColor,
      padding: padding,
      child: child,
    );
  }
}

class AnimatedGlowFrame extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderThickness;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const AnimatedGlowFrame({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.borderThickness,
    this.backgroundColor,
    this.padding,
  });

  @override
  State<AnimatedGlowFrame> createState() => _AnimatedGlowFrameState();
}

class _AnimatedGlowFrameState extends State<AnimatedGlowFrame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              center: Alignment.center,
              colors: const [
                Color(0xFFD84315), // Deep Orange
                Color(0xFF3F51B5), // Indigo
                Color(0xFF009688), // Teal
                Color(0xFFE91E63), // Pink
                Color(0xFFD84315),
              ],
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3F51B5).withOpacity(0.3),
                blurRadius: 15 + (math.sin(_controller.value * 2 * math.pi) * 8),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(widget.borderThickness),
            padding: widget.padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? Theme.of(context).cardTheme.color ?? Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(
                  widget.borderRadius - widget.borderThickness),
            ),
            child: widget.child,
          ),
        );
      },
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
    colors: [aiBlue, aiPurple, aiPink, Color(0xFF00D2FF)],
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
