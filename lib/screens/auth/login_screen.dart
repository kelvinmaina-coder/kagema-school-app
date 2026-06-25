import '../../app_theme.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/authentication_service.dart';
import '../parent/parent_dashboard.dart';

// ─────────────────────────────────────────────────────────────────
// RESPONSIVE BREAKPOINTS HELPER
// ─────────────────────────────────────────────────────────────────
enum ScreenLayout { mobile, tablet, desktop }

extension LayoutHelper on BuildContext {
  ScreenLayout get layout {
    final w = MediaQuery.of(this).size.width;
    if (w >= 1100) return ScreenLayout.desktop;
    if (w >= 650) return ScreenLayout.tablet;
    return ScreenLayout.mobile;
  }

  bool get isMobile => layout == ScreenLayout.mobile;
  bool get isTablet => layout == ScreenLayout.tablet;
  bool get isDesktop => layout == ScreenLayout.desktop;

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}

// ─────────────────────────────────────────────────────────────────
// FEATURE #7 — TIME-AWARE GREETING HELPER
// ─────────────────────────────────────────────────────────────────
class _TimeGreeting {
  final String prefix;
  final String emoji;
  final String timeLabel;
  const _TimeGreeting({
    required this.prefix,
    required this.emoji,
    required this.timeLabel,
  });

  static _TimeGreeting get now {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return const _TimeGreeting(
        prefix: 'Good Morning,',
        emoji: '🌅',
        timeLabel: 'morning',
      );
    } else if (hour >= 12 && hour < 17) {
      return const _TimeGreeting(
        prefix: 'Good Afternoon,',
        emoji: '☀️',
        timeLabel: 'afternoon',
      );
    } else if (hour >= 17 && hour < 21) {
      return const _TimeGreeting(
        prefix: 'Good Evening,',
        emoji: '🌆',
        timeLabel: 'evening',
      );
    } else {
      return const _TimeGreeting(
        prefix: 'Good Night,',
        emoji: '🌙',
        timeLabel: 'night',
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// FEATURE #1 — PARTICLE DATA MODEL
// ─────────────────────────────────────────────────────────────────
class _Particle {
  double x, y, vx, vy, radius, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
  });

  void tick() {
    x += vx;
    y += vy;
    if (x < 0) x = 1.0;
    if (x > 1) x = 0.0;
    if (y < 0) y = 1.0;
    if (y > 1) y = 0.0;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double connectionDistance;
  final bool isDark;

  _ParticlePainter({
    required this.particles,
    required this.color,
    required this.connectionDistance,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8;

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final px = p.x * size.width;
      final py = p.y * size.height;

      dotPaint.color = color.withValues(alpha: p.opacity * (isDark ? 0.6 : 0.5));
      canvas.drawCircle(Offset(px, py), p.radius, dotPaint);

      for (int j = i + 1; j < particles.length; j++) {
        final q = particles[j];
        final qx = q.x * size.width;
        final qy = q.y * size.height;
        final dist = math.sqrt(
          math.pow(px - qx, 2) + math.pow(py - qy, 2),
        );
        final maxDist = connectionDistance * size.width;
        if (dist < maxDist) {
          final alpha = (1.0 - dist / maxDist) *
              (isDark ? 0.25 : 0.18) *
              math.min(p.opacity, q.opacity);
          linePaint.color = color.withValues(alpha: alpha);
          canvas.drawLine(Offset(px, py), Offset(qx, qy), linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────
// DARK-MODE TOKEN HELPER
// ─────────────────────────────────────────────────────────────────
class _DT {
  final bool dark;
  const _DT(this.dark);

  Color get pageBg => dark ? const Color(0xFF0F172A) : const Color(0xFFF0F4F8);
  Color get cardBg => dark ? const Color(0xFF1E293B) : Colors.white;
  Color get inputBg => dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
  Color get inputFocusBg =>
      dark ? const Color(0xFF243347) : const Color(0xFFF8FAFC);
  Color get textPrimary =>
      dark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
  Color get textMuted =>
      dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  Color get hint => dark ? const Color(0xFF475569) : const Color(0xFFCDD5DE);
  Color get iconInactive =>
      dark ? const Color(0xFF475569) : const Color(0xFFB0BFCF);
  Color get cardBorder =>
      dark ? const Color(0xFF334155) : const Color(0xFFE8EDF2);
  Color get roleLabelMuted =>
      dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  Color get roleIconBg =>
      dark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  Color get footerPillBg =>
      dark ? const Color(0xFF1E293B) : Colors.white;
  Color get footerPillBorder =>
      dark ? const Color(0xFF334155) : const Color(0xFFE8EDF2);
  Color get footerText =>
      dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get sectionLabel =>
      dark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
  Color aura(Color roleColor) =>
      roleColor.withValues(alpha: dark ? 0.07 : 0.045);
  Color get desktopRightBg =>
      dark ? const Color(0xFF0F172A) : const Color(0xFFF0F4F8);
}

// ─────────────────────────────────────────────────────────────────
// LOGIN SCREEN
// ─────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  String selectedRole = 'ADMIN';
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;
  Map<String, dynamic>? cachedUser; // Personalized "Welcome Back"

  // ── Entry animations ────────────────────────────────────────────
  late AnimationController _headerAnimController;
  late AnimationController _cardAnimController;
  late AnimationController _formAnimController;
  late AnimationController _pulseController;

  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _pulseAnim;

  // ── FEATURE #1 — Particle animation controller ──────────────────
  late AnimationController _particleController;
  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();

  // ── FEATURE #5 — Aura animation controller ──────────────────────
  late AnimationController _auraController;
  late Animation<double> _auraAnim;

  // ── Focus nodes ─────────────────────────────────────────────────
  final FocusNode _idFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  bool _idFocused = false;
  bool _passFocused = false;

  // ── Role data ───────────────────────────────────────────────────
  final List<Map<String, dynamic>> roles = [
    {
      'title': 'ADMIN',
      'label': 'Admin',
      'icon': Icons.shield_rounded,
      'bgIcon': Icons.admin_panel_settings_rounded,
      'color': const Color(0xFFFF4D00),
      'lightColor': const Color(0xFFFFF0EB),
      'darkLightColor': const Color(0xFF2A1A10),
      'id': 'admin',
      'hint': 'Email or Admin ID',
      'roleName': 'Admin',
      'emoji': '👑',
      'sub': 'Manage your school from one powerful dashboard.',
      'accountLabel': 'your Admin account',
      'badge': 'Full Access',
    },
    {
      'title': 'TEACHER',
      'label': 'Teacher',
      'icon': Icons.school_rounded,
      'bgIcon': Icons.menu_book_rounded,
      'color': const Color(0xFF10B981),
      'lightColor': const Color(0xFFEBFAF4),
      'darkLightColor': const Color(0xFF0A2419),
      'id': 'teacher',
      'hint': 'Staff ID',
      'roleName': 'Teacher',
      'emoji': '🎓',
      'sub': 'Your students are ready for today.',
      'accountLabel': 'your Teacher account',
      'badge': 'Educator',
    },
    {
      'title': 'PARENT',
      'label': 'Parent',
      'icon': Icons.family_restroom_rounded,
      'bgIcon': Icons.child_care_rounded,
      'color': const Color(0xFFEF4444),
      'lightColor': const Color(0xFFFEF0F0),
      'darkLightColor': const Color(0xFF2A0E0E),
      'id': 'parent',
      'hint': 'Phone Number',
      'roleName': 'Parent',
      'emoji': '❤️',
      'sub': 'Track your child\'s progress and stay connected.',
      'accountLabel': 'your Parent account',
      'badge': 'Guardian',
    },
    {
      'title': 'ACCOUNTANT',
      'label': 'Accountant',
      'icon': Icons.account_balance_wallet_rounded,
      'bgIcon': Icons.bar_chart_rounded,
      'color': const Color(0xFFF59E0B),
      'lightColor': const Color(0xFFFEF9EB),
      'darkLightColor': const Color(0xFF2A2005),
      'id': 'accountant',
      'hint': 'Treasury ID',
      'roleName': 'Accountant',
      'emoji': '💰',
      'sub': 'Finance reports and records await you.',
      'accountLabel': 'your Accountant account',
      'badge': 'Finance',
    },
    {
      'title': 'SECRETARY',
      'label': 'Secretary',
      'icon': Icons.assignment_ind_rounded,
      'bgIcon': Icons.event_note_rounded,
      'color': const Color(0xFF8B5CF6),
      'lightColor': const Color(0xFFF3EFFE),
      'darkLightColor': const Color(0xFF1A1030),
      'id': 'secretary',
      'hint': 'Office ID',
      'roleName': 'Secretary',
      'emoji': '📋',
      'sub': 'Manage schedules and keep things running smoothly.',
      'accountLabel': 'your Secretary account',
      'badge': 'Operations',
    },
    {
      'title': 'STAFF',
      'label': 'Staff',
      'icon': Icons.badge_rounded,
      'bgIcon': Icons.groups_rounded,
      'color': const Color(0xFF0EA5E9),
      'lightColor': const Color(0xFFEBF7FE),
      'darkLightColor': const Color(0xFF0A1E2A),
      'id': 'staff',
      'hint': 'Staff ID',
      'roleName': 'Staff',
      'emoji': '🌟',
      'sub': 'Your tasks and schedule are ready for you.',
      'accountLabel': 'your Staff account',
      'badge': 'Team Member',
    },
  ];

  Map<String, dynamic> get activeRole =>
      roles.firstWhere((r) => r['title'] == selectedRole);
  Color get activeColor => activeRole['color'] as Color;
  Color activeLightColor(bool dark) => dark
      ? activeRole['darkLightColor'] as Color
      : activeRole['lightColor'] as Color;

  // ── FEATURE #7 — cached time greeting ──────────────────────────
  final _TimeGreeting _timeGreeting = _TimeGreeting.now;

  String _buildGreeting() {
    if (cachedUser != null) {
      return 'Welcome Back, ${cachedUser!['name']}!';
    }
    return '${_timeGreeting.prefix} ${activeRole['roleName']}!';
  }

  String _buildGreetingEmoji() => _timeGreeting.emoji;

  String _buildSub() {
    final hour = DateTime.now().hour;
    String timeSuffix = '';
    if (hour >= 5 && hour < 12) timeSuffix = 'Have a great morning ahead.';
    else if (hour >= 12 && hour < 17) timeSuffix = 'Hope your afternoon is productive.';
    else if (hour >= 17 && hour < 21) timeSuffix = 'Wrapping up a great day?';
    else timeSuffix = 'Working late — we\'ve got you covered.';
    return '${activeRole['sub']}\n$timeSuffix';
  }

  // ── FEATURE #1 — build particle list ────────────────────────────
  void _initParticles({int count = 38}) {
    _particles.clear();
    for (int i = 0; i < count; i++) {
      final speed = 0.00008 + _rng.nextDouble() * 0.00014;
      final angle = _rng.nextDouble() * math.pi * 2;
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        radius: 1.2 + _rng.nextDouble() * 2.0,
        opacity: 0.3 + _rng.nextDouble() * 0.55,
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    _checkCachedUser(); // Personalize the experience immediately

    // Entry animations
    _headerAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _formAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    _headerFade =
        CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
        begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _headerAnimController, curve: Curves.easeOutCubic));

    _cardFade =
        CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
        begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _cardAnimController, curve: Curves.easeOutCubic));

    _formFade =
        CurvedAnimation(parent: _formAnimController, curve: Curves.easeOut);
    _formSlide = Tween<Offset>(
        begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _formAnimController, curve: Curves.easeOutCubic));

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Staggered entry
    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 200),
            () => _cardAnimController.forward());
    Future.delayed(const Duration(milliseconds: 400),
            () => _formAnimController.forward());

    // FEATURE #1 — particle ticker
    _initParticles();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
      for (final p in _particles) {
        p.tick();
      }
      setState(() {});
    })
      ..repeat();

    // FEATURE #5 — aura pulse
    _auraController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _auraAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _auraController, curve: Curves.easeInOut));

    // Focus listeners
    _idFocus.addListener(() => setState(() => _idFocused = _idFocus.hasFocus));
    _passFocus
        .addListener(() => setState(() => _passFocused = _passFocus.hasFocus));
  }

  Future<void> _checkCachedUser() async {
    final auth = Provider.of<AuthenticationService>(context, listen: false);
    final profile = await auth.getCachedProfile();
    if (profile != null && mounted) {
      setState(() {
        cachedUser = profile;
        // Auto-select the role they used last for flexibility
        selectedRole = profile['role']?.toString().toUpperCase() ?? 'ADMIN';
        identifierController.text = profile['phone'] ?? profile['id'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _cardAnimController.dispose();
    _formAnimController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _auraController.dispose();
    _idFocus.dispose();
    _passFocus.dispose();
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _switchRole(String roleTitle) {
    setState(() => selectedRole = roleTitle);
    identifierController.clear();
    passwordController.clear();
    _formAnimController.reset();
    _formAnimController.forward();
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = _DT(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _auraAnim,
        builder: (context, child) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: dt.pageBg,
                ),
              ),
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: layout == ScreenLayout.desktop
                          ? const Alignment(0.4, -0.2)
                          : const Alignment(0.0, -0.6),
                      radius: 1.1,
                      colors: [
                        activeColor.withValues(
                            alpha: (isDark ? 0.09 : 0.055) *
                                _auraAnim.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      color: activeColor,
                      connectionDistance: 0.18,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: layout == ScreenLayout.desktop
                    ? _buildDesktopLayout(dt)
                    : layout == ScreenLayout.tablet
                    ? _buildTabletLayout(dt)
                    : _buildMobileLayout(dt),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // MOBILE LAYOUT
  // ─────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(_DT dt) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: _buildHeroHeader(compact: false, dt: dt),
            ),
          ),
          FadeTransition(
            opacity: _cardFade,
            child: SlideTransition(
              position: _cardSlide,
              child: _buildRoleSection(crossAxisCount: 3, dt: dt),
            ),
          ),
          FadeTransition(
            opacity: _formFade,
            child: SlideTransition(
              position: _formSlide,
              child: _buildAuthSection(dt: dt),
            ),
          ),
          const SizedBox(height: 28),
          _buildFooter(dt),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TABLET LAYOUT
  // ─────────────────────────────────────────────────────────────────
  Widget _buildTabletLayout(_DT dt) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: _buildHeroHeader(compact: true, dt: dt),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: _buildRoleSection(
                          crossAxisCount: 2, padded: false, dt: dt),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 5,
                  child: FadeTransition(
                    opacity: _formFade,
                    child: SlideTransition(
                      position: _formSlide,
                      child: _buildAuthSection(padded: false, dt: dt),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(dt),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // DESKTOP LAYOUT
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(_DT dt) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: _buildDesktopHeroPanel(dt),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Container(
            color: Colors.transparent,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(36, 36, 36, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KAGEMA SCHOOL — INTELLIGENT EDUCATION HUB',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: activeColor,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: _buildRoleSection(
                          crossAxisCount: 3, padded: false, dt: dt),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _formFade,
                    child: SlideTransition(
                      position: _formSlide,
                      child: _buildAuthSection(padded: false, dt: dt),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildFooter(dt),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // DESKTOP HERO PANEL
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDesktopHeroPanel(_DT dt) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [activeColor, activeColor.withValues(alpha: 0.80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRect(
                child: CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    color: Colors.white,
                    connectionDistance: 0.30,
                    isDark: true,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -30,
            top: 60,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Icon(
                activeRole['bgIcon'] as IconData,
                key: ValueKey('bg_${activeRole['id']}'),
                size: 220,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: 120,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(Icons.hub_rounded, size: 34, color: activeColor),
                ),
                const SizedBox(height: 24),
                const Text(
                  'KAGEMA\nSCHOOL',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.05,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'INTELLIGENT EDUCATION HUB',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.65),
                    letterSpacing: 2.5,
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey('badge_${activeRole['id']}'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Text(
                      activeRole['badge'],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                          begin: const Offset(0, 0.2), end: Offset.zero)
                          .animate(anim),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey('greet_${activeRole['id']}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _buildGreeting(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ScaleTransition(
                            scale: _pulseAnim,
                            child: Text(
                              _buildGreetingEmoji(),
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _buildSub(),
                    key: ValueKey('sub_${activeRole['id']}_${_timeGreeting.timeLabel}'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Connection secured & encrypted',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Empowering education.\nEnabling excellence.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HERO HEADER (mobile + tablet)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeroHeader({required bool compact, required _DT dt}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [activeColor, activeColor.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                child: CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    color: Colors.white,
                    connectionDistance: 0.28,
                    isDark: true,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: -10,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Icon(
                activeRole['bgIcon'] as IconData,
                key: ValueKey('bg_${activeRole['id']}'),
                size: compact ? 130 : 160,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: compact ? 90 : 120,
              height: compact ? 90 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -20,
            child: Container(
              width: compact ? 50 : 70,
              height: compact ? 50 : 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                24, compact ? 18 : 24, 24, compact ? 22 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(compact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.hub_rounded,
                          size: compact ? 22 : 26, color: activeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KAGEMA SCHOOL',
                            style: TextStyle(
                              fontSize: compact ? 15 : 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'INTELLIGENT EDUCATION HUB',
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.75),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey('badge_${activeRole['id']}'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1),
                        ),
                        child: Text(
                          activeRole['badge'],
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 16 : 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                          begin: const Offset(0, 0.2), end: Offset.zero)
                          .animate(anim),
                      child: child,
                    ),
                  ),
                  child: Row(
                    key: ValueKey(
                        'greet_${activeRole['id']}_${_timeGreeting.timeLabel}'),
                    children: [
                      Flexible(
                        child: Text(
                          _buildGreeting(),
                          style: TextStyle(
                            fontSize: compact ? 20 : 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Text(
                          _buildGreetingEmoji(),
                          style: TextStyle(fontSize: compact ? 20 : 26),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _buildSub(),
                      key: ValueKey(
                          'sub_${activeRole['id']}_${_timeGreeting.timeLabel}'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // ROLE SELECTOR SECTION
  // ─────────────────────────────────────────────────────────────────
  Widget _buildRoleSection({
    required int crossAxisCount,
    bool padded = true,
    required _DT dt,
  }) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'SELECT ACCESS LEVEL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: dt.sectionLabel,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            'Choose your role to continue',
            style: TextStyle(fontSize: 11.5, color: dt.textMuted),
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: crossAxisCount == 2 ? 1.05 : 0.95,
          ),
          itemCount: roles.length,
          itemBuilder: (context, index) => _buildRoleCard(roles[index], dt),
        ),
      ],
    );

    if (padded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: content,
      );
    }
    return content;
  }

  Widget _buildRoleCard(Map<String, dynamic> role, _DT dt) {
    final isSelected = selectedRole == role['title'];
    final roleColor = role['color'] as Color;
    final roleLightColor = activeLightColor(dt.dark);

    return GestureDetector(
      onTap: () => _switchRole(role['title']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? roleLightColor : dt.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? roleColor : dt.cardBorder,
            width: isSelected ? 2.2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? roleColor.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: dt.dark ? 0.2 : 0.05),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: isSelected
                    ? roleColor.withValues(alpha: 0.18)
                    : dt.roleIconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                role['icon'] as IconData,
                color: isSelected ? roleColor : dt.iconInactive,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isSelected ? roleColor : dt.roleLabelMuted,
                letterSpacing: 0.4,
              ),
              child: Text(role['label']),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSelected ? 20 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // AUTH FORM SECTION — with role‑color animated border on the outer card
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAuthSection({bool padded = true, required _DT dt}) {
    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: dt.cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: activeColor,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: dt.dark ? 0.2 : 0.12),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dt.dark ? 0.3 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormHeader(dt),
            const SizedBox(height: 26),
            _buildBorderlessInput(
              focus: _idFocus,
              isFocused: _idFocused,
              icon: Icons.fingerprint_rounded,
              label: 'IDENTIFICATION',
              hint: activeRole['hint'],
              controller: identifierController,
              dt: dt,
            ),
            const SizedBox(height: 18),
            _buildBorderlessInput(
              focus: _passFocus,
              isFocused: _passFocused,
              icon: Icons.lock_person_rounded,
              label: 'ACCESS KEY',
              hint: 'Enter your password',
              controller: passwordController,
              isPass: true,
              dt: dt,
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {},
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: activeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            _buildLoginButton(),
          ],
        ),
      ),
    );

    if (padded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: content,
      );
    }
    return Padding(padding: const EdgeInsets.only(top: 20), child: content);
  }

  Widget _buildFormHeader(_DT dt) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.lock_open_rounded, color: activeColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOGIN TO YOUR ACCOUNT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: dt.textPrimary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'Sign in to access ${activeRole['accountLabel']}',
                  key: ValueKey('formSub_${activeRole['id']}'),
                  style: TextStyle(fontSize: 12, color: dt.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── ✅ COMPLETELY BORDERLESS INPUT – NO RED BOX ──────────────
  Widget _buildBorderlessInput({
    required FocusNode focus,
    required bool isFocused,
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPass = false,
    required _DT dt,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isFocused ? activeColor : dt.textMuted,
              letterSpacing: 1.4,
            ),
            child: Text(label),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isFocused ? dt.inputFocusBg : dt.inputBg,
            borderRadius: BorderRadius.circular(18),
            // ─── NO BORDER AT ALL ───
            border: Border.all(
              color: Colors.transparent,
              width: 0,
            ),
            boxShadow: isFocused
                ? [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),
              Icon(
                icon,
                color: isFocused ? activeColor : dt.iconInactive,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focus,
                  obscureText: isPass && !isPasswordVisible,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: dt.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: dt.hint,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              if (isPass)
                GestureDetector(
                  onTap: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isPasswordVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        key: ValueKey(isPasswordVisible),
                        size: 22,
                        color: dt.iconInactive,
                      ),
                    ),
                  ),
                ),
              if (!isPass) const SizedBox(width: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            activeColor,
            HSLColor.fromColor(activeColor)
                .withLightness(
                (HSLColor.fromColor(activeColor).lightness + 0.08)
                    .clamp(0.0, 1.0))
                .toColor(),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: activeColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isLoading ? null : _handleLogin,
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Center(
            child: isLoading
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                ),
                const SizedBox(width: 14),
                Text(
                  'Authenticating...',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                  ),
                ),
              ],
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_open_rounded,
                    color: Colors.white, size: 22),
                SizedBox(width: 12),
                Text(
                  'Secure Sign In',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 17,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildFooter(_DT dt) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: dt.footerPillBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: dt.footerPillBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dt.dark ? 0.2 : 0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.security_update_good_rounded,
                      size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    'Offline-Ready Secure System',
                    style: TextStyle(
                      fontSize: 11,
                      color: dt.footerText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Empowering education. Enabling excellence.',
          style: TextStyle(fontSize: 11, color: dt.textMuted),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // LOGIN HANDLER
  // ─────────────────────────────────────────────────────────────────
  void _handleLogin() async {
    setState(() => isLoading = true);
    final authService =
    Provider.of<AuthenticationService>(context, listen: false);
    final roleData = roles.firstWhere((r) => r['title'] == selectedRole);
    final success = await authService.login(
      roleData['id'],
      identifierController.text.trim(),
      passwordController.text,
    );
    if (mounted) {
      setState(() => isLoading = false);
      if (success) {
        if (roleData['id'] == 'parent') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ParentDashboard(
                  parentPhone: identifierController.text.trim()),
            ),
          );
        } else {
          Navigator.pushReplacementNamed(
              context, '/${roleData['id']}_dashboard');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                const Text('Invalid credentials or connection. Fallback failed.',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: activeColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
