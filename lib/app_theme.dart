import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class GeminiThemeExtension extends ThemeExtension<GeminiThemeExtension> {
  final LinearGradient? primaryGradient;
  final LinearGradient? glowingBorderGradient;

  const GeminiThemeExtension({
    this.primaryGradient,
    this.glowingBorderGradient,
  });

  @override
  GeminiThemeExtension copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? glowingBorderGradient,
  }) {
    return GeminiThemeExtension(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      glowingBorderGradient:
          glowingBorderGradient ?? this.glowingBorderGradient,
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
    );
  }

  /// THE NEURAL HUB BACKGROUND: Main Screen Wrapper
  Widget buildCreativeBackground({
    required Widget child, 
    bool isDark = false, 
    double maxWidth = 600,
    bool useAIBorder = false, // Selective: only for specific "portal" screens
  }) {
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

    if (useAIBorder) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AISpectrumBorder(
            borderRadius: 32,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      );
    }

    return _NeuralMeshBackground(isDark: isDark, child: content);
  }

  /// THE FUTURE GLASS CONTAINER: Enhanced with optional AI Glowing Border
  Widget buildGlowContainer({
    required Widget child,
    double borderRadius = 24,
    double borderThickness = 1.0,
    Color? backgroundColor,
    EdgeInsets? padding,
    bool useAIBorder = false, // NEW: Apply to important cards/stats
  }) {
    Widget card = _NeuralGlassCard(
      borderRadius: borderRadius,
      borderThickness: borderThickness,
      backgroundColor: backgroundColor,
      padding: padding,
      child: child,
    );

    if (useAIBorder) {
      return AISpectrumBorder(
        borderRadius: borderRadius,
        child: card,
      );
    }
    return card;
  }
}

/// Standalone AI Spectrum Border Utility
class AISpectrumBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  const AISpectrumBorder({
    required this.child, 
    required this.borderRadius,
    this.strokeWidth = 2.5,
    super.key,
  });

  @override
  State<AISpectrumBorder> createState() => _AISpectrumBorderState();
}

class _AISpectrumBorderState extends State<AISpectrumBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
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
        return CustomPaint(
          painter: _SpectrumPainter(
            animation: _controller,
            borderRadius: widget.borderRadius,
            strokeWidth: widget.strokeWidth,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final Animation<double> animation;
  final double borderRadius;
  final double strokeWidth;

  _SpectrumPainter({
    required this.animation, 
    required this.borderRadius,
    required this.strokeWidth,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final colors = [
      const Color(0xFFFF3D00), // Red
      const Color(0xFFFFB300), // Orange
      const Color(0xFF00E676), // Green
      const Color(0xFF00B0FF), // Blue
      const Color(0xFFD500F9), // Purple
      const Color(0xFFFF3D00), // Back to Red
    ];

    final gradient = SweepGradient(
      colors: colors,
      transform: GradientRotation(animation.value * 2 * math.pi),
    );

    paint.shader = gradient.createShader(rect);
    
    // Outer Glow Effect
    final glowPaint = Paint()
      ..strokeWidth = strokeWidth * 2.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    glowPaint.shader = gradient.createShader(rect);

    final path = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    
    canvas.drawRRect(path, glowPaint..color = glowPaint.color.withOpacity(0.3));
    canvas.drawRRect(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NeuralMeshBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;
  const _NeuralMeshBackground({required this.child, required this.isDark, super.key});

  @override
  State<_NeuralMeshBackground> createState() => _NeuralMeshBackgroundState();
}

class _NeuralMeshBackgroundState extends State<_NeuralMeshBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
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
        return Stack(
          children: [
            Container(color: widget.isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA)),
            
            CustomPaint(
              size: Size.infinite,
              painter: _NeuralGridPainter(widget.isDark, _controller.value),
            ),

            Positioned(
              top: -150 + (math.sin(_controller.value * 2 * math.pi) * 120),
              right: -100 + (math.cos(_controller.value * 2 * math.pi) * 100),
              child: _OrganicBlob(color: const Color(0xFFD84315).withOpacity(widget.isDark ? 0.18 : 0.1), size: 700),
            ),
            Positioned(
              bottom: -200 + (math.cos(_controller.value * 2 * math.pi) * 180),
              left: -150 + (math.sin(_controller.value * 2 * math.pi) * 110),
              child: _OrganicBlob(color: const Color(0xFF3F51B5).withOpacity(widget.isDark ? 0.15 : 0.07), size: 800),
            ),

            ...List.generate(10, (index) {
              final rand = math.Random(index * 99);
              return Positioned(
                top: rand.nextDouble() * MediaQuery.of(context).size.height,
                left: rand.nextDouble() * MediaQuery.of(context).size.width,
                child: _TwinklingNode(progress: _controller.value, offset: rand.nextDouble()),
              );
            }),

            BackdropFilter(filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90), child: widget.child),
          ],
        );
      },
    );
  }
}

class _NeuralGridPainter extends CustomPainter {
  final bool isDark;
  final double progress;
  _NeuralGridPainter(this.isDark, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.02)
      ..strokeWidth = 0.8;

    const spacing = 50.0;
    final offset = progress * spacing;

    for (double i = -spacing; i < size.width + spacing; i += spacing) {
      canvas.drawLine(Offset(i + offset, 0), Offset(i + offset, size.height), paint);
    }
    for (double i = -spacing; i < size.height + spacing; i += spacing) {
      canvas.drawLine(Offset(0, i + offset), Offset(size.width, i + offset), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TwinklingNode extends StatelessWidget {
  final double progress;
  final double offset;
  const _TwinklingNode({required this.progress, required this.offset, super.key});

  @override
  Widget build(BuildContext context) {
    final val = (math.sin((progress + offset) * 10 * math.pi) + 1) / 2;
    return Opacity(
      opacity: val * 0.3,
      child: Container(
        width: 3, height: 3,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 4)],
        ),
      ),
    );
  }
}

class _NeuralGlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderThickness;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const _NeuralGlassCard({
    required this.child,
    required this.borderRadius,
    required this.borderThickness,
    this.backgroundColor,
    this.padding,
  });

  @override
  State<_NeuralGlassCard> createState() => _NeuralGlassCardState();
}

class _NeuralGlassCardState extends State<_NeuralGlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final pulse = (math.sin(t * 2 * math.pi) + 1) / 2;
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              center: Alignment.center,
              colors: [
                const Color(0xFFD84315).withOpacity(0.1 + (pulse * 0.4)),
                const Color(0xFF3F51B5).withOpacity(0.1),
                const Color(0xFF009688).withOpacity(0.1 + (pulse * 0.4)),
                const Color(0xFFD84315).withOpacity(0.1 + (pulse * 0.4)),
              ],
              transform: GradientRotation(t * 2 * math.pi),
            ),
          ),
          child: Container(
            margin: EdgeInsets.all(widget.borderThickness),
            padding: widget.padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7)),
              borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderThickness),
              border: Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.2)),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _OrganicBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _OrganicBlob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}

class AppTheme {
  static const Color primaryWarm = Color(0xFFD84315);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryWarm,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA),
      colorScheme: ColorScheme.fromSeed(seedColor: primaryWarm, brightness: brightness),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0x1AFFFFFF) : const Color(0xB3FFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5, color: Colors.white),
      ),
      extensions: [
        GeminiThemeExtension(
          primaryGradient: LinearGradient(
            colors: isDark ? [primaryWarm, const Color(0xFFBF360C)] : [primaryWarm, const Color(0xFFFFAB91)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }
}
