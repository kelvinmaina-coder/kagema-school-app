import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/authentication_service.dart';
import '../parent/parent_dashboard.dart';

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

  final FocusNode _idFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  bool _idFocused = false;
  bool _passFocused = false;

  final List<Map<String, dynamic>> roles = [
    {
      'title': 'ADMIN',
      'label': 'Admin',
      'icon': Icons.shield_rounded,
      'bgIcon': Icons.admin_panel_settings_rounded,
      'color': const Color(0xFFFF4D00),
      'lightColor': const Color(0xFFFFF0EB),
      'id': 'admin',
      'hint': 'Email or Admin ID',
      'greeting': 'Hello, Admin!',
      'emoji': '👑',
      'sub': 'Welcome back. Manage your school\nfrom one powerful dashboard.',
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
      'id': 'teacher',
      'hint': 'Staff ID',
      'greeting': 'Hello, Teacher!',
      'emoji': '🎓',
      'sub': 'Welcome back. Your students\nare ready for today.',
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
      'id': 'parent',
      'hint': 'Phone Number',
      'greeting': 'Hello, Parent!',
      'emoji': '❤️',
      'sub': 'Welcome back. Track your child\'s\nprogress and stay connected.',
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
      'id': 'accountant',
      'hint': 'Treasury ID',
      'greeting': 'Hello, Accountant!',
      'emoji': '💰',
      'sub': 'Welcome back. Finance reports\nand records await you.',
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
      'id': 'secretary',
      'hint': 'Office ID',
      'greeting': 'Hello, Secretary!',
      'emoji': '📋',
      'sub': 'Welcome back. Manage schedules\nand keep things running smoothly.',
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
      'id': 'staff',
      'hint': 'Staff ID',
      'greeting': 'Hello, Staff!',
      'emoji': '🌟',
      'sub': 'Welcome back. Your tasks and\nschedule are ready for you.',
      'accountLabel': 'your Staff account',
      'badge': 'Team Member',
    },
  ];

  Map<String, dynamic> get activeRole =>
      roles.firstWhere((r) => r['title'] == selectedRole);
  Color get activeColor => activeRole['color'] as Color;
  Color get activeLightColor => activeRole['lightColor'] as Color;

  @override
  void initState() {
    super.initState();

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

    _idFocus.addListener(() => setState(() => _idFocused = _idFocus.hasFocus));
    _passFocus
        .addListener(() => setState(() => _passFocused = _passFocus.hasFocus));
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _cardAnimController.dispose();
    _formAnimController.dispose();
    _pulseController.dispose();
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
    // Re-animate form on role switch
    _formAnimController.reset();
    _formAnimController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── HERO HEADER ──────────────────────────────────
              FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: _buildHeroHeader(),
                ),
              ),
              const SizedBox(height: 0),
              // ── ROLE SELECTOR ────────────────────────────────
              FadeTransition(
                opacity: _cardFade,
                child: SlideTransition(
                  position: _cardSlide,
                  child: _buildRoleSection(),
                ),
              ),
              // ── AUTH FORM ────────────────────────────────────
              FadeTransition(
                opacity: _formFade,
                child: SlideTransition(
                  position: _formSlide,
                  child: _buildAuthSection(),
                ),
              ),
              const SizedBox(height: 28),
              _buildFooter(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HERO HEADER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            activeColor,
            activeColor.withValues(alpha: 0.82),
          ],
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
          // Decorative large faded background icon
          Positioned(
            right: -10,
            top: -10,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Icon(
                activeRole['bgIcon'] as IconData,
                key: ValueKey('bg_${activeRole['id']}'),
                size: 160,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
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
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar: logo + school name + badge
                Row(
                  children: [
                    // Logo bubble
                    Container(
                      padding: const EdgeInsets.all(10),
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
                          size: 26, color: activeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KAGEMA SCHOOL',
                            style: TextStyle(
                              fontSize: 17,
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
                    // Access badge
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
                const SizedBox(height: 28),
                // Greeting
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
                    key: ValueKey('greet_${activeRole['id']}'),
                    children: [
                      Text(
                        activeRole['greeting'],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Text(
                          activeRole['emoji'],
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    activeRole['sub'],
                    key: ValueKey('sub_${activeRole['id']}'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
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
  // ROLE SELECTOR SECTION
  // ─────────────────────────────────────────────────────────────────
  Widget _buildRoleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
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
              const Text(
                'SELECT ACCESS LEVEL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Text(
              'Choose your role to continue',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: roles.length,
            itemBuilder: (context, index) => _buildRoleCard(roles[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    final isSelected = selectedRole == role['title'];
    final roleColor = role['color'] as Color;
    final roleLightColor = role['lightColor'] as Color;

    return GestureDetector(
      onTap: () => _switchRole(role['title']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? roleLightColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? roleColor : const Color(0xFFE8EDF2),
            width: isSelected ? 2.2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? roleColor.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.05),
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
                    ? roleColor.withValues(alpha: 0.15)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                role['icon'] as IconData,
                color: isSelected ? roleColor : const Color(0xFFB0BFCF),
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isSelected ? roleColor : const Color(0xFF94A3B8),
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
  // AUTH FORM SECTION
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAuthSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form header
              _buildFormHeader(),
              const SizedBox(height: 22),
              // Identifier input
              _buildSmartInput(
                focus: _idFocus,
                isFocused: _idFocused,
                icon: Icons.fingerprint_rounded,
                label: 'IDENTIFICATION',
                hint: activeRole['hint'],
                controller: identifierController,
              ),
              const SizedBox(height: 14),
              // Password input
              _buildSmartInput(
                focus: _passFocus,
                isFocused: _passFocused,
                icon: Icons.lock_person_rounded,
                label: 'ACCESS KEY',
                hint: 'Enter your password',
                controller: passwordController,
                isPass: true,
              ),
              const SizedBox(height: 10),
              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {},
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: activeColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              // Login button
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.lock_open_rounded, color: activeColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LOGIN TO YOUR ACCOUNT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'Sign in to access ${activeRole['accountLabel']}',
                  key: ValueKey('formSub_${activeRole['id']}'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmartInput({
    required FocusNode focus,
    required bool isFocused,
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPass = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: isFocused
            ? activeColor.withValues(alpha: 0.03)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFocused
              ? activeColor
              : activeColor.withValues(alpha: 0.25),
          width: isFocused ? 2 : 1.5,
        ),
        boxShadow: isFocused
            ? [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              icon,
              color: isFocused ? activeColor : const Color(0xFFB0BFCF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: isFocused ? activeColor : const Color(0xFFB0BFCF),
                    letterSpacing: 1.8,
                  ),
                  child: Text(label),
                ),
                const SizedBox(height: 3),
                TextField(
                  controller: controller,
                  focusNode: focus,
                  obscureText: isPass && !isPasswordVisible,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFFCDD5DE),
                        fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
          ),
          if (isPass)
            GestureDetector(
              onTap: () =>
                  setState(() => isPasswordVisible = !isPasswordVisible),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  key: ValueKey(isPasswordVisible),
                  size: 20,
                  color: const Color(0xFFB0BFCF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            color: activeColor.withValues(alpha: 0.4),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: activeColor.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isLoading ? null : _handleLogin,
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Center(
            child: isLoading
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                ),
                const SizedBox(width: 12),
                Text(
                  'Authenticating...',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_open_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Secure Sign In',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 0.4,
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
  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFE8EDF2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
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
                  const Icon(Icons.security_rounded,
                      size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  const Text(
                    'Your connection is secure & encrypted',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Empowering education. Enabling excellence.',
          style: TextStyle(fontSize: 11, color: Color(0xFFB0BFCF)),
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
                const Text('Invalid credentials. Please try again.',
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