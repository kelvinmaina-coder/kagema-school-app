// ═══════════════════════════════════════════════════════════════════════════════════════════
//  KAGEMA SCHOOL - ULTRA THEME  v5.0  🚀
//  ✨ NEW: Animated cards, Smart empty states, Adaptive grid
// ═══════════════════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// ───────────────────────────────────────────────────────────────────────────────────────────
// FALLBACK CONTEXT
// ───────────────────────────────────────────────────────────────────────────────────────────
class _FallbackContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName.toString().contains('width')) return 1100.0;
    if (invocation.memberName.toString().contains('height')) return 800.0;
    return null;
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// MOTION TOKENS
// ───────────────────────────────────────────────────────────────────────────────────────────
class KagemaMotion {
  KagemaMotion._();

  static const Duration instant    = Duration(milliseconds: 120);
  static const Duration fast       = Duration(milliseconds: 220);
  static const Duration normal     = Duration(milliseconds: 350);
  static const Duration slow       = Duration(milliseconds: 550);
  static const Duration verySlow   = Duration(milliseconds: 900);
  static const Duration breathe    = Duration(milliseconds: 3000);
  static const Duration orbit      = Duration(milliseconds: 6000);
  static const Duration blobDrift  = Duration(seconds: 40);

  static const Curve spring        = Curves.easeOutCubic;
  static const Curve smooth        = Curves.easeInOutCubic;
  static const Curve overshoot     = Curves.elasticOut;
  static const Curve snap          = Curves.easeOutExpo;

  // ✨ NEW: Extra animation curves
  static const Curve gentleBounce = Curves.easeOutBack;
  static const Curve softFade    = Curves.easeOutQuad;
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// RESPONSIVE BREAKPOINTS + TYPOGRAPHY SCALE
// ───────────────────────────────────────────────────────────────────────────────────────────
enum KagemaLayout { mobile, tablet, desktop, wide }

class TypographyScale {
  final double mobile;
  final double tablet;
  final double desktop;

  const TypographyScale(this.mobile, this.tablet, this.desktop);

  double resolve(BuildContext context) {
    try {
      final width = MediaQuery.of(context).size.width;
      if (width < 650) return mobile;
      if (width < 1100) return tablet;
      return desktop;
    } catch (e) {
      return desktop;
    }
  }

  TextStyle apply(TextStyle base, BuildContext context) {
    return base.copyWith(fontSize: resolve(context));
  }

  static const headlineLarge = TypographyScale(24, 32, 48);
  static const headlineMedium = TypographyScale(20, 26, 36);
  static const headlineSmall = TypographyScale(16, 20, 28);
  static const titleLarge = TypographyScale(14, 18, 24);
  static const titleMedium = TypographyScale(12, 15, 20);
  static const bodyLarge = TypographyScale(14, 16, 18);
  static const bodyMedium = TypographyScale(12, 14, 16);
  static const bodySmall = TypographyScale(10, 12, 14);
  static const labelLarge = TypographyScale(11, 13, 15);
  static const labelMedium = TypographyScale(9, 10, 12);
  static const labelSmall = TypographyScale(7, 8, 9);
}

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

  double fluid(double mobile, double desktop) {
    final t = ((sw - 320) / (1400 - 320)).clamp(0.0, 1.0);
    return mobile + (desktop - mobile) * t;
  }

  double ts(TypographyScale scale) => scale.resolve(this);
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// COLOUR PALETTE
// ───────────────────────────────────────────────────────────────────────────────────────────
class KagemaColors {
  KagemaColors._();

  static const Color adminOrange   = Color(0xFFFF4D00);
  static const Color teacherGreen  = Color(0xFF10B981);
  static const Color parentRed     = Color(0xFFEF4444);
  static const Color accountantAmber = Color(0xFFF59E0B);
  static const Color secretaryViolet = Color(0xFF8B5CF6);
  static const Color staffSky      = Color(0xFF0EA5E9);

  static const Color azure         = Color(0xFF2979FF);
  static const Color electric      = adminOrange;
  static const Color emerald       = teacherGreen;
  static const Color rose          = parentRed;
  static const Color amber         = accountantAmber;
  static const Color violet        = secretaryViolet;
  static const Color sky           = staffSky;
  static const Color gold          = Color(0xFFFFD700);
  static const Color neonCyan      = Color(0xFF00E5FF);
  static const Color neonMint      = Color(0xFF00FFA3);
  static const Color plasmaViolet  = Color(0xFFBB00FF);

  static const Color darkInk       = Color(0xFF060810);
  static const Color darkBase      = Color(0xFF0A0E1A);
  static const Color darkSurface   = Color(0xFF0F1523);
  static const Color darkCard      = Color(0xFF161D2E);
  static const Color darkCardAlt   = Color(0xFF1C2438);
  static const Color darkBorder    = Color(0xFF252D42);
  static const Color darkBorderHi  = Color(0xFF2E3A52);

  static const Color lightBase     = Color(0xFFF5F7FF);
  static const Color lightSurface  = Color(0xFFEEF2FA);
  static const Color lightCard     = Color(0xFFFFFFFF);
  static const Color lightBorder   = Color(0xFFE2E8F0);
  static const Color lightBorderHi = Color(0xFFCBD5E1);

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

  static List<Color> morphingGradient(String roleId, {bool dark = false, DateTime? time}) {
    final hour = time?.hour ?? DateTime.now().hour;
    final base = roleGradient(roleId, dark: dark);

    if (hour >= 6 && hour < 12) {
      return base.map((c) => Color.lerp(c, const Color(0xFFFFD700), 0.15)!).toList();
    } else if (hour >= 17 && hour < 21) {
      return base.map((c) => Color.lerp(c, const Color(0xFF4A00E0), 0.15)!).toList();
    } else if (hour >= 21 || hour < 6) {
      return base.map((c) => Color.lerp(c, const Color(0xFF1A0A3E), 0.25)!).toList();
    }
    return base;
  }

  static Color generateVariant(Color base, {double offset = 0.1}) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness(
        (hsl.lightness + offset).clamp(0.0, 1.0)
    ).toColor();
  }

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

// ───────────────────────────────────────────────────────────────────────────────────────────
// DARK-MODE TOKEN HELPER
// ───────────────────────────────────────────────────────────────────────────────────────────
class DT {
  final bool dark;
  const DT(this.dark);

  static DT of(BuildContext context) =>
      DT(Theme.of(context).brightness == Brightness.dark);

  Color get pageBg        => dark ? KagemaColors.darkBase     : KagemaColors.lightBase;
  Color get surfaceBg     => dark ? KagemaColors.darkSurface  : KagemaColors.lightSurface;
  Color get cardBg        => dark ? KagemaColors.darkCard     : KagemaColors.lightCard;
  Color get cardAltBg     => dark ? KagemaColors.darkCardAlt  : const Color(0xFFF8FAFD);
  Color get inputBg       => dark ? KagemaColors.darkCard     : const Color(0xFFF8FAFC);
  Color get inputFocusBg  => dark ? const Color(0xFF1A2438)   : const Color(0xFFF0F5FF);

  Color get textPrimary   => dark ? const Color(0xFFF1F5F9)   : const Color(0xFF0F172A);
  Color get textSecondary => dark ? const Color(0xFFCBD5E1)   : const Color(0xFF475569);
  Color get textMuted     => dark ? const Color(0xFF4E5E7A)   : const Color(0xFF94A3B8);
  Color get hint          => dark ? const Color(0xFF384563)   : const Color(0xFFCDD5DE);

  Color get iconInactive  => dark ? const Color(0xFF3D4F6A)   : const Color(0xFFB0BFCF);
  Color get iconActive    => dark ? const Color(0xFFF1F5F9)   : const Color(0xFF1E293B);

  Color get cardBorder    => dark ? KagemaColors.darkBorder   : KagemaColors.lightBorder;
  Color get cardBorderHi  => dark ? KagemaColors.darkBorderHi : KagemaColors.lightBorderHi;
  Color get divider       => dark ? const Color(0xFF161D2E)   : const Color(0xFFE8EDF5);

  Color get success       => KagemaColors.teacherGreen;
  Color get warning       => KagemaColors.accountantAmber;
  Color get error         => KagemaColors.parentRed;
  Color get info          => KagemaColors.staffSky;

  Color get footerPillBg  => dark ? KagemaColors.darkCard     : KagemaColors.lightCard;
  Color get footerBorder  => dark ? KagemaColors.darkBorder   : KagemaColors.lightBorder;
  Color get footerText    => dark ? const Color(0xFF64748B)   : const Color(0xFF64748B);
  Color get sectionLabel  => dark ? const Color(0xFFF1F5F9)   : const Color(0xFF0F172A);
  Color get shimmerBase   => dark ? const Color(0xFF161D2E)   : const Color(0xFFE2E8F0);
  Color get shimmerHigh   => dark ? const Color(0xFF252D42)   : const Color(0xFFF8FAFC);
  Color get scrim         => dark
      ? Colors.black.withOpacity(0.78)
      : Colors.black.withOpacity(0.42);

  Color aura(Color roleColor)         => roleColor.withOpacity(dark ? 0.10 : 0.055);
  Color roleCardBg(Color roleColor)   => roleColor.withOpacity(dark ? 0.14 : 0.07);
  Color roleSoftBg(Color roleColor)   => roleColor.withOpacity(dark ? 0.08 : 0.04);
  Color roleGlow(Color roleColor)     => roleColor.withOpacity(dark ? 0.35 : 0.20);
  Color roleIconBg(Color roleColor, bool selected) {
    if (selected) return roleColor.withOpacity(dark ? 0.22 : 0.14);
    return dark ? KagemaColors.darkSurface : const Color(0xFFF1F5F9);
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// TIME-AWARE GREETER - WITH REAL EMOJIS
// ───────────────────────────────────────────────────────────────────────────────────────────
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
        prefix: 'Good Morning,',
        emoji: '\u{1F305}',
        label: 'morning',
        tailline: 'Have a brilliant morning ahead.',
        glowColor: Color(0xFFFF9800),
      );
    } else if (h >= 12 && h < 17) {
      return const TimeGreeter._(
        prefix: 'Good Afternoon,',
        emoji: '\u{2600}\u{FE0F}',
        label: 'afternoon',
        tailline: 'Hope your afternoon is electric.',
        glowColor: Color(0xFFFFEB3B),
      );
    } else if (h >= 17 && h < 21) {
      return const TimeGreeter._(
        prefix: 'Good Evening,',
        emoji: '\u{1F306}',
        label: 'evening',
        tailline: 'Wrapping up a brilliant day?',
        glowColor: Color(0xFFFF5722),
      );
    } else {
      return const TimeGreeter._(
        prefix: 'Good Night,',
        emoji: '\u{1F319}',
        label: 'night',
        tailline: 'Working late - we\'ve got you covered.',
        glowColor: Color(0xFF7C4DFF),
      );
    }
  }

  String greet(String roleName) => '$prefix $roleName! $emoji';
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// ROLE COLOUR RESOLVER
// ───────────────────────────────────────────────────────────────────────────────────────────
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
    final stops = KagemaColors.morphingGradient(roleId, dark: dark);
    return LinearGradient(
      colors: stops,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient shimmerGradient(String roleId) {
    final c = of(roleId);
    return LinearGradient(colors: [
      c.withOpacity(0.0),
      c.withOpacity(0.6),
      c.withOpacity(0.0),
    ]);
  }

  static Color complement(String roleId) => KagemaColors.roleComplement(roleId);
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// ✨ NEW: ANIMATED CARD WRAPPER - Lifts on hover/click
// ───────────────────────────────────────────────────────────────────────────────────────────
class AnimatedCardWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hoverElevation;
  final double tapElevation;
  final Duration animationDuration;

  const AnimatedCardWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.hoverElevation = 12,
    this.tapElevation = 6,
    this.animationDuration = KagemaMotion.fast,
  });

  @override
  State<AnimatedCardWrapper> createState() => _AnimatedCardWrapperState();
}

class _AnimatedCardWrapperState extends State<AnimatedCardWrapper> {
  bool _isHovered = false;
  bool _isPressed = false;

  double get _elevation {
    if (_isPressed) return widget.tapElevation;
    if (_isHovered) return widget.hoverElevation;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: widget.animationDuration,
          curve: KagemaMotion.gentleBounce,
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.98 : 1.0)
            ..translate(0, _isHovered ? -4 : 0),
          child: widget.child,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// ✨ NEW: SMART EMPTY STATE WIDGET
// ───────────────────────────────────────────────────────────────────────────────────────────
class SmartEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onAction;
  final String? actionLabel;

  const SmartEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final isMobile = context.isMobile;
    final color = iconColor ?? dt.textMuted;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 48,
          vertical: isMobile ? 40 : 60,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isMobile ? 80 : 100,
              height: isMobile ? 80 : 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.08),
              ),
              child: Icon(
                icon,
                size: isMobile ? 36 : 48,
                color: color.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.w800,
                color: dt.textPrimary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: dt.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KagemaColors.electric,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// ✨ NEW: ADAPTIVE RESPONSIVE GRID
// ───────────────────────────────────────────────────────────────────────────────────────────
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 4,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio = 1.2,
  });

  @override
  Widget build(BuildContext context) {
    final layout = context.kagemaLayout;
    int crossAxisCount;

    switch (layout) {
      case KagemaLayout.mobile:
        crossAxisCount = mobileColumns;
        break;
      case KagemaLayout.tablet:
        crossAxisCount = tabletColumns;
        break;
      case KagemaLayout.desktop:
      case KagemaLayout.wide:
        crossAxisCount = desktopColumns;
        break;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: runSpacing,
      childAspectRatio: childAspectRatio,
      children: children,
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// ✨ NEW: SHIMMER LOADING SKELETON
// ───────────────────────────────────────────────────────────────────────────────────────────
class ShimmerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// ✨ NEW: SECTION HEADER WITH ACTION
// ───────────────────────────────────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final roleColor = color ?? context.roleColor ?? KagemaColors.electric;
    final isMobile = context.isMobile;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: isMobile ? 14 : 18,
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                color: dt.textSecondary,
              ),
            ),
          ],
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: TextStyle(
                fontSize: isMobile ? 9 : 10,
                fontWeight: FontWeight.w800,
                color: roleColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// [REST OF YOUR EXISTING CODE - KEPT EXACTLY THE SAME]
// KagemaParticle, KagemaParticlePainter, RolePlasma, ChromaticBorderPainter,
// AISpectrumBorder, LiquidGlassCard, FrostGlassCard, NeuralBackground,
// RoleAuraLayer, ShimmerBox, AnimatedStatBadge, PrestigeThemeSwitcher,
// BreadcrumbNav, GradientAvatar, HoverScale, PressScale,
// GeminiThemeExtension, AppTheme, KagemaThemeX
// ───────────────────────────────────────────────────────────────────────────────────────────

// ───────── [YOUR EXISTING CODE CONTINUES HERE - KEPT UNCHANGED] ─────────
// (All the widgets from KagemaParticle through to the end remain exactly as you had them)

// ───────────────────────────────────────────────────────────────────────────────────────────
// LIVING PARTICLE with lifecycle
// ───────────────────────────────────────────────────────────────────────────────────────────
class KagemaParticle {
  double x, y, vx, vy, radius, opacity;
  double life;
  final double maxLife;
  final math.Random _rng = math.Random();

  KagemaParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
    this.life = 1.0,
    this.maxLife = 1.0,
  });

  bool get isAlive => life > 0;

  void update() {
    tick();
    life -= 0.0015 + _rng.nextDouble() * 0.001;
    if (life <= 0) {
      life = maxLife;
      x = _rng.nextDouble();
      y = _rng.nextDouble();
      radius = 1.0 + _rng.nextDouble() * 2.4;
      opacity = 0.25 + _rng.nextDouble() * 0.60;
    }
  }

  void tick() {
    x += vx; y += vy;
    if (x < 0) x = 1.0; if (x > 1) x = 0.0;
    if (y < 0) y = 1.0; if (y > 1) y = 0.0;
  }

  static List<KagemaParticle> generate({int count = 46, math.Random? rng}) {
    final r = rng ?? math.Random();
    return List.generate(count, (_) {
      final speed = 0.000065 + r.nextDouble() * 0.000125;
      final angle = r.nextDouble() * math.pi * 2;
      return KagemaParticle(
        x: r.nextDouble(), y: r.nextDouble(),
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        radius: 1.0 + r.nextDouble() * 2.4,
        opacity: 0.25 + r.nextDouble() * 0.60,
        life: 0.5 + r.nextDouble() * 0.5,
        maxLife: 0.5 + r.nextDouble() * 0.5,
      );
    });
  }
}

class KagemaParticlePainter extends CustomPainter {
  final List<KagemaParticle> particles;
  final Color color;
  final Color? accentColor;
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

      final lifeOpacity = p.life * (isDark ? 0.58 : 0.42);
      dot.color = c.withOpacity(p.opacity * lifeOpacity);
      canvas.drawCircle(Offset(px, py), p.radius * p.life, dot);

      for (int j = i + 1; j < particles.length; j++) {
        final q   = particles[j];
        final qx  = q.x * size.width;
        final qy  = q.y * size.height;
        final d   = math.sqrt(math.pow(px - qx, 2) + math.pow(py - qy, 2));
        final max = connectionDistance * size.width;
        if (d < max) {
          final a = (1.0 - d / max) *
              (isDark ? 0.24 : 0.14) *
              math.min(p.opacity, q.opacity) *
              math.min(p.life, q.life);
          line.color = c.withOpacity(a);
          canvas.drawLine(Offset(px, py), Offset(qx, qy), line);
        }
      }
    }
  }

  @override
  bool shouldRepaint(KagemaParticlePainter old) => true;
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// PLASMA RINGS
// ───────────────────────────────────────────────────────────────────────────────────────────
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
        ..color       = c.withOpacity(alpha)
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, r.clamp(0, maxR * 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(_PlasmaPainter old) => old.progress != progress;
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// CHROMATIC BORDER PAINTER
// ───────────────────────────────────────────────────────────────────────────────────────────
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

    canvas.drawRRect(
      rrect,
      Paint()
        ..strokeWidth = stroke + 8.0
        ..style       = PaintingStyle.stroke
        ..shader      = shader
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color       = c1.withOpacity(0.20 * pulse),
    );

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

// ───────────────────────────────────────────────────────────────────────────────────────────
// AI SPECTRUM BORDER
// ───────────────────────────────────────────────────────────────────────────────────────────
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

// ───────────────────────────────────────────────────────────────────────────────────────────
// LIQUID GLASS CARD
// ───────────────────────────────────────────────────────────────────────────────────────────
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
                widget.accentColor.withOpacity(0.18),
                widget.accentColor2.withOpacity(0.18),
                (widget.accentColor3 ?? widget.accentColor).withOpacity(0.18),
                widget.accentColor.withOpacity(0.18),
              ],
              transform: GradientRotation(_sweep.value * 2 * math.pi),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(isDark ? 0.18 : 0.09),
                blurRadius: 32 * widget.elevation,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.40 : 0.06),
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
                      (isDark ? KagemaColors.darkCard.withOpacity(0.94)
                          : Colors.white.withOpacity(0.96)),
                  borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderThickness),
                  border: Border.all(
                    color: dt.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Stack(
                  children: [
                    widget.child,
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
                            Colors.white.withOpacity(isDark ? 0.12 : 0.70),
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

// ───────────────────────────────────────────────────────────────────────────────────────────
// FROST GLASS CARD
// ───────────────────────────────────────────────────────────────────────────────────────────
class FrostGlassCard extends LiquidGlassCard {
  final double frostIntensity;

  const FrostGlassCard({
    super.key,
    required super.child,
    super.borderRadius = 28,
    super.accentColor = KagemaColors.electric,
    super.accentColor2 = KagemaColors.azure,
    super.accentColor3,
    super.backgroundColor,
    super.padding,
    super.useAIBorder = false,
    super.elevation = 1.0,
    this.frostIntensity = 0.7,
  });

  @override
  _FrostGlassCardState createState() => _FrostGlassCardState();
}

class _FrostGlassCardState extends State<FrostGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweep;
  late AnimationController _frostPulse;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _frostPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sweep.dispose();
    _frostPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt     = DT(isDark);

    return AnimatedBuilder(
      animation: Listenable.merge([_sweep, _frostPulse]),
      builder: (_, __) {
        final frostBlur = 20 * widget.frostIntensity * (0.8 + _frostPulse.value * 0.2);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              center: Alignment.center,
              colors: [
                widget.accentColor.withOpacity(0.18),
                widget.accentColor2.withOpacity(0.18),
                (widget.accentColor3 ?? widget.accentColor).withOpacity(0.18),
                widget.accentColor.withOpacity(0.18),
              ],
              transform: GradientRotation(_sweep.value * 2 * math.pi),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(isDark ? 0.18 : 0.09),
                blurRadius: 32 * widget.elevation,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.40 : 0.06),
                blurRadius: 24 * widget.elevation,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius - 1.3),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: frostBlur, sigmaY: frostBlur),
              child: Container(
                margin: const EdgeInsets.all(1.3),
                padding: widget.padding ?? const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ??
                      (isDark ? KagemaColors.darkCard.withOpacity(0.88)
                          : Colors.white.withOpacity(0.90)),
                  borderRadius: BorderRadius.circular(widget.borderRadius - 1.3),
                  border: Border.all(
                    color: dt.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Stack(
                  children: [
                    widget.child,
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.borderRadius - 1.3),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(isDark ? 0.02 : 0.08),
                                Colors.transparent,
                                Colors.white.withOpacity(isDark ? 0.02 : 0.05),
                              ],
                            ),
                          ),
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
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// NEURAL BACKGROUND
// ───────────────────────────────────────────────────────────────────────────────────────────
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
        for (final p in _particles) p.update();
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
            Container(
              color: widget.isDark ? KagemaColors.darkInk : KagemaColors.lightBase,
            ),

            if (widget.showBlobs) ...[
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.55, -0.4),
                      radius: 1.3 * aura,
                      colors: [
                        widget.primaryBlob.withOpacity(widget.isDark ? 0.11 : 0.06),
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
                        widget.secondaryBlob.withOpacity(widget.isDark ? 0.08 : 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top:   -180 + math.sin(t * 2 * math.pi) * 90,
                right: -160 + math.cos(t * 2 * math.pi) * 80,
                child: _Blob(
                  color: widget.primaryBlob.withOpacity(widget.isDark ? 0.08 : 0.04),
                  size: 680,
                ),
              ),
              Positioned(
                bottom: -220 + math.cos(t * 2 * math.pi) * 110,
                left:   -160 + math.sin(t * 2 * math.pi) * 85,
                child: _Blob(
                  color: widget.secondaryBlob.withOpacity(widget.isDark ? 0.08 : 0.04),
                  size: 820,
                ),
              ),
              Positioned(
                top:  MediaQuery.of(context).size.height * 0.4 +
                    math.sin(t * 4 * math.pi) * 60,
                left: MediaQuery.of(context).size.width * 0.5 +
                    math.cos(t * 3 * math.pi) * 80,
                child: _Blob(
                  color: Color.lerp(widget.primaryBlob, widget.secondaryBlob, 0.5)!
                      .withOpacity(widget.isDark ? 0.06 : 0.03),
                  size: 320,
                ),
              ),
            ],

            if (widget.showGrid)
              CustomPaint(
                size: Size.infinite,
                painter: _DriftingGridPainter(isDark: widget.isDark, t: t),
              ),

            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: const SizedBox.expand(),
            ),

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
          .withOpacity(isDark ? 0.016 : 0.012)
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

// ───────────────────────────────────────────────────────────────────────────────────────────
// ROLE AURA LAYER
// ───────────────────────────────────────────────────────────────────────────────────────────
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
                    widget.roleColor.withOpacity(
                        (widget.isDark ? 0.11 : 0.06) * _anim.value),
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

// ───────────────────────────────────────────────────────────────────────────────────────────
// SHIMMER BOX
// ───────────────────────────────────────────────────────────────────────────────────────────
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

// ───────────────────────────────────────────────────────────────────────────────────────────
// ANIMATED STAT BADGE
// ───────────────────────────────────────────────────────────────────────────────────────────
class AnimatedStatBadge extends StatefulWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const AnimatedStatBadge({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  State<AnimatedStatBadge> createState() => _AnimatedStatBadgeState();
}

class _AnimatedStatBadgeState extends State<AnimatedStatBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final isMobile = context.isMobile;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Transform.scale(
          scale: widget.isLoading ? 1.0 : 1.0 + _pulse.value * 0.025,
          child: Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color.withOpacity(0.08), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
              border: Border.all(
                color: widget.color.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.isLoading
                ? ShimmerBox(
              width: isMobile ? 60 : 80,
              height: isMobile ? 60 : 80,
              borderRadius: 12,
            )
                : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: isMobile ? 20 : 28,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 10),
                Text(
                  widget.value,
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    color: widget.color,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: isMobile ? 9 : 10,
                    fontWeight: FontWeight.w700,
                    color: dt.textMuted,
                    letterSpacing: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  margin: EdgeInsets.only(top: isMobile ? 4 : 8),
                  height: 2,
                  width: isMobile ? 20 : 30,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// PRESTIGE THEME SWITCHER
// ───────────────────────────────────────────────────────────────────────────────────────────
class PrestigeThemeSwitcher extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  final Color? activeColor;

  const PrestigeThemeSwitcher({
    super.key,
    required this.isDark,
    required this.onToggle,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? KagemaColors.electric;
    final dt = context.dt;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: KagemaMotion.normal,
        width: 60,
        height: 32,
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
            colors: [color, color.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isDark ? null : dt.cardBorder,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? color.withOpacity(0.2) : Colors.transparent,
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: KagemaMotion.normal,
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
              size: 14,
              color: isDark ? color : Colors.amber,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// BREADCRUMB NAVIGATION
// ───────────────────────────────────────────────────────────────────────────────────────────
class BreadcrumbNav extends StatelessWidget {
  final List<String> segments;
  final VoidCallback? onSegmentTap;

  const BreadcrumbNav({
    super.key,
    required this.segments,
    this.onSegmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final roleColor = KagemaColors.electric;
    final isMobile = context.isMobile;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: segments.asMap().entries.map((entry) {
          final index = entry.key;
          final segment = entry.value;
          final isLast = index == segments.length - 1;

          return Row(
            children: [
              GestureDetector(
                onTap: isLast ? null : onSegmentTap,
                child: Text(
                  segment.toUpperCase(),
                  style: TextStyle(
                    fontSize: isMobile ? 8 : 9,
                    fontWeight: FontWeight.w800,
                    color: isLast ? roleColor : dt.textMuted,
                    letterSpacing: 1,
                    decoration: isLast ? TextDecoration.underline : TextDecoration.none,
                    decorationColor: roleColor,
                    decorationThickness: 1.5,
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 12,
                    color: dt.textMuted.withOpacity(0.5),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// GRADIENT AVATAR
// ───────────────────────────────────────────────────────────────────────────────────────────
class GradientAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final bool showBadge;

  const GradientAvatar({
    super.key,
    required this.name,
    this.radius = 30,
    this.color,
    this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = color ?? KagemaColors.electric;
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isMobile = context.isMobile;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  roleColor,
                  roleColor.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: roleColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: radius * 0.85,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (showBadge)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: isMobile ? 10 : 12,
                height: isMobile ? 10 : 12,
                decoration: BoxDecoration(
                  color: KagemaColors.teacherGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// MICRO-INTERACTIONS
// ───────────────────────────────────────────────────────────────────────────────────────────
class HoverScale extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final Curve curve;

  const HoverScale({
    super.key,
    required this.child,
    this.scale = 1.03,
    this.duration = KagemaMotion.fast,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? widget.scale : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;
  final double hoverScale;
  final Duration duration;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.97,
    this.hoverScale = 1.03,
    this.duration = KagemaMotion.fast,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? widget.pressScale : (_isHovered ? widget.hoverScale : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────────────────
// GEMINI THEME EXTENSION
// ───────────────────────────────────────────────────────────────────────────────────────────
class GeminiThemeExtension extends ThemeExtension<GeminiThemeExtension> {
  final LinearGradient? primaryGradient;
  final LinearGradient? glowingBorderGradient;
  final Color? accentGlow;

  const GeminiThemeExtension({
    this.primaryGradient,
    this.glowingBorderGradient,
    this.accentGlow,
  });

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

  Widget buildFrostGlass({
    required Widget child,
    double borderRadius    = 28,
    Color? backgroundColor,
    EdgeInsets? padding,
    bool useAIBorder       = false,
    Color accentColor      = KagemaColors.electric,
    Color accentColor2     = KagemaColors.azure,
    Color? accentColor3,
    double elevation       = 1.0,
    double frostIntensity  = 0.7,
  }) {
    return FrostGlassCard(
      borderRadius:    borderRadius,
      backgroundColor: backgroundColor,
      padding:         padding,
      useAIBorder:     useAIBorder,
      accentColor:     accentColor,
      accentColor2:    accentColor2,
      accentColor3:    accentColor3,
      elevation:       elevation,
      frostIntensity:  frostIntensity,
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

// ───────────────────────────────────────────────────────────────────────────────────────────
// APP THEME
// ───────────────────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static BuildContext _getFallbackContext() {
    return _FallbackContext();
  }

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

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: TypographyScale.headlineLarge.resolve(_getFallbackContext()),
          letterSpacing: -2.5, color: dt.textPrimary, height: 1.0,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: TypographyScale.headlineMedium.resolve(_getFallbackContext()),
          letterSpacing: -1.5, color: dt.textPrimary, height: 1.05,
        ),
        displaySmall: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: TypographyScale.headlineSmall.resolve(_getFallbackContext()),
          letterSpacing: -1.0, color: dt.textPrimary, height: 1.1,
        ),
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: TypographyScale.headlineLarge.resolve(_getFallbackContext()),
          letterSpacing: -0.8, color: dt.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: TypographyScale.headlineMedium.resolve(_getFallbackContext()),
          letterSpacing: -0.4, color: dt.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: TypographyScale.headlineSmall.resolve(_getFallbackContext()),
          letterSpacing: -0.2, color: dt.textPrimary,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: TypographyScale.titleLarge.resolve(_getFallbackContext()),
          letterSpacing: 0.2, color: dt.textPrimary,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: TypographyScale.titleMedium.resolve(_getFallbackContext()),
          letterSpacing: 0.4, color: dt.textPrimary,
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: TypographyScale.titleMedium.resolve(_getFallbackContext()),
          letterSpacing: 0.3, color: dt.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: TypographyScale.bodyLarge.resolve(_getFallbackContext()),
          color: dt.textPrimary, height: 1.55,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: TypographyScale.bodyMedium.resolve(_getFallbackContext()),
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: TypographyScale.bodySmall.resolve(_getFallbackContext()),
          color: dt.textMuted, height: 1.5,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: TypographyScale.labelLarge.resolve(_getFallbackContext()),
          letterSpacing: 0.4, color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: TypographyScale.labelMedium.resolve(_getFallbackContext()),
          letterSpacing: 1.0, color: dt.textMuted,
        ),
        labelSmall: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: TypographyScale.labelSmall.resolve(_getFallbackContext()),
          letterSpacing: 2.0, color: dt.textMuted,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor:         Colors.transparent,
        elevation:               0,
        scrolledUnderElevation:  0,
        centerTitle:             true,
        iconTheme:               IconThemeData(color: dt.textPrimary, size: 22),
        actionsIconTheme:        IconThemeData(color: dt.textPrimary, size: 22),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: TypographyScale.titleLarge.resolve(_getFallbackContext()),
          letterSpacing: 2.2, color: dt.textPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        elevation:        0,
        color:            dt.cardBg,
        shadowColor:      Colors.black.withOpacity(isDark ? 0.4 : 0.07),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: dt.cardBorder, width: 1.2),
        ),
      ),

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

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KagemaColors.electric,
          foregroundColor: Colors.white,
          elevation:       0,
          shadowColor:     KagemaColors.electric.withOpacity(0.5),
          padding:         const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KagemaColors.electric,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dt.textPrimary,
          side: BorderSide(color: dt.cardBorderHi, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor:  dt.cardBg,
        selectedColor:    KagemaColors.electric.withOpacity(0.15),
        disabledColor:    dt.surfaceBg,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: dt.textPrimary),
        secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
        side:   BorderSide(color: dt.cardBorder, width: 1.2),
        shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        iconTheme: IconThemeData(color: dt.iconInactive, size: 16),
      ),

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

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:  dt.cardBg,
        indicatorColor:   KagemaColors.electric.withOpacity(0.14),
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

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:    dt.cardBg,
        selectedIconTheme:  const IconThemeData(color: KagemaColors.electric, size: 24),
        unselectedIconTheme: IconThemeData(color: dt.iconInactive, size: 22),
        selectedLabelTextStyle: const TextStyle(
            color: KagemaColors.electric, fontWeight: FontWeight.w800, fontSize: 11),
        unselectedLabelTextStyle: TextStyle(
            color: dt.textMuted, fontWeight: FontWeight.w600, fontSize: 11),
        indicatorColor: KagemaColors.electric.withOpacity(0.14),
        elevation: 0,
        groupAlignment: -0.8,
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: dt.cardBg,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: dt.divider, thickness: 1, space: 24,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: dt.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: TypographyScale.titleLarge.resolve(_getFallbackContext()),
          color: dt.textPrimary, letterSpacing: 0.2,
        ),
        contentTextStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: TypographyScale.bodyMedium.resolve(_getFallbackContext()),
          color: dt.textSecondary, height: 1.55,
        ),
        shadowColor: Colors.black.withOpacity(0.2),
        surfaceTintColor: Colors.transparent,
      ),

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

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? KagemaColors.darkCardAlt : const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        behavior:  SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actionTextColor: KagemaColors.electric,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? KagemaColors.electric : dt.iconInactive),
        trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected)
            ? KagemaColors.electric.withOpacity(0.38)
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
            KagemaColors.electric.withOpacity(0.08)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? KagemaColors.electric : dt.iconInactive),
        overlayColor: WidgetStateProperty.all(
            KagemaColors.electric.withOpacity(0.08)),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor:   KagemaColors.electric,
        inactiveTrackColor: dt.cardBorder,
        thumbColor:         KagemaColors.electric,
        overlayColor:       KagemaColors.electric.withOpacity(0.12),
        valueIndicatorColor: KagemaColors.electric,
        valueIndicatorTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700),
        trackHeight: 4,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:              KagemaColors.electric,
        linearTrackColor:   dt.cardBorder,
        circularTrackColor: dt.cardBorder,
        linearMinHeight:    6,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor:            KagemaColors.electric,
        unselectedLabelColor:  dt.textMuted,
        indicatorColor:        KagemaColors.electric,
        indicatorSize:         TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(
            KagemaColors.electric.withOpacity(0.06)),
      ),

      listTileTheme: ListTileThemeData(
        tileColor:          Colors.transparent,
        selectedTileColor:  KagemaColors.electric.withOpacity(0.08),
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

      iconTheme: IconThemeData(color: dt.iconActive, size: 22),
      primaryIconTheme: const IconThemeData(color: KagemaColors.electric, size: 22),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? KagemaColors.darkCardAlt : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12),
          ],
        ),
        textStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),

      badgeTheme: BadgeThemeData(
        backgroundColor: KagemaColors.rose,
        textColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        smallSize: 8,
        largeSize: 18,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: dt.cardBg,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: dt.cardBorder, width: 1.0),
        ),
        textStyle: TextStyle(
            color: dt.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
        surfaceTintColor: Colors.transparent,
      ),

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

// ───────────────────────────────────────────────────────────────────────────────────────────
// CONVENIENCE EXTENSION on BuildContext
// ───────────────────────────────────────────────────────────────────────────────────────────
extension KagemaThemeX on BuildContext {
  GeminiThemeExtension? get kagemaTheme =>
      Theme.of(this).extension<GeminiThemeExtension>();

  DT get dt => DT.of(this);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  double get pt => MediaQuery.of(this).padding.top;
  double get pb => MediaQuery.of(this).padding.bottom;

  Color get roleColor => KagemaColors.electric;
}