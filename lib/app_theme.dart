import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  KAGEMA SCHOOL — APP THEME
//  Features:
//    • NeuralMesh animated background (shared with login screen DNA)
//    • AISpectrumBorder — sweeping dual-tone animated border
//    • NeuralGlassCard  — glassmorphism card, role-colour tinted
//    • RoleAuraLayer    — full-screen breathing radial glow
//    • ParticleLayer    — constellation particles (same engine as login)
//    • TimeAwareGreeter — static helper used across all dashboards
//    • AppTheme         — light + dark ThemeData with GeminiThemeExtension
//    • _DT              — dark-mode token helper (same as login screen)
// ═══════════════════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────────────────
// 1.  COLOUR PALETTE  (single source of truth for the whole app)
// ───────────────────────────────────────────────────────────────────────────
class KagemaColors {
  KagemaColors._();

  // Brand
  static const Color electric  = Color(0xFFFF3D00); // primary orange-red
  static const Color azure     = Color(0xFF2979FF); // secondary blue
  static const Color emerald   = Color(0xFF10B981); // success / secure
  static const Color amber     = Color(0xFFF59E0B); // accountant / warning
  static const Color violet    = Color(0xFF8B5CF6); // secretary
  static const Color sky       = Color(0xFF0EA5E9); // staff
  static const Color rose      = Color(0xFFEF4444); // parent / danger
  static const Color jade      = Color(0xFF10B981); // teacher

  // Dark-mode surfaces
  static const Color darkBase    = Color(0xFF08090A);
  static const Color darkSurface = Color(0xFF121418);
  static const Color darkCard    = Color(0xFF1E293B);
  static const Color darkBorder  = Color(0xFF334155);

  // Light-mode surfaces
  static const Color lightBase    = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFF0F4F8);
  static const Color lightCard    = Colors.white;
  static const Color lightBorder  = Color(0xFFE8EDF2);
}

// ───────────────────────────────────────────────────────────────────────────
// 2.  DARK-MODE TOKEN HELPER  (identical API to login screen _DT)
//     Import this in every dashboard so colours are always consistent.
// ───────────────────────────────────────────────────────────────────────────
class DT {
  final bool dark;
  const DT(this.dark);

  Color get pageBg       => dark ? KagemaColors.darkBase    : KagemaColors.lightSurface;
  Color get surfaceBg    => dark ? KagemaColors.darkSurface : KagemaColors.lightBase;
  Color get cardBg       => dark ? KagemaColors.darkCard    : KagemaColors.lightCard;
  Color get inputBg      => dark ? KagemaColors.darkCard    : const Color(0xFFF8FAFC);
  Color get inputFocusBg => dark ? const Color(0xFF243347)  : const Color(0xFFF8FAFC);
  Color get textPrimary  => dark ? const Color(0xFFF1F5F9)  : const Color(0xFF1E293B);
  Color get textSecondary=> dark ? const Color(0xFFCBD5E1)  : const Color(0xFF475569);
  Color get textMuted    => dark ? const Color(0xFF64748B)  : const Color(0xFF94A3B8);
  Color get hint         => dark ? const Color(0xFF475569)  : const Color(0xFFCDD5DE);
  Color get iconInactive => dark ? const Color(0xFF475569)  : const Color(0xFFB0BFCF);
  Color get cardBorder   => dark ? KagemaColors.darkBorder  : KagemaColors.lightBorder;
  Color get divider      => dark ? const Color(0xFF1E293B)  : const Color(0xFFE8EDF2);
  Color get footerPillBg => dark ? KagemaColors.darkCard    : KagemaColors.lightCard;
  Color get footerBorder => dark ? KagemaColors.darkBorder  : KagemaColors.lightBorder;
  Color get footerText   => dark ? const Color(0xFF94A3B8)  : const Color(0xFF64748B);
  Color get sectionLabel => dark ? const Color(0xFFF1F5F9)  : const Color(0xFF1E293B);
  Color get shimmerBase  => dark ? const Color(0xFF1E293B)  : const Color(0xFFE2E8F0);
  Color get shimmerHigh  => dark ? const Color(0xFF334155)  : const Color(0xFFF8FAFC);

  /// Role-aware breathing aura tint — use as a RadialGradient stop
  Color aura(Color roleColor) =>
      roleColor.withValues(alpha: dark ? 0.09 : 0.05);

  /// Role-aware selected card background
  Color roleCardBg(Color roleColor) =>
      roleColor.withValues(alpha: dark ? 0.12 : 0.06);

  /// Overlay scrim for modals / bottom sheets
  Color get scrim => dark
      ? Colors.black.withValues(alpha: 0.72)
      : Colors.black.withValues(alpha: 0.38);

  /// Convenience — build from context
  static DT of(BuildContext context) =>
      DT(Theme.of(context).brightness == Brightness.dark);
}

// ───────────────────────────────────────────────────────────────────────────
// 3.  TIME-AWARE GREETER  (shared with login screen)
//     Use TimeGreeter.now to get greeting data anywhere in the app.
// ───────────────────────────────────────────────────────────────────────────
class TimeGreeter {
  final String prefix;    // "Good Morning,"
  final String emoji;     // "🌅"
  final String label;     // "morning"
  final String tailline;  // "Have a productive morning!"

  const TimeGreeter._({
    required this.prefix,
    required this.emoji,
    required this.label,
    required this.tailline,
  });

  static TimeGreeter get now {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) {
      return const TimeGreeter._(
        prefix: 'Good Morning,', emoji: '🌅', label: 'morning',
        tailline: 'Have a great morning ahead.',
      );
    } else if (h >= 12 && h < 17) {
      return const TimeGreeter._(
        prefix: 'Good Afternoon,', emoji: '☀️', label: 'afternoon',
        tailline: 'Hope your afternoon is productive.',
      );
    } else if (h >= 17 && h < 21) {
      return const TimeGreeter._(
        prefix: 'Good Evening,', emoji: '🌆', label: 'evening',
        tailline: 'Wrapping up a great day?',
      );
    } else {
      return const TimeGreeter._(
        prefix: 'Good Night,', emoji: '🌙', label: 'night',
        tailline: 'Working late — we\'ve got you covered.',
      );
    }
  }

  /// Full greeting string e.g. "Good Morning, Admin! 🌅"
  String greet(String roleName) => '$prefix $roleName! $emoji';
}

// ───────────────────────────────────────────────────────────────────────────
// 4.  PARTICLE ENGINE  (same model as login screen, promoted to shared)
// ───────────────────────────────────────────────────────────────────────────
class KagemaParticle {
  double x, y, vx, vy, radius, opacity;
  KagemaParticle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.radius, required this.opacity,
  });
  void tick() {
    x += vx; y += vy;
    if (x < 0) x = 1.0; if (x > 1) x = 0.0;
    if (y < 0) y = 1.0; if (y > 1) y = 0.0;
  }
}

class KagemaParticlePainter extends CustomPainter {
  final List<KagemaParticle> particles;
  final Color color;
  final double connectionDistance;
  final bool isDark;

  KagemaParticlePainter({
    required this.particles,
    required this.color,
    required this.connectionDistance,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dot  = Paint()..style = PaintingStyle.fill;
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.7;

    for (int i = 0; i < particles.length; i++) {
      final p  = particles[i];
      final px = p.x * size.width;
      final py = p.y * size.height;

      dot.color = color.withValues(alpha: p.opacity * (isDark ? 0.55 : 0.45));
      canvas.drawCircle(Offset(px, py), p.radius, dot);

      for (int j = i + 1; j < particles.length; j++) {
        final q   = particles[j];
        final qx  = q.x * size.width;
        final qy  = q.y * size.height;
        final d   = math.sqrt(math.pow(px - qx, 2) + math.pow(py - qy, 2));
        final max = connectionDistance * size.width;
        if (d < max) {
          final a = (1.0 - d / max) *
              (isDark ? 0.22 : 0.15) *
              math.min(p.opacity, q.opacity);
          line.color = color.withValues(alpha: a);
          canvas.drawLine(Offset(px, py), Offset(qx, qy), line);
        }
      }
    }
  }

  @override
  bool shouldRepaint(KagemaParticlePainter old) => true;
}

// ───────────────────────────────────────────────────────────────────────────
// 5.  NEURAL MESH BACKGROUND  (upgraded from original with role colour blobs)
// ───────────────────────────────────────────────────────────────────────────
class NeuralBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final Color primaryBlob;   // role or brand colour for top-right blob
  final Color secondaryBlob; // complementary colour for bottom-left blob
  final bool showParticles;
  final bool showGrid;

  const NeuralBackground({
    super.key,
    required this.child,
    required this.isDark,
    this.primaryBlob   = KagemaColors.electric,
    this.secondaryBlob = KagemaColors.azure,
    this.showParticles = true,
    this.showGrid      = true,
  });

  @override
  State<NeuralBackground> createState() => _NeuralBackgroundState();
}

class _NeuralBackgroundState extends State<NeuralBackground>
    with TickerProviderStateMixin {
  late AnimationController _blobCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _auraCtrl;

  final List<KagemaParticle> _particles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();

    _blobCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 40))
      ..repeat();

    _auraCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);

    // Build particles
    for (int i = 0; i < 42; i++) {
      final speed = 0.00007 + _rng.nextDouble() * 0.00013;
      final angle = _rng.nextDouble() * math.pi * 2;
      _particles.add(KagemaParticle(
        x: _rng.nextDouble(), y: _rng.nextDouble(),
        vx: math.cos(angle) * speed, vy: math.sin(angle) * speed,
        radius: 1.1 + _rng.nextDouble() * 2.2,
        opacity: 0.28 + _rng.nextDouble() * 0.55,
      ));
    }

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..addListener(() {
        for (final p in _particles) p.tick();
        setState(() {});
      })
      ..repeat();
  }

  @override
  void dispose() {
    _blobCtrl.dispose();
    _particleCtrl.dispose();
    _auraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_blobCtrl, _auraCtrl]),
      builder: (context, _) {
        final t = _blobCtrl.value;
        final aura = (_auraCtrl.value * 0.15) + 0.85; // 0.85 → 1.0

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Base colour ──────────────────────────────────────
            Container(
              color: widget.isDark
                  ? KagemaColors.darkBase
                  : KagemaColors.lightBase,
            ),

            // ── FEATURE #5: Role-aware breathing aura ────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.5, -0.3),
                    radius: 1.2 * aura,
                    colors: [
                      widget.primaryBlob.withValues(
                          alpha: widget.isDark ? 0.10 : 0.055),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.5, 0.5),
                    radius: 1.0 * aura,
                    colors: [
                      widget.secondaryBlob.withValues(
                          alpha: widget.isDark ? 0.08 : 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── FEATURE #1: Moving organic blobs ─────────────────
            Positioned(
              top: -150 + (math.sin(t * 2 * math.pi) * 80),
              right: -150 + (math.cos(t * 2 * math.pi) * 80),
              child: _Blob(
                color: widget.primaryBlob.withValues(
                    alpha: widget.isDark ? 0.09 : 0.045),
                size: 700,
              ),
            ),
            Positioned(
              bottom: -200 + (math.cos(t * 2 * math.pi) * 120),
              left: -150 + (math.sin(t * 2 * math.pi) * 80),
              child: _Blob(
                color: widget.secondaryBlob.withValues(
                    alpha: widget.isDark ? 0.09 : 0.045),
                size: 800,
              ),
            ),

            // ── Subtle moving grid ────────────────────────────────
            if (widget.showGrid)
              CustomPaint(
                size: Size.infinite,
                painter: _GridPainter(widget.isDark, t),
              ),

            // ── Backdrop blur (the "frosted glass" feel) ──────────
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const SizedBox.expand(),
            ),

            // ── FEATURE #1: Constellation particles ──────────────
            if (widget.showParticles)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: KagemaParticlePainter(
                      particles: _particles,
                      color: widget.primaryBlob,
                      connectionDistance: 0.17,
                      isDark: widget.isDark,
                    ),
                  ),
                ),
              ),

            // ── Actual page content ───────────────────────────────
            widget.child,
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  final double progress;
  _GridPainter(this.isDark, this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.018)
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
  bool shouldRepaint(_GridPainter old) => old.progress != progress;
}

// ───────────────────────────────────────────────────────────────────────────
// 6.  AI SPECTRUM BORDER  (upgraded: role colour + secondary sweep)
// ───────────────────────────────────────────────────────────────────────────
class AISpectrumBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final bool isEdgeToEdge;
  final Color primaryColor;
  final Color secondaryColor;

  const AISpectrumBorder({
    super.key,
    required this.child,
    this.borderRadius   = 30,
    this.strokeWidth    = 2.5,
    this.isEdgeToEdge   = false,
    this.primaryColor   = KagemaColors.electric,
    this.secondaryColor = KagemaColors.azure,
  });

  @override
  State<AISpectrumBorder> createState() => _AISpectrumBorderState();
}

class _AISpectrumBorderState extends State<AISpectrumBorder>
    with TickerProviderStateMixin {
  late AnimationController _rotCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _rotCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotCtrl, _pulseCtrl]),
      builder: (_, child) => CustomPaint(
        painter: _SpectrumPainter(
          rotation:       _rotCtrl.value,
          pulse:          _pulseCtrl.value,
          borderRadius:   widget.borderRadius,
          strokeWidth:    widget.strokeWidth,
          primaryColor:   widget.primaryColor,
          secondaryColor: widget.secondaryColor,
        ),
        child: widget.isEdgeToEdge
            ? widget.child
            : ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: widget.child,
        ),
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final double rotation, pulse, borderRadius, strokeWidth;
  final Color primaryColor, secondaryColor;

  _SpectrumPainter({
    required this.rotation, required this.pulse,
    required this.borderRadius, required this.strokeWidth,
    required this.primaryColor, required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final grow   = pulse * 2.0;
    final stroke = strokeWidth + (pulse * 0.5);
    const opacity = 0.65;

    final rect = Offset(-grow / 2, -grow / 2) &
    Size(size.width + grow, size.height + grow);

    final colors = [
      primaryColor.withValues(alpha: opacity),
      secondaryColor.withValues(alpha: opacity),
      primaryColor.withValues(alpha: opacity),
    ];

    final gradient = SweepGradient(
      colors: colors,
      transform: GradientRotation(rotation * 2 * math.pi),
    );

    final paint = Paint()
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(rect);

    final rrect = RRect.fromRectAndRadius(
        rect, Radius.circular(borderRadius > 0 ? borderRadius + grow : 0));

    // Outer glow
    final glowPaint = Paint()
      ..strokeWidth = stroke + 5.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, glowPaint..color = glowPaint.color.withValues(alpha: 0.18 * pulse));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}

// ───────────────────────────────────────────────────────────────────────────
// 7.  NEURAL GLASS CARD  (role-colour tinted rotating sweep — upgraded)
// ───────────────────────────────────────────────────────────────────────────
class NeuralGlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderThickness;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final bool useAIBorder;
  final Color accentColor;
  final Color accentColor2;

  const NeuralGlassCard({
    super.key,
    required this.child,
    this.borderRadius     = 30,
    this.borderThickness  = 1.2,
    this.backgroundColor,
    this.padding,
    this.useAIBorder  = false,
    this.accentColor  = KagemaColors.electric,
    this.accentColor2 = KagemaColors.azure,
  });

  @override
  State<NeuralGlassCard> createState() => _NeuralGlassCardState();
}

class _NeuralGlassCardState extends State<NeuralGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: SweepGradient(
            center: Alignment.center,
            colors: [
              widget.accentColor.withValues(alpha: 0.16),
              widget.accentColor2.withValues(alpha: 0.16),
              widget.accentColor.withValues(alpha: 0.16),
            ],
            transform: GradientRotation(_ctrl.value * 2 * math.pi),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 28,
              spreadRadius: -8,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
              widget.borderRadius - widget.borderThickness),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              margin: EdgeInsets.all(widget.borderThickness),
              padding: widget.padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.backgroundColor ??
                    (isDark
                        ? const Color(0xF2121418)
                        : const Color(0xF5FFFFFF)),
                borderRadius: BorderRadius.circular(
                    widget.borderRadius - widget.borderThickness),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.32),
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.useAIBorder) {
      return AISpectrumBorder(
        borderRadius:   widget.borderRadius,
        strokeWidth:    2.0,
        primaryColor:   widget.accentColor,
        secondaryColor: widget.accentColor2,
        child: card,
      );
    }
    return card;
  }
}

// ───────────────────────────────────────────────────────────────────────────
// 8.  ROLE-AWARE AURA LAYER  (drop-in wrapper for any dashboard screen)
//     Wrap your Scaffold body with this for the breathing glow effect.
// ───────────────────────────────────────────────────────────────────────────
class RoleAuraLayer extends StatefulWidget {
  final Widget child;
  final Color roleColor;
  final bool isDark;
  final Alignment auraAlignment;

  const RoleAuraLayer({
    super.key,
    required this.child,
    required this.roleColor,
    required this.isDark,
    this.auraAlignment = const Alignment(0.4, -0.3),
  });

  @override
  State<RoleAuraLayer> createState() => _RoleAuraLayerState();
}

class _RoleAuraLayerState extends State<RoleAuraLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.82, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Stack(
        fit: StackFit.expand,
        children: [
          // Breathing aura
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: widget.auraAlignment,
                  radius: 1.1 * _anim.value,
                  colors: [
                    widget.roleColor.withValues(
                        alpha: (widget.isDark ? 0.10 : 0.055) * _anim.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: widget.child,
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// 9.  GEMINI THEME EXTENSION  (carries gradient + glow into ThemeData)
// ───────────────────────────────────────────────────────────────────────────
class GeminiThemeExtension extends ThemeExtension<GeminiThemeExtension> {
  final LinearGradient? primaryGradient;
  final LinearGradient? glowingBorderGradient;
  final Color? accentGlow;

  const GeminiThemeExtension({
    this.primaryGradient,
    this.glowingBorderGradient,
    this.accentGlow,
  });

  // ── Convenience builders ─────────────────────────────────────────

  /// Full-screen NeuralBackground wrapper — call from any Scaffold body.
  Widget buildCreativeBackground({
    required Widget child,
    bool isDark = false,
    double? maxWidth,
    bool useAIBorder = false,
    Color primaryBlob   = KagemaColors.electric,
    Color secondaryBlob = KagemaColors.azure,
  }) {
    Widget content = maxWidth != null
        ? Center(
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth), child: child))
        : child;

    Widget bg = NeuralBackground(
      isDark:        isDark,
      primaryBlob:   primaryBlob,
      secondaryBlob: secondaryBlob,
      child: content,
    );

    if (useAIBorder) {
      return Stack(
        fit: StackFit.expand,
        children: [
          bg,
          IgnorePointer(
            child: AISpectrumBorder(
              borderRadius:   0,
              strokeWidth:    4.0,
              isEdgeToEdge:   true,
              primaryColor:   primaryBlob,
              secondaryColor: secondaryBlob,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      );
    }
    return bg;
  }

  /// Glassmorphism card — drop-in replacement for Card().
  Widget buildGlowContainer({
    required Widget child,
    double borderRadius    = 30,
    double borderThickness = 1.2,
    Color? backgroundColor,
    EdgeInsets? padding,
    bool useAIBorder       = false,
    Color accentColor      = KagemaColors.electric,
    Color accentColor2     = KagemaColors.azure,
  }) {
    return NeuralGlassCard(
      borderRadius:    borderRadius,
      borderThickness: borderThickness,
      backgroundColor: backgroundColor,
      padding:         padding,
      useAIBorder:     useAIBorder,
      accentColor:     accentColor,
      accentColor2:    accentColor2,
      child: child,
    );
  }

  @override
  GeminiThemeExtension copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? glowingBorderGradient,
    Color? accentGlow,
  }) =>
      GeminiThemeExtension(
        primaryGradient:      primaryGradient      ?? this.primaryGradient,
        glowingBorderGradient: glowingBorderGradient ?? this.glowingBorderGradient,
        accentGlow:           accentGlow           ?? this.accentGlow,
      );

  @override
  GeminiThemeExtension lerp(
      ThemeExtension<GeminiThemeExtension>? other, double t) {
    if (other is! GeminiThemeExtension) return this;
    return GeminiThemeExtension(
      primaryGradient:       LinearGradient.lerp(primaryGradient, other.primaryGradient, t),
      glowingBorderGradient: LinearGradient.lerp(glowingBorderGradient, other.glowingBorderGradient, t),
      accentGlow:            Color.lerp(accentGlow, other.accentGlow, t),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// 10.  APP THEME  (light + dark ThemeData)
// ───────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final dt     = DT(isDark);

    return ThemeData(
      useMaterial3: true,
      brightness:   brightness,
      primaryColor: KagemaColors.electric,

      scaffoldBackgroundColor: dt.pageBg,

      colorScheme: ColorScheme.fromSeed(
        seedColor:  KagemaColors.electric,
        brightness: brightness,
        primary:    KagemaColors.electric,
        secondary:  KagemaColors.azure,
        surface:    dt.cardBg,
        error:      KagemaColors.rose,
      ),

      // ── Typography ─────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 48,
          letterSpacing: -2,
          color: dt.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 32,
          letterSpacing: -1,
          color: dt.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 24,
          letterSpacing: -0.5,
          color: dt.textPrimary,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.3,
          color: dt.textPrimary,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.5,
          color: dt.textPrimary,
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.4,
          color: dt.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: dt.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        bodySmall: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: dt.textMuted,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.4,
          color: Colors.white,
        ),
        labelSmall: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 9,
          letterSpacing: 1.8,
          color: dt.textMuted,
        ),
      ),

      // ── AppBar ─────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation:       0,
        scrolledUnderElevation: 0,
        centerTitle:     true,
        iconTheme:       IconThemeData(color: dt.textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: dt.textPrimary, size: 22),
        titleTextStyle: TextStyle(
          fontWeight:  FontWeight.w900,
          fontSize:    17,
          letterSpacing: 2.5,
          color:       dt.textPrimary,
        ),
      ),

      // ── Cards ──────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color:     dt.cardBg,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: dt.cardBorder, width: 1.2),
        ),
      ),

      // ── Input fields ───────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   dt.inputBg,
        border:      _inputBorder(dt.cardBorder),
        enabledBorder: _inputBorder(dt.cardBorder),
        focusedBorder: _inputBorder(KagemaColors.electric, width: 2),
        errorBorder:   _inputBorder(KagemaColors.rose),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: TextStyle(color: dt.hint, fontWeight: FontWeight.w400),
        labelStyle: TextStyle(
          color: dt.textMuted,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),

      // ── Elevated buttons ───────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KagemaColors.electric,
          foregroundColor: Colors.white,
          elevation:       0,
          shadowColor:     KagemaColors.electric.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      // ── Text buttons ───────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KagemaColors.electric,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),

      // ── Outlined buttons ───────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dt.textPrimary,
          side: BorderSide(color: dt.cardBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // ── Chips ──────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:  dt.cardBg,
        selectedColor:    KagemaColors.electric.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: dt.textPrimary,
        ),
        side: BorderSide(color: dt.cardBorder, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── Bottom navigation bar ──────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: dt.cardBg,
        selectedItemColor:   KagemaColors.electric,
        unselectedItemColor: dt.iconInactive,
        elevation:           0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.3),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 10),
      ),

      // ── Navigation bar (Material 3) ────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:      dt.cardBg,
        indicatorColor:       KagemaColors.electric.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: KagemaColors.electric, size: 24);
          }
          return IconThemeData(color: dt.iconInactive, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = TextStyle(fontSize: 11, color: dt.textMuted);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
              fontWeight: FontWeight.w800,
              color: KagemaColors.electric,
            );
          }
          return base.copyWith(fontWeight: FontWeight.w600);
        }),
        elevation: 0,
      ),

      // ── Drawer ─────────────────────────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor: dt.cardBg,
        elevation:       0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
      ),

      // ── Divider ────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color:     dt.divider,
        thickness: 1,
        space:     24,
      ),

      // ── Dialog ─────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: dt.cardBg,
        elevation:       0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: dt.textPrimary,
          letterSpacing: 0.3,
        ),
        contentTextStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: dt.textSecondary,
        ),
      ),

      // ── BottomSheet ────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dt.cardBg,
        elevation:       0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        dragHandleColor: dt.cardBorder,
        showDragHandle:  true,
      ),

      // ── SnackBar ───────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        behavior:  SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Switch / Checkbox / Radio ──────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? KagemaColors.electric : dt.iconInactive),
        trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected)
            ? KagemaColors.electric.withValues(alpha: 0.35)
            : dt.cardBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? KagemaColors.electric : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: dt.cardBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? KagemaColors.electric : dt.iconInactive),
      ),

      // ── Progress indicator ─────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:           KagemaColors.electric,
        linearTrackColor: dt.cardBorder,
        circularTrackColor: dt.cardBorder,
      ),

      // ── Tabs ───────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:         KagemaColors.electric,
        unselectedLabelColor: dt.textMuted,
        indicatorColor:     KagemaColors.electric,
        indicatorSize:      TabBarIndicatorSize.label,
        labelStyle:   const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
      ),

      // ── ListTile ───────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor:         Colors.transparent,
        iconColor:         dt.textMuted,
        textColor:         dt.textPrimary,
        subtitleTextStyle: TextStyle(color: dt.textMuted, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── Floating action button ─────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: KagemaColors.electric,
        foregroundColor: Colors.white,
        elevation:       0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // ── Icon ───────────────────────────────────────────────────
      iconTheme: IconThemeData(color: dt.textPrimary, size: 22),

      // ── GeminiThemeExtension ───────────────────────────────────
      extensions: [
        GeminiThemeExtension(
          primaryGradient: LinearGradient(
            colors: isDark
                ? [KagemaColors.electric, const Color(0xFFC62828)]
                : [KagemaColors.electric, const Color(0xFFFF7043)],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
          glowingBorderGradient: const LinearGradient(
            colors: [KagemaColors.electric, KagemaColors.azure],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
          accentGlow: KagemaColors.azure,
        ),
      ],
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1.5}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
}

// ───────────────────────────────────────────────────────────────────────────
// 11.  SHIMMER LOADER  (dark-mode aware skeleton loader widget)
//      Usage: ShimmerBox(width: 120, height: 16)
// ───────────────────────────────────────────────────────────────────────────
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 10,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dt = DT.of(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width:  widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end:   Alignment(_anim.value,     0),
            colors: [
              dt.shimmerBase,
              dt.shimmerHigh,
              dt.shimmerBase,
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// 12.  ROLE COLOUR RESOLVER  (single source — mirrors login screen roles)
//      Call RoleColors.of('admin') anywhere in the app.
// ───────────────────────────────────────────────────────────────────────────
class RoleColors {
  RoleColors._();

  static const _map = <String, Color>{
    'admin':      KagemaColors.electric,
    'teacher':    KagemaColors.jade,
    'parent':     KagemaColors.rose,
    'accountant': KagemaColors.amber,
    'secretary':  KagemaColors.violet,
    'staff':      KagemaColors.sky,
  };

  static Color of(String roleId) =>
      _map[roleId.toLowerCase()] ?? KagemaColors.electric;

  static Color light(String roleId, {bool dark = false}) {
    final c = of(roleId);
    return dark
        ? c.withValues(alpha: 0.18)
        : c.withValues(alpha: 0.10);
  }
}