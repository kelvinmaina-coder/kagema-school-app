import 'student_management_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'app_theme.dart';
import 'screens/settings/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kagema School',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeLoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryTeal, AppTheme.primaryDark],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child:
                  const Icon(Icons.school, size: 70, color: Colors.white),
                ),
                const SizedBox(height: 30),
                const Text(
                  'KAGEMA COMPREHENSIVE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'School Management System',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== HOME LOGIN SCREEN (Role + Login on one page) ====================
class HomeLoginScreen extends StatefulWidget {
  const HomeLoginScreen({super.key});

  @override
  State<HomeLoginScreen> createState() => _HomeLoginScreenState();
}

class _HomeLoginScreenState extends State<HomeLoginScreen>
    with TickerProviderStateMixin {
  String? selectedRole;
  bool isPasswordVisible = false;
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Roles list — no Student (students don't have phones in school!)
  final List<Map<String, dynamic>> roles = const [
    {
      'title': 'Administration',
      'icon': Icons.admin_panel_settings,
      'emoji': '🏫',
      'sub': 'Headmaster • Deputy • BOM',
      'color': Color(0xFF5C6BC0),
    },
    {
      'title': 'Teacher',
      'icon': Icons.school,
      'emoji': '📚',
      'sub': 'Class Teacher • Subject Teacher',
      'color': Color(0xFF26A69A),
    },
    {
      'title': 'Parent',
      'icon': Icons.family_restroom,
      'emoji': '👨‍👩‍👧',
      'sub': 'Mother • Father • Guardian',
      'color': Color(0xFFEF5350),
    },
    {
      'title': 'Accountant',
      'icon': Icons.calculate,
      'emoji': '💰',
      'sub': 'Finance Officer • Bursar',
      'color': Color(0xFFFF7043),
    },
    {
      'title': 'Staff',
      'icon': Icons.work,
      'emoji': '🔧',
      'sub': 'Librarian • Nurse • Chef • Driver',
      'color': Color(0xFF66BB6A),
    },
    {
      'title': 'Secretary',
      'icon': Icons.assignment,
      'emoji': '📋',
      'sub': 'School Secretary • Admin Assistant',
      'color': Color(0xFFAB47BC),
    },
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your role first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (identifierController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your ID/Email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _getDashboard(selectedRole!)),
    );
  }

  Color get _selectedColor {
    if (selectedRole == null) return AppTheme.primaryTeal;
    return roles.firstWhere((r) => r['title'] == selectedRole)['color'] as Color;
  }

  Widget _getDashboard(String role) {
    switch (role) {
      case 'Administration':
        return const AdminDashboard();
      case 'Teacher':
        return const TeacherDashboard();
      case 'Parent':
        return const ParentDashboard();
      case 'Accountant':
        return const AccountantDashboard();
      case 'Staff':
        return const StaffDashboard();
      case 'Secretary':
        return const SecretaryDashboard();
      default:
        return const AdminDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // ── School Logo & Name ──
                  _buildHeader(),

                  const SizedBox(height: 24),

                  // ── Role Selection Card ──
                  _buildRoleCard(),

                  const SizedBox(height: 20),

                  // ── Login Form Card ──
                  _buildLoginCard(),

                  const SizedBox(height: 16),

                  Text(
                    '© 2026 Kagema Comprehensive School',
                    style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated school icon
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (_, val, child) =>
              Transform.scale(scale: val, child: child),
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryTeal,
                  AppTheme.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryTeal.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.school, size: 48, color: Colors.white),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'KAGEMA COMPREHENSIVE',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A3A5C),
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'School Management System',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.primaryTeal,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge_outlined, color: AppTheme.primaryTeal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Select Your Role',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tap your role to continue',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final double tileWidth = (constraints.maxWidth - 20) / 3;
                const double tileHeight = 82;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: roles.map((role) {
                    final bool isSelected = selectedRole == role['title'];
                    final Color roleColor = role['color'] as Color;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedRole = role['title'] as String);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: tileWidth,
                        height: tileHeight,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? roleColor.withOpacity(0.12)
                              : const Color(0xFFF5F8FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? roleColor : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: roleColor.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? roleColor.withOpacity(0.2)
                                    : roleColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                role['icon'] as IconData,
                                size: 20,
                                color: roleColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              role['title'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? roleColor
                                    : const Color(0xFF1A3A5C),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: _selectedColor.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.waving_hand_rounded,
                      color: _selectedColor, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back! 👋',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C),
                      ),
                    ),
                    Text(
                      selectedRole != null
                          ? 'Sign in as $selectedRole'
                          : 'Select a role above first',
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedRole != null
                            ? _selectedColor
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ID / Email field
            _buildTextField(
              controller: identifierController,
              hint: 'Enter ID or Email',
              icon: Icons.person_outline_rounded,
              accentColor: _selectedColor,
            ),
            const SizedBox(height: 14),

            // Password field
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle:
                TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.lock_outline_rounded,
                    color: _selectedColor, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F8FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                  BorderSide(color: _selectedColor, width: 1.5),
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),

            const SizedBox(height: 10),

            // Forgot password / Sign up row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen()),
                  ),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0)),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                        color: _selectedColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0)),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                        color: _selectedColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: _selectedColor.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        selectedRole != null
                            ? 'LOGIN AS ${selectedRole!.toUpperCase()}'
                            : 'LOGIN',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color accentColor,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F8FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}

// ==================== SIGNUP SCREEN ====================
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  String selectedRole = 'Parent';
  final List<String> roles = [
    'Administration',
    'Teacher',
    'Parent',
    'Accountant',
    'Staff',
    'Secretary'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        title: const Text('Create Account',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryTeal, AppTheme.primaryDark],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add,
                        size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text('Join Kagema Family',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C))),
                  const SizedBox(height: 4),
                  Text('Create your school account',
                      style:
                      TextStyle(color: Colors.grey[500], fontSize: 13)),
                  const SizedBox(height: 24),
                  _inputField(nameController, 'Full Name', Icons.person),
                  const SizedBox(height: 12),
                  _inputField(
                      emailController, 'Email Address', Icons.email_outlined),
                  const SizedBox(height: 12),
                  _inputField(idController, 'Staff / Parent ID',
                      Icons.badge_outlined),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedRole = v!),
                    decoration: InputDecoration(
                      labelText: 'Select Role',
                      prefixIcon: Icon(Icons.work_outline,
                          color: AppTheme.primaryTeal),
                      filled: true,
                      fillColor: const Color(0xFFF5F8FF),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _inputField(passwordController, 'Password',
                      Icons.lock_outline_rounded,
                      obscure: true),
                  const SizedBox(height: 12),
                  _inputField(confirmController, 'Confirm Password',
                      Icons.lock_outline_rounded,
                      obscure: true),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (passwordController.text !=
                            confirmController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Passwords do not match'),
                                backgroundColor: Colors.red),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Registration successful! Please login.'),
                              backgroundColor: Colors.green),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: const Text('CREATE ACCOUNT',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
      TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryTeal, size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F8FF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.primaryTeal, width: 1.5),
        ),
      ),
    );
  }
}

// ==================== FORGOT PASSWORD SCREEN ====================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        title: const Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_reset_rounded,
                        size: 44, color: AppTheme.primaryTeal),
                  ),
                  const SizedBox(height: 20),
                  const Text('Forgot Password?',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C))),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email or staff ID to receive a password reset link',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Email or Staff ID',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: AppTheme.primaryTeal, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF5F8FF),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: AppTheme.primaryTeal, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Reset link sent! Check your email.'),
                              backgroundColor: Colors.green),
                        );
                        Future.delayed(const Duration(seconds: 2),
                                () => Navigator.pop(context));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: const Text('SEND RESET LINK',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DASHBOARD BUILDER ====================
Widget _buildDashboard({
  required BuildContext context,
  required String role,
  required Color color,
  required String emoji,
  required List<Map<String, dynamic>> cards,
}) {
  return Scaffold(
    backgroundColor: const Color(0xFFEFF6FF),
    appBar: AppBar(
      title: Text('$emoji $role Dashboard',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SettingsScreen(role: role)),
            );
          },
        ),
      ],
    ),
    drawer: Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(height: 12),
                Text('$role Panel',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('Kagema Comprehensive',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          ListTile(
              leading:
              Icon(Icons.dashboard_outlined, color: color),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context)),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: color),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SettingsScreen(role: role)));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Logout',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const HomeLoginScreen()),
                    (_) => false,
              );
            },
          ),
        ],
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
        physics: const BouncingScrollPhysics(),
        children: cards.map((card) {
          return GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${card['title']} coming soon!'),
                    backgroundColor: color),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(card['icon'] as IconData,
                          size: 30, color: color),
                    ),
                    const SizedBox(height: 10),
                    Text(card['title'] as String,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A3A5C),
                            fontSize: 13),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(card['subtitle'] as String,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

// ==================== DASHBOARDS ====================
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) => _buildDashboard(
    context: context,
    role: 'Admin',
    color: const Color(0xFF5C6BC0),
    emoji: '👑',
    cards: const [
      {'title': 'School Stats', 'icon': Icons.dashboard, 'subtitle': 'View overall performance'},
      {'title': 'Manage Users', 'icon': Icons.people, 'subtitle': 'Add/Edit/Delete roles'},
      {'title': 'Classes', 'icon': Icons.class_, 'subtitle': 'Manage all classes'},
      {'title': 'Timetable', 'icon': Icons.calendar_today, 'subtitle': 'Set school timetable'},
      {'title': 'Finances', 'icon': Icons.attach_money, 'subtitle': 'Full financial overview'},
      {'title': 'System', 'icon': Icons.settings, 'subtitle': 'Global system settings'},
    ],
  );
}

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        title: const Text('📚 Teacher Dashboard'),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(context, '📝 Student Management', Icons.people, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => StudentManagementScreen()));
            }),
            _buildCard(context, 'My Classes', Icons.class_, null),
            _buildCard(context, 'Attendance', Icons.checklist, null),
            _buildCard(context, 'Grades', Icons.grade, null),
            _buildCard(context, 'Timetable', Icons.calendar_today, null),
            _buildCard(context, 'Reports', Icons.bar_chart, null),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCard(BuildContext context, String title, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title coming soon!'), backgroundColor: const Color(0xFF26A69A)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF26A69A)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});
  @override
  Widget build(BuildContext context) => _buildDashboard(
    context: context,
    role: 'Parent',
    color: const Color(0xFFEF5350),
    emoji: '👪',
    cards: const [
      {'title': 'My Children', 'icon': Icons.family_restroom, 'subtitle': 'View children details'},
      {'title': 'Fee Status', 'icon': Icons.account_balance_wallet, 'subtitle': 'Check fee balance'},
      {'title': 'Academic Report', 'icon': Icons.assignment, 'subtitle': 'View report cards'},
      {'title': 'Events', 'icon': Icons.event, 'subtitle': 'School calendar'},
      {'title': 'Messages', 'icon': Icons.message, 'subtitle': 'Talk to teachers'},
      {'title': 'Settings', 'icon': Icons.settings, 'subtitle': 'Profile & preferences'},
    ],
  );
}

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});
  @override
  Widget build(BuildContext context) => _buildDashboard(
    context: context,
    role: 'Staff',
    color: const Color(0xFF66BB6A),
    emoji: '🔧',
    cards: const [
      {'title': 'My Tasks', 'icon': Icons.task, 'subtitle': 'Pending & completed'},
      {'title': 'Salary Slip', 'icon': Icons.receipt, 'subtitle': 'View payslips'},
      {'title': 'Leave Request', 'icon': Icons.beach_access, 'subtitle': 'Apply for leave'},
      {'title': 'Announcements', 'icon': Icons.announcement, 'subtitle': 'School news'},
      {'title': 'Duty Roster', 'icon': Icons.schedule, 'subtitle': 'Your shifts'},
      {'title': 'Settings', 'icon': Icons.settings, 'subtitle': 'Profile & preferences'},
    ],
  );
}

class AccountantDashboard extends StatelessWidget {
  const AccountantDashboard({super.key});
  @override
  Widget build(BuildContext context) => _buildDashboard(
    context: context,
    role: 'Accountant',
    color: const Color(0xFFFF7043),
    emoji: '💰',
    cards: const [
      {'title': 'Fee Collection', 'icon': Icons.payments, 'subtitle': 'Record payments'},
      {'title': 'Expenses', 'icon': Icons.receipt_long, 'subtitle': 'Track expenses'},
      {'title': 'Financial Reports', 'icon': Icons.show_chart, 'subtitle': 'Monthly/Yearly'},
      {'title': 'Debtors', 'icon': Icons.warning, 'subtitle': 'Outstanding fees'},
      {'title': 'Bank Reconciliation', 'icon': Icons.account_balance, 'subtitle': 'Match records'},
      {'title': 'Settings', 'icon': Icons.settings, 'subtitle': 'Financial preferences'},
    ],
  );
}

class SecretaryDashboard extends StatelessWidget {
  const SecretaryDashboard({super.key});
  @override
  Widget build(BuildContext context) => _buildDashboard(
    context: context,
    role: 'Secretary',
    color: const Color(0xFFAB47BC),
    emoji: '📋',
    cards: const [
      {'title': 'New Admissions', 'icon': Icons.person_add, 'subtitle': 'Register students'},
      {'title': 'Student Records', 'icon': Icons.folder, 'subtitle': 'Manage files'},
      {'title': 'Documents', 'icon': Icons.description, 'subtitle': 'Certificates & letters'},
      {'title': 'Appointments', 'icon': Icons.calendar_month, 'subtitle': 'Schedule meetings'},
      {'title': 'Communications', 'icon': Icons.email, 'subtitle': 'Send notices'},
      {'title': 'Settings', 'icon': Icons.settings, 'subtitle': 'Office preferences'},
    ],
  );
}


