import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class GeminiThemeExtension extends ThemeExtension<GeminiThemeExtension> {
  final LinearGradient? primaryGradient;
  final LinearGradient? glowingBorderGradient;
  final Color? accentGlow;

  const GeminiThemeExtension({
    this.primaryGradient,
    this.glowingBorderGradient,
    this.accentGlow,
  });

  @override
  GeminiThemeExtension copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? glowingBorderGradient,
    Color? accentGlow,
  }) {
    return GeminiThemeExtension(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      glowingBorderGradient: glowingBorderGradient ?? this.glowingBorderGradient,
      accentGlow: accentGlow ?? this.accentGlow,
    );
  }

  @override
  GeminiThemeExtension lerp(ThemeExtension<GeminiThemeExtension>? other, double t) {
    if (other is! GeminiThemeExtension) return this;
    return GeminiThemeExtension(
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t),
      glowingBorderGradient: LinearGradient.lerp(glowingBorderGradient, other.glowingBorderGradient, t),
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t),
    );
  }

  /// THE NEURAL HUB BACKGROUND: Main Screen Wrapper
  Widget buildCreativeBackground({
    required Widget child, 
    bool isDark = false, 
    double? maxWidth, 
    bool useAIBorder = false, 
  }) {
    Widget background = _NeuralMeshBackground(
      isDark: isDark, 
      child: const SizedBox.expand()
    );

    Widget content = maxWidth != null 
      ? Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child))
      : child;

    if (useAIBorder) {
      return Stack(
        fit: StackFit.expand,
        children: [
          background,
          content,
          const IgnorePointer(
            child: AISpectrumBorder(
              borderRadius: 0, 
              strokeWidth: 4.0, 
              isEdgeToEdge: true,
              child: SizedBox.expand(),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        content,
      ],
    );
  }

  /// THE FUTURE GLASS CONTAINER: High-Visibility Glassmorphism
  Widget buildGlowContainer({
    required Widget child,
    double borderRadius = 30,
    double borderThickness = 1.2, // Thinner for a sharper look
    Color? backgroundColor,
    EdgeInsets? padding,
    bool useAIBorder = false, 
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
        strokeWidth: 2.0,
        child: card,
      );
    }
    return card;
  }
}

class AISpectrumBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final bool isEdgeToEdge;

  const AISpectrumBorder({
    required this.child, 
    required this.borderRadius,
    this.strokeWidth = 2.5,
    this.isEdgeToEdge = false,
    super.key,
  });

  @override
  State<AISpectrumBorder> createState() => _AISpectrumBorderState();
}

class _AISpectrumBorderState extends State<AISpectrumBorder> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _SpectrumPainter(
            rotation: _rotationController.value,
            pulse: _pulseController.value,
            borderRadius: widget.borderRadius,
            strokeWidth: widget.strokeWidth,
          ),
          child: widget.isEdgeToEdge 
            ? widget.child 
            : ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: widget.child,
              ),
        );
      },
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final double borderRadius;
  final double strokeWidth;

  _SpectrumPainter({
    required this.rotation, 
    required this.pulse,
    required this.borderRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final growthFactor = pulse * 2.0; // Reduced growth
    final dynamicStroke = strokeWidth + (pulse * 0.5);
    final opacity = 0.6; // Subtle border
    
    final rect = Offset(-growthFactor / 2, -growthFactor / 2) & 
                 Size(size.width + growthFactor, size.height + growthFactor);
    
    final paint = Paint()
      ..strokeWidth = dynamicStroke
      ..style = PaintingStyle.stroke;

    // PROFESSIONAL DUAL-TONE (Primary & Secondary Only)
    final colors = [
      const Color(0xFFFF3D00).withOpacity(opacity), 
      const Color(0xFF2979FF).withOpacity(opacity), 
      const Color(0xFFFF3D00).withOpacity(opacity), 
    ];

    final gradient = SweepGradient(
      colors: colors,
      transform: GradientRotation(rotation * 2 * math.pi),
    );

    paint.shader = gradient.createShader(rect);
    
    final path = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius > 0 ? borderRadius + growthFactor : 0));
    
    // Subtle Outer Glow
    final glowPaint = Paint()
      ..strokeWidth = dynamicStroke + 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    glowPaint.shader = gradient.createShader(rect);
    
    canvas.drawRRect(path, glowPaint..color = glowPaint.color.withOpacity(0.2 * pulse));
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
            Container(color: widget.isDark ? const Color(0xFF08090A) : const Color(0xFFF8FAFC)),
            
            CustomPaint(
              size: Size.infinite,
              painter: _NeuralGridPainter(widget.isDark, _controller.value),
            ),

            Positioned(
              top: -150 + (math.sin(_controller.value * 2 * math.pi) * 80),
              right: -150 + (math.cos(_controller.value * 2 * math.pi) * 80),
              child: _OrganicBlob(color: const Color(0xFFFF3D00).withOpacity(widget.isDark ? 0.08 : 0.04), size: 700),
            ),
            Positioned(
              bottom: -200 + (math.cos(_controller.value * 2 * math.pi) * 120),
              left: -150 + (math.sin(_controller.value * 2 * math.pi) * 80),
              child: _OrganicBlob(color: const Color(0xFF2979FF).withOpacity(widget.isDark ? 0.08 : 0.04), size: 800),
            ),

            BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: widget.child),
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
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.02) // Extremely subtle grid
      ..strokeWidth = 0.5;

    const spacing = 100.0;
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
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
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
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            // ELIMINATED RAINBOW: Use soft primary-to-transparent sweep
            gradient: SweepGradient(
              center: Alignment.center,
              colors: [
                const Color(0xFFFF3D00).withOpacity(0.15),
                const Color(0xFF2979FF).withOpacity(0.15),
                const Color(0xFFFF3D00).withOpacity(0.15),
              ],
              transform: GradientRotation(t * 2 * math.pi),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.blueGrey).withOpacity(0.08),
                blurRadius: 25,
                spreadRadius: -10,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderThickness),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                margin: EdgeInsets.all(widget.borderThickness),
                padding: widget.padding ?? const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? (isDark ? const Color(0xF2121418) : const Color(0xF2FFFFFF)),
                  borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderThickness),
                  border: Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.3)),
                ),
                child: widget.child,
              ),
            ),
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
  static const Color primaryElectric = Color(0xFFFF3D00);
  static const Color secondaryElectric = Color(0xFF2979FF);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryElectric,
      scaffoldBackgroundColor: isDark ? const Color(0xFF08090A) : const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryElectric, 
        brightness: brightness,
        primary: primaryElectric,
        secondary: secondaryElectric,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: -1),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black, letterSpacing: 0.5),
        bodyMedium: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xF2121418) : const Color(0xF2FFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w900, 
          fontSize: 18, 
          letterSpacing: 3.0, 
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      extensions: [
        GeminiThemeExtension(
          primaryGradient: LinearGradient(
            colors: isDark ? [primaryElectric, const Color(0xFFC62828)] : [primaryElectric, const Color(0xFFFF7043)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          accentGlow: secondaryElectric,
        ),
      ],
    );
  }
}
