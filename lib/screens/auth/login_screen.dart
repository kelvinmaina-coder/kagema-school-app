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

  final List<Map<String, dynamic>> roles = [
    {'title': 'Admin', 'icon': Icons.admin_panel_settings_rounded, 'color': const Color(0xFF1A237E), 'id': 'admin', 'hint': 'Administrator ID'},
    {'title': 'Teacher', 'icon': Icons.school_rounded, 'color': const Color(0xFF00695C), 'id': 'teacher', 'hint': 'Staff Work ID'},
    {'title': 'Parent', 'icon': Icons.family_restroom_rounded, 'color': const Color(0xFFE65100), 'id': 'parent', 'hint': 'Guardian Phone'},
    {'title': 'Accountant', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFFBF360C), 'id': 'accountant', 'hint': 'Treasury ID'},
    {'title': 'Secretary', 'icon': Icons.assignment_ind_rounded, 'color': const Color(0xFF4A148C), 'id': 'secretary', 'hint': 'Office ID'},
    {'title': 'Staff', 'icon': Icons.badge_rounded, 'color': const Color(0xFF1B5E20), 'id': 'staff', 'hint': 'Staff Work ID'},
  ];

  void _handleLogin() async {
    if (selectedRole == null) {
      _showError('Security: Please select your authorization role.');
      return;
    }
    setState(() => isLoading = true);
    final authService = Provider.of<AuthenticationService>(context, listen: false);
    final roleData = roles.firstWhere((r) => r['title'] == selectedRole);
    
    final success = await authService.login(
      roleData['id'], 
      identifierController.text.trim(), 
      passwordController.text
    );

    if (mounted) {
      setState(() => isLoading = false);

      if (success) {
        if (roleData['id'] == 'parent') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ParentDashboard(parentPhone: identifierController.text.trim())));
        } else {
          Navigator.pushReplacementNamed(context, '/${roleData['id']}_dashboard');
        }
      } else {
        _showError('Access Denied: Invalid credentials.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                _buildBranding(theme),
                const SizedBox(height: 40),
                _buildRoleGrid(theme),
                const SizedBox(height: 32),
                _buildLoginForm(theme),
                const SizedBox(height: 24),
                if (selectedRole == 'Parent')
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('New Parent? Register Identity', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 40),
                const Text('SYSTEM SECURITY: AUTHORIZED ACCESS ONLY', style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ],
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.school_rounded, size: 60, color: theme.primaryColor),
        ),
        const SizedBox(height: 16),
        const Text('Kagema School', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text('CLOUD-POWERED HUB', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 2)),
        ),
      ],
    );
  }

  Widget _buildRoleGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.0,
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
              color: isSelected ? role['color'] : theme.cardColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? role['color'] : Colors.grey.withOpacity(0.2), width: 2),
              boxShadow: isSelected ? [BoxShadow(color: role['color'].withOpacity(0.3), blurRadius: 10, spreadRadius: 1)] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(role['icon'], color: isSelected ? Colors.white : role['color'], size: 28),
                const SizedBox(height: 6),
                Text(role['title'].toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.grey[700])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    String dynamicHint = selectedRole != null ? roles.firstWhere((r) => r['title'] == selectedRole)['hint'] : "Select Role Above";
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          TextField(
            controller: identifierController,
            decoration: InputDecoration(
              labelText: dynamicHint,
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Access Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
              ),
              child: isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('AUTHORIZE SESSION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
