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
  /// HYPER-VIBRANT, SUPER FAST, AND ABSOLUTE EDGE-TO-EDGE GROWING BORDERS
  Widget buildCreativeBackground({
    required Widget child, 
    bool isDark = false, 
    double? maxWidth, 
    bool useAIBorder = false, 
  }) {
    // 1. Quantum Mesh Layer (Always full screen)
    Widget background = _NeuralMeshBackground(
      isDark: isDark, 
      child: const SizedBox.expand()
    );

    // 2. Intelligence Content Layer
    Widget content = maxWidth != null 
      ? Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child))
      : child;

    if (useAIBorder) {
      // THE EDGE-TO-EDGE QUANTUM OVERLAY
      // Border and Background are decoupled from content to ensure the frame hugs the screen limits
      return Stack(
        fit: StackFit.expand,
        children: [
          background,
          content,
          const IgnorePointer(
            child: AISpectrumBorder(
              borderRadius: 0, // Frame-less edge synchronization
              strokeWidth: 5.0, 
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

  /// THE FUTURE GLASS CONTAINER: Enhanced with optional AI Glowing Border
  Widget buildGlowContainer({
    required Widget child,
    double borderRadius = 24,
    double borderThickness = 1.0,
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
        strokeWidth: 3.0,
        child: card,
      );
    }
    return card;
  }
}

/// Standalone AI Spectrum Border Utility
/// SUPER CREATIVE: ULTRA-FAST SYNC, KINETIC GROWTH, AND VIVID NEON GLOW
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
    // ROTATION: 0.4 seconds (Hyper-Drive Neural Sync)
    _rotationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..repeat();
    // PULSE: 0.6 seconds for aggressive "Growing" edge effect
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
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
    // KINETIC GROWTH: Border inflates dynamically off-canvas
    final expansion = pulse * 20.0; 
    final dynamicStroke = strokeWidth + (pulse * 15.0);
    final intensity = 0.5 + (pulse * 0.5);
    
    // Drawing area inflated beyond screen bounds for "frame-less" bleed
    final rect = Offset(-expansion / 2, -expansion / 2) & 
                 Size(size.width + expansion, size.height + expansion);
    
    final paint = Paint()
      ..strokeWidth = dynamicStroke
      ..style = PaintingStyle.stroke;

    // HYPER-VIBRANT QUANTUM PALETTE
    final colors = [
      const Color(0xFFFF0000).withOpacity(intensity), 
      const Color(0xFFFF7B00).withOpacity(intensity), 
      const Color(0xFFFFFF00).withOpacity(intensity), 
      const Color(0xFF00FF00).withOpacity(intensity), 
      const Color(0xFF00FFFF).withOpacity(intensity), 
      const Color(0xFF0044FF).withOpacity(intensity), 
      const Color(0xFF9100FF).withOpacity(intensity), 
      const Color(0xFFFF00FF).withOpacity(intensity), 
      const Color(0xFFFF0000).withOpacity(intensity), 
    ];

    final gradient = SweepGradient(
      colors: colors,
      transform: GradientRotation(rotation * 2 * math.pi),
    );

    paint.shader = gradient.createShader(rect);
    
    // LAYERED AURORA GLOW (5 Layers of Light Emission)
    for (int i = 1; i <= 5; i++) {
      final glowPaint = Paint()
        ..strokeWidth = dynamicStroke * (1.8 * i)
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (15.0 * i) * pulse + 8);
      glowPaint.shader = gradient.createShader(rect);
      
      final path = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius > 0 ? borderRadius + expansion : 0));
      canvas.drawRRect(path, glowPaint..color = glowPaint.color.withOpacity(0.2 / i));
    }

    // PRIMARY DYNAMIC BORDER
    final path = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius > 0 ? borderRadius + expansion : 0));
    canvas.drawRRect(path, paint);
    
    // QUANTUM SPARKLE EDGE (Thin high-frequency line)
    final sparkPaint = Paint()
      ..strokeWidth = 3.0
      ..color = Colors.white.withOpacity(0.7 * pulse)
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(path, sparkPaint);
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
            Container(color: widget.isDark ? const Color(0xFF010102) : const Color(0xFFF9FBFF)),
            
            CustomPaint(
              size: Size.infinite,
              painter: _NeuralGridPainter(widget.isDark, _controller.value),
            ),

            Positioned(
              top: -350 + (math.sin(_controller.value * 2 * math.pi) * 200),
              right: -250 + (math.cos(_controller.value * 2 * math.pi) * 150),
              child: _OrganicBlob(color: const Color(0xFFFF3D00).withOpacity(widget.isDark ? 0.35 : 0.18), size: 1000),
            ),
            Positioned(
              bottom: -400 + (math.cos(_controller.value * 2 * math.pi) * 250),
              left: -300 + (math.sin(_controller.value * 2 * math.pi) * 180),
              child: _OrganicBlob(color: const Color(0xFF2979FF).withOpacity(widget.isDark ? 0.32 : 0.15), size: 1100),
            ),

            ...List.generate(35, (index) {
              final rand = math.Random(index * 200);
              return Positioned(
                top: rand.nextDouble() * MediaQuery.of(context).size.height,
                left: rand.nextDouble() * MediaQuery.of(context).size.width,
                child: _TwinklingNode(progress: _controller.value, offset: rand.nextDouble()),
              );
            }),

            BackdropFilter(filter: ImageFilter.blur(sigmaX: 130, sigmaY: 120), child: widget.child),
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
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.08)
      ..strokeWidth = 2.0;

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

class _TwinklingNode extends StatelessWidget {
  final double progress;
  final double offset;
  const _TwinklingNode({required this.progress, required this.offset, super.key});

  @override
  Widget build(BuildContext context) {
    final val = (math.sin((progress + offset) * 30 * math.pi) + 1) / 2;
    return Opacity(
      opacity: val * 0.8,
      child: Container(
        width: 5, height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.white.withOpacity(1.0), blurRadius: 15)],
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
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
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
                const Color(0xFFFF3D00).withOpacity(0.3 + (pulse * 0.3)),
                const Color(0xFF2979FF).withOpacity(0.3),
                const Color(0xFF00E676).withOpacity(0.3 + (pulse * 0.3)),
                const Color(0xFFFF3D00).withOpacity(0.3 + (pulse * 0.3)),
              ],
              transform: GradientRotation(t * 2 * math.pi),
            ),
          ),
          child: Container(
            margin: EdgeInsets.all(widget.borderThickness),
            padding: widget.padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? (isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.75)),
              borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderThickness),
              border: Border.all(color: Colors.white.withOpacity(isDark ? 0.25 : 0.45)),
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
  static const Color primaryWarm = Color(0xFFFF3D00);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryWarm,
      scaffoldBackgroundColor: isDark ? const Color(0xFF010102) : const Color(0xFFF9FBFF),
      colorScheme: ColorScheme.fromSeed(seedColor: primaryWarm, brightness: brightness),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0x59FFFFFF) : const Color(0xFAFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 30, letterSpacing: 1.5, color: Colors.white),
      ),
      extensions: [
        GeminiThemeExtension(
          primaryGradient: LinearGradient(
            colors: isDark ? [primaryWarm, const Color(0xFFD50000)] : [primaryWarm, const Color(0xFFFFAB91)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }
}
