import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/authentication_service.dart';
import '../parent/parent_dashboard.dart';
import '../../app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  String? selectedRole;
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> roles = [
    {'title': 'Admin', 'icon': Icons.admin_panel_settings_rounded, 'color': const Color(0xFF1A237E), 'id': 'admin', 'hint': 'Administrator ID'},
    {'title': 'Teacher', 'icon': Icons.school_rounded, 'color': const Color(0xFF00695C), 'id': 'teacher', 'hint': 'Staff Work ID'},
    {'title': 'Parent', 'icon': Icons.family_restroom_rounded, 'color': const Color(0xFFE65100), 'id': 'parent', 'hint': 'Guardian Email / Phone'},
    {'title': 'Accountant', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFFBF360C), 'id': 'accountant', 'hint': 'Treasury ID'},
    {'title': 'Secretary', 'icon': Icons.assignment_ind_rounded, 'color': const Color(0xFF4A148C), 'id': 'secretary', 'hint': 'Office ID'},
    {'title': 'Staff', 'icon': Icons.badge_rounded, 'color': const Color(0xFF1B5E20), 'id': 'staff', 'hint': 'Staff Work ID'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (selectedRole == null) {
      _showError('Security: Please select your authorization role.');
      return;
    }
    if (identifierController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _showError('Credentials Required: Please enter your ID and Password.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = Provider.of<AuthenticationService>(context, listen: false);
      final roleData = roles.firstWhere((r) => r['title'] == selectedRole);
      
      // Fixed signature call
      final success = await authService.login(
        roleData['id'], 
        identifierController.text.trim(), 
        passwordController.text
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (success) {
        if (roleData['id'] == 'parent') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ParentDashboard(parentPhone: identifierController.text.trim()))
          );
        } else {
          Navigator.pushReplacementNamed(context, '/${roleData['id']}_dashboard');
        }
      } else {
        _showError('Access Denied: Invalid credentials.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showError('System Error: Unable to verify credentials.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                children: [
                  _buildBranding(theme),
                  const SizedBox(height: 40),
                  _buildIdentityGrid(theme, gemini),
                  const SizedBox(height: 40),
                  _buildLoginForm(theme, gemini),
                  const SizedBox(height: 24),
                  if (selectedRole == 'Parent') 
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text('New Parent? Register here', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: 40),
                  _buildFooter(theme),
                ],
              ),
            ),
          ),
        ),
      ) ?? const SizedBox(),
    );
  }

  Widget _buildBranding(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.school_rounded, size: 60, color: theme.primaryColor),
        ),
        const SizedBox(height: 16),
        const Text('Kagema school', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text('CLOUD-POWERED CAMPUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 2)),
        ),
      ],
    );
  }

  Widget _buildIdentityGrid(ThemeData theme, GeminiThemeExtension? gemini) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
      ),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        final isSelected = selectedRole == role['title'];
        return InkWell(
          onTap: () => setState(() => selectedRole = role['title']),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? role['color'] : theme.cardColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? role['color'] : theme.primaryColor.withOpacity(0.1), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(role['icon'], color: isSelected ? Colors.white : role['color'], size: 28),
                const SizedBox(height: 6),
                Text(role['title'].toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(ThemeData theme, GeminiThemeExtension? gemini) {
    String dynamicHint = selectedRole != null ? roles.firstWhere((r) => r['title'] == selectedRole)['hint'] : "Select Identity Above";
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          TextField(controller: identifierController, decoration: InputDecoration(labelText: dynamicHint, prefixIcon: const Icon(Icons.person))),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible)),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('AUTHORIZE ACCESS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return const Text('SYSTEM STATUS: SECURE CONNECTION ACTIVE', style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 2));
  }
}
