// ═══════════════════════════════════════════════════════════════════════════════
//  KAGEMA SCHOOL — ULTRA THEME  v3.0
//
//  ▸ KagemaColors          — single-source brand + role palette
//  ▸ DT                    — dark/light token helper (all dashboards use this)
//  ▸ TimeGreeter           — time-aware greeting helper
//  ▸ RoleColors            — role → color + gradient resolver
//  ▸ KagemaParticle        — constellation particle model
//  ▸ KagemaParticlePainter — constellation particle renderer
//  ▸ RolePlasma            — pulsing multi-layer role plasma effect
//  ▸ ChromaticBorderPainter— animated 3-tone sweeping border
//  ▸ AISpectrumBorder      — drop-in widget using ChromaticBorderPainter
//  ▸ LiquidGlassCard       — premium glassmorphism card with sweep + shimmer
//  ▸ NeuralBackground      — full-screen living canvas (particles + blobs + grid)
//  ▸ RoleAuraLayer         — breathing radial glow wrapper
//  ▸ ShimmerBox            — skeleton loading block
//  ▸ GeminiThemeExtension  — ThemeExtension with gradient helpers
//  ▸ AppTheme              — light + dark Material 3 ThemeData
//  ▸ ResponsiveBreakpoints — screen-size helpers
//  ▸ KagemaMotion          — shared animation curves & durations
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// ───────────────────────────────────────────────────────────────────────────────
// MOTION TOKENS  — one place to tune every animation in the app
// ───────────────────────────────────────────────────────────────────────────────
class KagemaMotion {
  KagemaMotion._();

  // Durations
  static const Duration instant    = Duration(milliseconds: 120);
  static const Duration fast       = Duration(milliseconds: 220);
  static const Duration normal     = Duration(milliseconds: 350);
  static const Duration slow       = Duration(milliseconds: 550);
  static const Duration verySlow   = Duration(milliseconds: 900);
  static const Duration breathe    = Duration(milliseconds: 3000);
  static const Duration orbit      = Duration(milliseconds: 6000);
  static const Duration blobDrift  = Duration(seconds: 40);

  // Curves
  static const Curve spring        = Curves.easeOutCubic;
  static const Curve smooth        = Curves.easeInOutCubic;
  static const Curve overshoot     = Curves.elasticOut;
  static const Curve snap          = Curves.easeOutExpo;
}

// ───────────────────────────────────────────────────────────────────────────────
// RESPONSIVE BREAKPOINTS
// ───────────────────────────────────────────────────────────────────────────────
enum KagemaLayout { mobile, tablet, desktop, wide }

extension KagemaLayoutHelper on BuildContext {
  KagemaLayout get kagemaLayout {
    final w = MediaQuery.of(this).size.width;
    if (w >= 1400) return KagemaLayout.wide;
    if (w >= 1100) return KagemaLayout.desktop;
    if (w >= 650)  return KagemaLayout.tablet;
    return KagemaLayout.mobile;
  }

  bool get isMobile  => kagemaLayout == KagemaLayout.mobile;
  bool get isTablet  => kagemaLayout == KagemaLayout.tablet;
  bool get isDesktop => kagemaLayout == KagemaLayout.desktop || kagemaLayout == KagemaLayout.wide;
  bool get isWide    => kagemaLayout == KagemaLayout.wide;

  double get sw => MediaQuery.of(this).size.width;
  double get sh => MediaQuery.of(this).size.height;

  /// Fluid value: interpolates between [mobile] and [desktop] based on screen width
  double fluid(double mobile, double desktop) {
    final t = ((sw - 320) / (1400 - 320)).clamp(0.0, 1.0);
    return mobile + (desktop - mobile) * t;
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// COLOUR PALETTE
// ───────────────────────────────────────────────────────────────────────────────
class KagemaColors {
  KagemaColors._();

  // ── Role colours ─────────────────────────────────────────────────────────────
  static const Color adminOrange   = Color(0xFFFF4D00);   // Admin
  static const Color teacherGreen  = Color(0xFF10B981);   // Teacher
  static const Color parentRed     = Color(0xFFEF4444);   // Parent
  static const Color accountantAmber = Color(0xFFF59E0B); // Accountant
  static const Color secretaryViolet = Color(0xFF8B5CF6); // Secretary
  static const Color staffSky      = Color(0xFF0EA5E9);   // Staff

  // ── Supporting accents (used in backgrounds + gradients) ─────────────────────
  static const Color azure         = Color(0xFF2979FF);
  static const Color electric      = adminOrange; // primary brand
  static const Color emerald       = teacherGreen;
  static const Color rose          = parentRed;
  static const Color amber         = accountantAmber;
  static const Color violet        = secretaryViolet;
  static const Color sky           = staffSky;
  static const Color gold          = Color(0xFFFFD700);
  static const Color neonCyan      = Color(0xFF00E5FF);
  static const Color neonMint      = Color(0xFF00FFA3);
  static const Color plasmaViolet  = Color(0xFFBB00FF);

  // ── Dark-mode surfaces ────────────────────────────────────────────────────────
  static const Color darkInk       = Color(0xFF060810);
  static const Color darkBase      = Color(0xFF0A0E1A);
  static const Color darkSurface   = Color(0xFF0F1523);
  static const Color darkCard      = Color(0xFF161D2E);
  static const Color darkCardAlt   = Color(0xFF1C2438);
  static const Color darkBorder    = Color(0xFF252D42);
  static const Color darkBorderHi  = Color(0xFF2E3A52);

  // ── Light-mode surfaces ───────────────────────────────────────────────────────
  static const Color lightBase     = Color(0xFFF5F7FF);
  static const Color lightSurface  = Color(0xFFEEF2FA);
  static const Color lightCard     = Color(0xFFFFFFFF);
  static const Color lightBorder   = Color(0xFFE2E8F0);
  static const Color lightBorderHi = Color(0xFFCBD5E1);

  // ── Role gradient pairs (used in hero panels and cards) ───────────────────────
  static List<Color> roleGradient(String roleId, {bool dark = false}) {
    switch (roleId.toLowerCase()) {
      case 'admin':
        return dark
            ? [const Color(0xFFFF4D00), const Color(0xFFFF8C00)]
            : [const Color(0xFFFF4D00), const Color(0xFFFF7030)];
      case 'teacher':
        return dark
            ? [const Color(0xFF10B981), const Color(0xFF059669)]
            : [const Color(0xFF10B981), const Color(0xFF34D399)];
      case 'parent':
        return dark
            ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
            : [const Color(0xFFEF4444), const Color(0xFFF87171)];
      case 'accountant':
        return dark
            ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
            : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case 'secretary':
        return dark
            ? [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)]
            : [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)];
      case 'staff':
        return dark
            ? [const Color(0xFF0EA5E9), const Color(0xFF0284C7)]
            : [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)];
      default:
        return [adminOrange, const Color(0xFFFF7030)];
    }
  }

  /// Complementary glow colour used as 2nd blob in NeuralBackground
  static Color roleComplement(String roleId) {
    switch (roleId.toLowerCase()) {
      case 'admin':      return azure;
      case 'teacher':    return neonCyan;
      case 'parent':     return plasmaViolet;
      case 'accountant': return neonMint;
      case 'secretary':  return sky;
      case 'staff':      return emerald;
      default:           return azure;
    }
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// DARK-MODE TOKEN HELPER
// ───────────────────────────────────────────────────────────────────────────────
class DT {
  final bool dark;
  const DT(this.dark);

  static DT of(BuildContext context) =>
      DT(Theme.of(context).brightness == Brightness.dark);

  // Backgrounds
  Color get pageBg        => dark ? KagemaColors.darkBase     : KagemaColors.lightBase;
  Color get surfaceBg     => dark ? KagemaColors.darkSurface  : KagemaColors.lightSurface;
  Color get cardBg        => dark ? KagemaColors.darkCard     : KagemaColors.lightCard;
  Color get cardAltBg     => dark ? KagemaColors.darkCardAlt  : const Color(0xFFF8FAFD);
  Color get inputBg       => dark ? KagemaColors.darkCard     : const Color(0xFFF8FAFC);
  Color get inputFocusBg  => dark ? const Color(0xFF1A2438)   : const Color(0xFFF0F5FF);

  // Text
  Color get textPrimary   => dark ? const Color(0xFFF1F5F9)   : const Color(0xFF0F172A);
  Color get textSecondary => dark ? const Color(0xFFCBD5E1)   : const Color(0xFF475569);
  Color get textMuted     => dark ? const Color(0xFF4E5E7A)   : const Color(0xFF94A3B8);
  Color get hint          => dark ? const Color(0xFF384563)   : const Color(0xFFCDD5DE);

  // Icons
  Color get iconInactive  => dark ? const Color(0xFF3D4F6A)   : const Color(0xFFB0BFCF);
  Color get iconActive    => dark ? const Color(0xFFF1F5F9)   : const Color(0xFF1E293B);

  // Borders
  Color get cardBorder    => dark ? KagemaColors.darkBorder   : KagemaColors.lightBorder;
  Color get cardBorderHi  => dark ? KagemaColors.darkBorderHi : KagemaColors.lightBorderHi;
  Color get divider       => dark ? const Color(0xFF161D2E)   : const Color(0xFFE8EDF5);

  // Utility Status Colors
  Color get success       => KagemaColors.teacherGreen;
  Color get warning       => KagemaColors.accountantAmber;
  Color get error         => KagemaColors.parentRed;
  Color get info          => KagemaColors.staffSky;

  // Utility
  Color get footerPillBg  => dark ? KagemaColors.darkCard     : KagemaColors.lightCard;
  Color get footerBorder  => dark ? KagemaColors.darkBorder   : KagemaColors.lightBorder;
  Color get footerText    => dark ? const Color(0xFF64748B)   : const Color(0xFF64748B);
  Color get sectionLabel  => dark ? const Color(0xFFF1F5F9)   : const Color(0xFF0F172A);
  Color get shimmerBase   => dark ? const Color(0xFF161D2E)   : const Color(0xFFE2E8F0);
  Color get shimmerHigh   => dark ? const Color(0xFF252D42)   : const Color(0xFFF8FAFC);
  Color get scrim         => dark
      ? Colors.black.withValues(alpha: 0.78)
      : Colors.black.withValues(alpha: 0.42);

  // Role-aware helpers
  Color aura(Color roleColor)         => roleColor.withValues(alpha: dark ? 0.10 : 0.055);
  Color roleCardBg(Color roleColor)   => roleColor.withValues(alpha: dark ? 0.14 : 0.07);
  Color roleSoftBg(Color roleColor)   => roleColor.withValues(alpha: dark ? 0.08 : 0.04);
  Color roleGlow(Color roleColor)     => roleColor.withValues(alpha: dark ? 0.35 : 0.20);
  Color roleIconBg(Color roleColor, bool selected) {
    if (selected) return roleColor.withValues(alpha: dark ? 0.22 : 0.14);
    return dark ? KagemaColors.darkSurface : const Color(0xFFF1F5F9);
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// TIME-AWARE GREETER
// ───────────────────────────────────────────────────────────────────────────────
class TimeGreeter {
  final String prefix;
  final String emoji;
  final String label;
  final String tailline;
  final Color  glowColor;

  const TimeGreeter._({
    required this.prefix,
    required this.emoji,
    required this.label,
    required this.tailline,
    required this.glowColor,
  });

  static TimeGreeter get now {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) {
      return const TimeGreeter._(
        prefix: 'Good Morning,', emoji: '🌅', label: 'morning',
        tailline: 'Have a brilliant morning ahead.',
        glowColor: Color(0xFFFF9800),
      );
    } else if (h >= 12 && h < 17) {
      return const TimeGreeter._(
        prefix: 'Good Afternoon,', emoji: '☀️', label: 'afternoon',
        tailline: 'Hope your afternoon is electric.',
        glowColor: Color(0xFFFFEB3B),
      );
    } else if (h >= 17 && h < 21) {
      return const TimeGreeter._(
        prefix: 'Good Evening,', emoji: '🌆', label: 'evening',
        tailline: 'Wrapping up a brilliant day?',
        glowColor: Color(0xFFFF5722),
      );
    } else {
      return const TimeGreeter._(
        prefix: 'Good Night,', emoji: '🌙', label: 'night',
        tailline: 'Working late — we\'ve got you covered.',
        glowColor: Color(0xFF7C4DFF),
      );
    }
  }

  String greet(String roleName) => '$prefix $roleName! $emoji';
}

// ───────────────────────────────────────────────────────────────────────────────
// ROLE COLOUR RESOLVER
// ───────────────────────────────────────────────────────────────────────────────
class RoleColors {
  RoleColors._();

  static const _primary = <String, Color>{
    'admin':      KagemaColors.adminOrange,
    'teacher':    KagemaColors.teacherGreen,
    'parent':     KagemaColors.parentRed,
    'accountant': KagemaColors.accountantAmber,
    'secretary':  KagemaColors.secretaryViolet,
    'staff':      KagemaColors.staffSky,
  };

  static Color of(String roleId) =>
      _primary[roleId.toLowerCase()] ?? KagemaColors.electric;

  static LinearGradient gradient(String roleId, {bool dark = false}) {
    final stops = KagemaColors.roleGradient(roleId, dark: dark);
    return LinearGradient(
      colors: stops,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient shimmerGradient(String roleId) {
    final c = of(roleId);
    return LinearGradient(colors: [
      c.withValues(alpha: 0.0),
      c.withValues(alpha: 0.6),
      c.withValues(alpha: 0.0),
    ]);
  }

  static Color complement(String roleId) => KagemaColors.roleComplement(roleId);
}

// ───────────────────────────────────────────────────────────────────────────────
// PARTICLE ENGINE
// ───────────────────────────────────────────────────────────────────────────────
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

  static List<KagemaParticle> generate({int count = 42, math.Random? rng}) {
    final r = rng ?? math.Random();
    return List.generate(count, (_) {
      final speed = 0.000065 + r.nextDouble() * 0.000125;
      final angle = r.nextDouble() * math.pi * 2;
      return KagemaParticle(
        x: r.nextDouble(), y: r.nextDouble(),
        vx: math.cos(angle) * speed, vy: math.sin(angle) * speed,
        radius: 1.0 + r.nextDouble() * 2.4,
        opacity: 0.25 + r.nextDouble() * 0.60,
      );
    });
  }
}

class KagemaParticlePainter extends CustomPainter {
  final List<KagemaParticle> particles;
  final Color color;
  final Color? accentColor;     // second tint for alternating dots
  final double connectionDistance;
  final bool isDark;

  const KagemaParticlePainter({
    required this.particles,
    required this.color,
    this.accentColor,
    required this.connectionDistance,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dot  = Paint()..style = PaintingStyle.fill;
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.65;

    for (int i = 0; i < particles.length; i++) {
      final p  = particles[i];
      final px = p.x * size.width;
      final py = p.y * size.height;
      final c  = (accentColor != null && i.isOdd) ? accentColor! : color;

      dot.color = c.withValues(alpha: p.opacity * (isDark ? 0.58 : 0.42));
      canvas.drawCircle(Offset(px, py), p.radius, dot);

      for (int j = i + 1; j < particles.length; j++) {
        final q   = particles[j];
        final qx  = q.x * size.width;
        final qy  = q.y * size.height;
        final d   = math.sqrt(math.pow(px - qx, 2) + math.pow(py - qy, 2));
        final max = connectionDistance * size.width;
        if (d < max) {
          final a = (1.0 - d / max) *
              (isDark ? 0.24 : 0.14) *
              math.min(p.opacity, q.opacity);
          line.color = c.withValues(alpha: a);
          canvas.drawLine(Offset(px, py), Offset(qx, qy), line);
        }
      }
    }
  }

  @override
  bool shouldRepaint(KagemaParticlePainter old) => true;
}

// ───────────────────────────────────────────────────────────────────────────────
// PLASMA RINGS  — pulsing concentric halos that radiate from a role colour
// Drop-in: wrap any widget with RolePlasma for a premium depth effect
// ───────────────────────────────────────────────────────────────────────────────
class RolePlasma extends StatefulWidget {
  final Widget child;
  final Color color;
  final Color? color2;
  final bool active;

  const RolePlasma({
    super.key,
    required this.child,
    required this.color,
    this.color2,
    this.active = true,
  });

  @override
  State<RolePlasma> createState() => _RolePlasmaState();
}

class _RolePlasmaState extends State<RolePlasma>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => CustomPaint(
        painter: _PlasmaPainter(
          progress: _ctrl.value,
          color: widget.color,
          color2: widget.color2,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _PlasmaPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color? color2;

  _PlasmaPainter({required this.progress, required this.color, this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR   = math.sqrt(size.width * size.width + size.height * size.height) / 2;

    for (int ring = 0; ring < 3; ring++) {
      final phase = (progress + ring * 0.33) % 1.0;
      final r     = phase * maxR * 1.15;
      final alpha = (1.0 - phase) * (ring == 0 ? 0.22 : ring == 1 ? 0.14 : 0.08);
      final c     = (color2 != null && ring.isOdd) ? color2! : color;

      final paint = Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5 - ring * 0.4
        ..color       = c.withValues(alpha: alpha)
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, r.clamp(0, maxR * 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(_PlasmaPainter old) => old.progress != progress;
}

// ───────────────────────────────────────────────────────────────────────────────
// CHROMATIC BORDER PAINTER — triple-colour sweeping animated border
// ───────────────────────────────────────────────────────────────────────────────
class ChromaticBorderPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final double borderRadius;
  final double strokeWidth;
  final Color c1, c2, c3;

  const ChromaticBorderPainter({
    required this.rotation,
    required this.pulse,
    required this.borderRadius,
    required this.strokeWidth,
    required this.c1,
    required this.c2,
    required this.c3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final grow   = pulse * 1.8;
    final stroke = strokeWidth + pulse * 0.6;
    final rect   = Offset(-grow / 2, -grow / 2) &
    Size(size.width + grow, size.height + grow);
    final rrect  = RRect.fromRectAndRadius(
        rect, Radius.circular(borderRadius > 0 ? borderRadius + grow : 0));

    final gradient = SweepGradient(
      colors: [c1, c2, c3, c1],
      transform: GradientRotation(rotation * 2 * math.pi),
    );
    final shader = gradient.createShader(rect);

    // Outer glow pass
    canvas.drawRRect(
      rrect,
      Paint()
        ..strokeWidth = stroke + 8.0
        ..style       = PaintingStyle.stroke
        ..shader      = shader
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color       = c1.withValues(alpha: 0.20 * pulse),
    );

    // Core stroke
    canvas.drawRRect(
      rrect,
      Paint()
        ..strokeWidth = stroke
        ..style       = PaintingStyle.stroke
        ..shader      = shader,
    );
  }

  @override
  bool shouldRepaint(ChromaticBorderPainter old) => true;
}

// ───────────────────────────────────────────────────────────────────────────────
// AI SPECTRUM BORDER — drop-in widget
// ───────────────────────────────────────────────────────────────────────────────
class AISpectrumBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final bool isEdgeToEdge;
  final Color primaryColor;
  final Color secondaryColor;
  final Color? tertiaryColor;

  const AISpectrumBorder({
    super.key,
    required this.child,
    this.borderRadius    = 30,
    this.strokeWidth     = 2.5,
    this.isEdgeToEdge    = false,
    this.primaryColor    = KagemaColors.electric,
    this.secondaryColor  = KagemaColors.azure,
    this.tertiaryColor,
  });

  @override
  State<AISpectrumBorder> createState() => _AISpectrumBorderState();
}

class _AISpectrumBorderState extends State<AISpectrumBorder>
    with TickerProviderStateMixin {
  late AnimationController _rot;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _rot   = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
  }

  @override
  void dispose() { _rot.dispose(); _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c3 = widget.tertiaryColor ??
        Color.lerp(widget.primaryColor, widget.secondaryColor, 0.5)!;
    return AnimatedBuilder(
      animation: Listenable.merge([_rot, _pulse]),
      builder: (_, child) => CustomPaint(
        painter: ChromaticBorderPainter(
          rotation:     _rot.value,
          pulse:        _pulse.value,
          borderRadius: widget.borderRadius,
          strokeWidth:  widget.strokeWidth,
          c1: widget.primaryColor,
          c2: widget.secondaryColor,
          c3: c3,
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

// ───────────────────────────────────────────────────────────────────────────────
// LIQUID GLASS CARD - FIXED
// Premium card: sweep gradient border + blur + inner shimmer line
// ───────────────────────────────────────────────────────────────────────────────
class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderThickness;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final bool useAIBorder;
  final Color accentColor;
  final Color accentColor2;
  final Color? accentColor3;
  final double elevation;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius     = 28,
    this.borderThickness  = 1.3,
    this.backgroundColor,
    this.padding,
    this.useAIBorder      = false,
    this.accentColor      = KagemaColors.electric,
    this.accentColor2     = KagemaColors.azure,
    this.accentColor3,
    this.elevation        = 1.0,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
  }

  @override
  void dispose() { _sweep.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt     = DT(isDark);

    Widget card = AnimatedBuilder(
      animation: _sweep,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              center: Alignment.center,
              colors: [
                widget.accentColor.withValues(alpha: 0.18),
                widget.accentColor2.withValues(alpha: 0.18),
                (widget.accentColor3 ?? widget.accentColor).withValues(alpha: 0.18),
                widget.accentColor.withValues(alpha: 0.18),
              ],
              transform: GradientRotation(_sweep.value * 2 * math.pi),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: isDark ? 0.18 : 0.09),
                blurRadius: 32 * widget.elevation,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.06),
                blurRadius: 24 * widget.elevation,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderThickness),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                margin: EdgeInsets.all(widget.borderThickness),
                padding: widget.padding ?? const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ??
                      (isDark ? KagemaColors.darkCard.withValues(alpha: 0.94)
                          : Colors.white.withValues(alpha: 0.96)),
                  borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderThickness),
                  // FIX: Use uniform border instead of non-uniform to avoid crash
                  border: Border.all(
                    color: dt.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Stack(
                  children: [
                    widget.child,
                    // Top shimmer line - moved from border to separate widget
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(widget.borderRadius - widget.borderThickness),
                            topRight: Radius.circular(widget.borderRadius - widget.borderThickness),
                          ),
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: isDark ? 0.12 : 0.70),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.useAIBorder) {
      return AISpectrumBorder(
        borderRadius:   widget.borderRadius,
        strokeWidth:    2.2,
        primaryColor:   widget.accentColor,
        secondaryColor: widget.accentColor2,
        tertiaryColor:  widget.accentColor3,
        child: card,
      );
    }
    return card;
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// NEURAL BACKGROUND  — full-screen living canvas
//   • two animated colour blobs (role-aware)
//   • subtle moving grid
//   • constellation particles (role + complement tint)
//   • backdrop blur for glass feel
//   • breathing radial aura
// ───────────────────────────────────────────────────────────────────────────────
class NeuralBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final Color primaryBlob;
  final Color secondaryBlob;
  final bool showParticles;
  final bool showGrid;
  final bool showBlobs;

  const NeuralBackground({
    super.key,
    required this.child,
    required this.isDark,
    this.primaryBlob    = KagemaColors.electric,
    this.secondaryBlob  = KagemaColors.azure,
    this.showParticles  = true,
    this.showGrid       = true,
    this.showBlobs      = true,
  });

  @override
  State<NeuralBackground> createState() => _NeuralBackgroundState();
}

class _NeuralBackgroundState extends State<NeuralBackground>
    with TickerProviderStateMixin {
  late AnimationController _blobCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _auraCtrl;

  late List<KagemaParticle> _particles;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _particles = KagemaParticle.generate(count: 46, rng: _rng);

    _blobCtrl = AnimationController(
        vsync: this, duration: KagemaMotion.blobDrift)..repeat();

    _auraCtrl = AnimationController(
        vsync: this, duration: KagemaMotion.breathe)..repeat(reverse: true);

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..addListener(() {
        for (final p in _particles) p.tick();
        if (mounted) setState(() {});
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
      builder: (_, __) {
        final t    = _blobCtrl.value;
        final aura = _auraCtrl.value * 0.18 + 0.82;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Base
            Container(
              color: widget.isDark ? KagemaColors.darkInk : KagemaColors.lightBase,
            ),

            // Breathing radial aura — role colour
            if (widget.showBlobs) ...[
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.55, -0.4),
                      radius: 1.3 * aura,
                      colors: [
                        widget.primaryBlob.withValues(alpha: widget.isDark ? 0.11 : 0.06),
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
                      center: const Alignment(-0.55, 0.55),
                      radius: 1.1 * aura,
                      colors: [
                        widget.secondaryBlob.withValues(alpha: widget.isDark ? 0.08 : 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Organic moving blobs
              Positioned(
                top:   -180 + math.sin(t * 2 * math.pi) * 90,
                right: -160 + math.cos(t * 2 * math.pi) * 80,
                child: _Blob(
                  color: widget.primaryBlob.withValues(alpha: widget.isDark ? 0.08 : 0.04),
                  size: 680,
                ),
              ),
              Positioned(
                bottom: -220 + math.cos(t * 2 * math.pi) * 110,
                left:   -160 + math.sin(t * 2 * math.pi) * 85,
                child: _Blob(
                  color: widget.secondaryBlob.withValues(alpha: widget.isDark ? 0.08 : 0.04),
                  size: 820,
                ),
              ),
              // Tertiary accent blob — small, fast
              Positioned(
                top:  MediaQuery.of(context).size.height * 0.4 +
                    math.sin(t * 4 * math.pi) * 60,
                left: MediaQuery.of(context).size.width * 0.5 +
                    math.cos(t * 3 * math.pi) * 80,
                child: _Blob(
                  color: Color.lerp(widget.primaryBlob, widget.secondaryBlob, 0.5)!
                      .withValues(alpha: widget.isDark ? 0.06 : 0.03),
                  size: 320,
                ),
              ),
            ],

            // Grid
            if (widget.showGrid)
              CustomPaint(
                size: Size.infinite,
                painter: _DriftingGridPainter(isDark: widget.isDark, t: t),
              ),

            // Backdrop blur — makes background feel frosted
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: const SizedBox.expand(),
            ),

            // Particles
            if (widget.showParticles)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: KagemaParticlePainter(
                      particles: _particles,
                      color:      widget.primaryBlob,
                      accentColor: widget.secondaryBlob,
                      connectionDistance: 0.16,
                      isDark: widget.isDark,
                    ),
                  ),
                ),
              ),

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
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _DriftingGridPainter extends CustomPainter {
  final bool isDark;
  final double t;
  const _DriftingGridPainter({required this.isDark, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color    = (isDark ? Colors.white : Colors.indigo)
          .withValues(alpha: isDark ? 0.016 : 0.012)
      ..strokeWidth = 0.5;
    const spacing = 90.0;
    final offset  = t * spacing;
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x + offset, 0), Offset(x + offset, size.height), paint);
    }
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y + offset), Offset(size.width, y + offset), paint);
    }
  }

  @override
  bool shouldRepaint(_DriftingGridPainter old) => old.t != old.t;
}

// ───────────────────────────────────────────────────────────────────────────────
// ROLE AURA LAYER — breathing radial glow for any dashboard screen
// ───────────────────────────────────────────────────────────────────────────────
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
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: KagemaMotion.breathe)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.80, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: KagemaMotion.normal,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: widget.auraAlignment,
                  radius: 1.15 * _anim.value,
                  colors: [
                    widget.roleColor.withValues(
                        alpha: (widget.isDark ? 0.11 : 0.06) * _anim.value),
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

// ───────────────────────────────────────────────────────────────────────────────
// SHIMMER BOX — skeleton loading
// ───────────────────────────────────────────────────────────────────────────────
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
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _anim = Tween<double>(begin: -1.8, end: 2.8)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final dt = DT.of(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end:   Alignment(_anim.value,     0),
            colors: [dt.shimmerBase, dt.shimmerHigh, dt.shimmerBase],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// GEMINI THEME EXTENSION — convenience builders for all dashboards
// ───────────────────────────────────────────────────────────────────────────────
class GeminiThemeExtension extends ThemeExtension<GeminiThemeExtension> {
  final LinearGradient? primaryGradient;
  final LinearGradient? glowingBorderGradient;
  final Color? accentGlow;

  const GeminiThemeExtension({
    this.primaryGradient,
    this.glowingBorderGradient,
    this.accentGlow,
  });

  // ── Build full-screen neural background (use in Scaffold body) ───────────────
  Widget buildCreativeBackground({
    required Widget child,
    bool isDark         = false,
    double? maxWidth,
    bool useAIBorder    = false,
    Color primaryBlob   = KagemaColors.electric,
    Color secondaryBlob = KagemaColors.azure,
    bool showParticles  = true,
    bool showGrid       = true,
  }) {
    Widget content = maxWidth != null
        ? Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth), child: child))
        : child;

    Widget bg = NeuralBackground(
      isDark:        isDark,
      primaryBlob:   primaryBlob,
      secondaryBlob: secondaryBlob,
      showParticles: showParticles,
      showGrid:      showGrid,
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
              strokeWidth:    4.5,
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

  // ── Build glassmorphism card ──────────────────────────────────────────────────
  Widget buildGlowContainer({
    required Widget child,
    double borderRadius    = 28,
    double borderThickness = 1.3,
    Color? backgroundColor,
    EdgeInsets? padding,
    bool useAIBorder       = false,
    Color accentColor      = KagemaColors.electric,
    Color accentColor2     = KagemaColors.azure,
    Color? accentColor3,
    double elevation       = 1.0,
  }) {
    return LiquidGlassCard(
      borderRadius:    borderRadius,
      borderThickness: borderThickness,
      backgroundColor: backgroundColor,
      padding:         padding,
      useAIBorder:     useAIBorder,
      accentColor:     accentColor,
      accentColor2:    accentColor2,
      accentColor3:    accentColor3,
      elevation:       elevation,
      child: child,
    );
  }

  @override
  GeminiThemeExtension copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? glowingBorderGradient,
    Color? accentGlow,
  }) => GeminiThemeExtension(
    primaryGradient:       primaryGradient       ?? this.primaryGradient,
    glowingBorderGradient: glowingBorderGradient ?? this.glowingBorderGradient,
    accentGlow:            accentGlow            ?? this.accentGlow,
  );

  @override
  GeminiThemeExtension lerp(ThemeExtension<GeminiThemeExtension>? other, double t) {
    if (other is! GeminiThemeExtension) return this;
    return GeminiThemeExtension(
      primaryGradient:       LinearGradient.lerp(primaryGradient, other.primaryGradient, t),
      glowingBorderGradient: LinearGradient.lerp(glowingBorderGradient, other.glowingBorderGradient, t),
      accentGlow:            Color.lerp(accentGlow, other.accentGlow, t),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// APP THEME — Material 3 ThemeData (light + dark)
// ───────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final dt     = DT(isDark);

    return ThemeData(
      useMaterial3:  true,
      brightness:    brightness,
      primaryColor:  KagemaColors.electric,

      scaffoldBackgroundColor: dt.pageBg,

      colorScheme: ColorScheme.fromSeed(
        seedColor:  KagemaColors.electric,
        brightness: brightness,
        primary:    KagemaColors.electric,
        secondary:  KagemaColors.azure,
        tertiary:   KagemaColors.teacherGreen,
        surface:    dt.cardBg,
        error:      KagemaColors.rose,
        onPrimary:  Colors.white,
        onSecondary: Colors.white,
        onSurface:  dt.textPrimary,
        onError:    Colors.white,
      ),

      // ── Typography ────────────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w900, fontSize: 52,
          letterSpacing: -2.5, color: dt.textPrimary, height: 1.0,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 40,
          letterSpacing: -1.5, color: dt.textPrimary, height: 1.05,
        ),
        displaySmall: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 32,
          letterSpacing: -1.0, color: dt.textPrimary, height: 1.1,
        ),
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w900, fontSize: 28,
          letterSpacing: -0.8, color: dt.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 22,
          letterSpacing: -0.4, color: dt.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700, fontSize: 18,
          letterSpacing: -0.2, color: dt.textPrimary,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 17,
          letterSpacing: 0.2, color: dt.textPrimary,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700, fontSize: 15,
          letterSpacing: 0.4, color: dt.textPrimary,
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w700, fontSize: 13,
          letterSpacing: 0.3, color: dt.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w500, fontSize: 16,
          color: dt.textPrimary, height: 1.55,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w400, fontSize: 14,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontWeight: FontWeight.w400, fontSize: 12,
          color: dt.textMuted, height: 1.5,
        ),
        labelLarge: const TextStyle(
          fontWeight: FontWeight.w800, fontSize: 14,
          letterSpacing: 0.4, color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontWeight: FontWeight.w700, fontSize: 11,
          letterSpacing: 1.0, color: dt.textMuted,
        ),
        labelSmall: TextStyle(
          fontWeight: FontWeight.w700, fontSize: 9,
          letterSpacing: 2.0, color: dt.textMuted,
        ),
      ),

      // ── AppBar ────────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:         Colors.transparent,
        elevation:               0,
        scrolledUnderElevation:  0,
        centerTitle:             true,
        iconTheme:               IconThemeData(color: dt.textPrimary, size: 22),
        actionsIconTheme:        IconThemeData(color: dt.textPrimary, size: 22),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w900, fontSize: 17,
          letterSpacing: 2.2, color: dt.textPrimary,
        ),
      ),

      // ── Cards ─────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation:        0,
        color:            dt.cardBg,
        shadowColor:      Colors.black.withValues(alpha: isDark ? 0.4 : 0.07),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: dt.cardBorder, width: 1.2),
        ),
      ),

      // ── Inputs ────────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   dt.inputBg,
        border:           _inputBorder(dt.cardBorder),
        enabledBorder:    _inputBorder(dt.cardBorder),
        focusedBorder:    _inputBorder(KagemaColors.electric, width: 2.2),
        errorBorder:      _inputBorder(KagemaColors.rose),
        focusedErrorBorder: _inputBorder(KagemaColors.rose, width: 2.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(color: dt.hint, fontWeight: FontWeight.w400, fontSize: 13.5),
        labelStyle: TextStyle(color: dt.textMuted, fontWeight: FontWeight.w600, fontSize: 13),
        floatingLabelStyle: TextStyle(color: KagemaColors.electric, fontWeight: FontWeight.w700),
        prefixIconColor: dt.iconInactive,
        suffixIconColor: dt.iconInactive,
        errorStyle: TextStyle(color: KagemaColors.rose, fontWeight: FontWeight.w600, fontSize: 11),
      ),

      // ── Elevated button ───────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KagemaColors.electric,
          foregroundColor: Colors.white,
          elevation:       0,
          shadowColor:     KagemaColors.electric.withValues(alpha: 0.5),
          padding:         const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),

      // ── Text button ───────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KagemaColors.electric,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),

      // ── Outlined button ───────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dt.textPrimary,
          side: BorderSide(color: dt.cardBorderHi, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),

      // ── Chips ─────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:  dt.cardBg,
        selectedColor:    KagemaColors.electric.withValues(alpha: 0.15),
        disabledColor:    dt.surfaceBg,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: dt.textPrimary),
        secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
        side:   BorderSide(color: dt.cardBorder, width: 1.2),
        shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        iconTheme: IconThemeData(color: dt.iconInactive, size: 16),
      ),

      // ── BottomNavigationBar ───────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      dt.cardBg,
        selectedItemColor:    KagemaColors.electric,
        unselectedItemColor:  dt.iconInactive,
        elevation:            0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.3),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 10),
      ),

      // ── NavigationBar (M3) ────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:  dt.cardBg,
        indicatorColor:   KagemaColors.electric.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return IconThemeData(color: KagemaColors.electric, size: 24);
          }
          return IconThemeData(color: dt.iconInactive, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final base = TextStyle(fontSize: 11, color: dt.textMuted);
          if (s.contains(WidgetState.selected)) {
            return base.copyWith(
                fontWeight: FontWeight.w800, color: KagemaColors.electric);
          }
          return base.copyWith(fontWeight: FontWeight.w600);
        }),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ── NavigationRail ────────────────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:    dt.cardBg,
        selectedIconTheme:  const IconThemeData(color: KagemaColors.electric, size: 24),
        unselectedIconTheme: IconThemeData(color: dt.iconInactive, size: 22),
        selectedLabelTextStyle: const TextStyle(
            color: KagemaColors.electric, fontWeight: FontWeight.w800, fontSize: 11),
        unselectedLabelTextStyle: TextStyle(
            color: dt.textMuted, fontWeight: FontWeight.w600, fontSize: 11),
        indicatorColor: KagemaColors.electric.withValues(alpha: 0.14),
        elevation: 0,
        groupAlignment: -0.8,
      ),

      // ── Drawer ────────────────────────────────────────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor: dt.cardBg,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: dt.divider, thickness: 1, space: 24,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: dt.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w900, fontSize: 18,
          color: dt.textPrimary, letterSpacing: 0.2,
        ),
        contentTextStyle: TextStyle(
          fontWeight: FontWeight.w500, fontSize: 14,
          color: dt.textSecondary, height: 1.55,
        ),
        shadowColor: Colors.black.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
      ),

      // ── BottomSheet ───────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:  dt.cardBg,
        elevation:        0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        dragHandleColor: dt.cardBorderHi,
        dragHandleSize:  const Size(40, 4),
        showDragHandle:  true,
        surfaceTintColor: Colors.transparent,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? KagemaColors.darkCardAlt : const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        behavior:  SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actionTextColor: KagemaColors.electric,
      ),

      // ── Switch / Checkbox / Radio ─────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? KagemaColors.electric : dt.iconInactive),
        trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected)
            ? KagemaColors.electric.withValues(alpha: 0.38)
            : dt.cardBorder),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? KagemaColors.electric : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: dt.cardBorderHi, width: 1.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        overlayColor: WidgetStateProperty.all(
            KagemaColors.electric.withValues(alpha: 0.08)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? KagemaColors.electric : dt.iconInactive),
        overlayColor: WidgetStateProperty.all(
            KagemaColors.electric.withValues(alpha: 0.08)),
      ),

      // ── Slider ────────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor:   KagemaColors.electric,
        inactiveTrackColor: dt.cardBorder,
        thumbColor:         KagemaColors.electric,
        overlayColor:       KagemaColors.electric.withValues(alpha: 0.12),
        valueIndicatorColor: KagemaColors.electric,
        valueIndicatorTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700),
        trackHeight: 4,
      ),

      // ── Progress indicator ────────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:              KagemaColors.electric,
        linearTrackColor:   dt.cardBorder,
        circularTrackColor: dt.cardBorder,
        linearMinHeight:    6,
      ),

      // ── Tabs ─────────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:            KagemaColors.electric,
        unselectedLabelColor:  dt.textMuted,
        indicatorColor:        KagemaColors.electric,
        indicatorSize:         TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(
            KagemaColors.electric.withValues(alpha: 0.06)),
      ),

      // ── ListTile ──────────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor:          Colors.transparent,
        selectedTileColor:  KagemaColors.electric.withValues(alpha: 0.08),
        iconColor:          dt.iconInactive,
        selectedColor:      KagemaColors.electric,
        textColor:          dt.textPrimary,
        subtitleTextStyle:  TextStyle(color: dt.textMuted, fontSize: 12, height: 1.4),
        leadingAndTrailingTextStyle: TextStyle(color: dt.textMuted, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        dense: false,
        visualDensity: VisualDensity.standard,
        minLeadingWidth: 24,
      ),

      // ── FAB ──────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor:  KagemaColors.electric,
        foregroundColor:  Colors.white,
        elevation:        0,
        focusElevation:   0,
        hoverElevation:   4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        extendedTextStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3),
      ),

      // ── Icon ─────────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: dt.iconActive, size: 22),
      primaryIconTheme: const IconThemeData(color: KagemaColors.electric, size: 22),

      // ── Tooltip ──────────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? KagemaColors.darkCardAlt : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12),
          ],
        ),
        textStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),

      // ── Badge ─────────────────────────────────────────────────────────────────
      badgeTheme: BadgeThemeData(
        backgroundColor: KagemaColors.rose,
        textColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        smallSize: 8,
        largeSize: 18,
      ),

      // ── PopupMenu ────────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: dt.cardBg,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: dt.cardBorder, width: 1.0),
        ),
        textStyle: TextStyle(
            color: dt.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
        surfaceTintColor: Colors.transparent,
      ),

      // ── DatePicker ───────────────────────────────────────────────────────────
      datePickerTheme: DatePickerThemeData(
        backgroundColor:     dt.cardBg,
        headerBackgroundColor: KagemaColors.electric,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? Colors.white : dt.textPrimary),
        dayBackgroundColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? KagemaColors.electric : Colors.transparent),
        todayForegroundColor: WidgetStateProperty.all(KagemaColors.electric),
        todayBorder: const BorderSide(color: KagemaColors.electric, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Extensions ───────────────────────────────────────────────────────────
      extensions: [
        GeminiThemeExtension(
          primaryGradient: LinearGradient(
            colors: isDark
                ? [KagemaColors.electric, const Color(0xFFFF7030)]
                : [KagemaColors.electric, const Color(0xFFFF6040)],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
          glowingBorderGradient: const LinearGradient(
            colors: [KagemaColors.electric, KagemaColors.azure, KagemaColors.teacherGreen],
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

// ───────────────────────────────────────────────────────────────────────────────
// CONVENIENCE EXTENSION on BuildContext
// Access the GeminiThemeExtension from anywhere in the widget tree
// ───────────────────────────────────────────────────────────────────────────────
extension KagemaThemeX on BuildContext {
  GeminiThemeExtension? get kagemaTheme =>
      Theme.of(this).extension<GeminiThemeExtension>();

  DT get dt => DT.of(this);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Screen metrics helpers
  double get pt => MediaQuery.of(this).padding.top;
  double get pb => MediaQuery.of(this).padding.bottom;
}