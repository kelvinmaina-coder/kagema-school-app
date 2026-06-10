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
    {'title': 'Parent', 'icon': Icons.family_restroom_rounded, 'color': const Color(0xFFE65100), 'id': 'parent', 'hint': 'Guardian Email / Phone'},
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
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
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.school_rounded, size: 80, color: Colors.orange),
                const SizedBox(height: 16),
                const Text('Kagema school', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                _buildRoleGrid(),
                const SizedBox(height: 32),
                _buildLoginForm(theme),
              ],
            ),
          ),
        ),
      ) ?? const SizedBox(),
    );
  }

  Widget _buildRoleGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        final isSelected = selectedRole == role['title'];
        return InkWell(
          onTap: () => setState(() => selectedRole = role['title']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? role['color'] : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? role['color'] : Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(role['icon'], color: isSelected ? Colors.white : role['color']),
                Text(role['title'], style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Column(
      children: [
        TextField(controller: identifierController, decoration: const InputDecoration(labelText: 'Identifier', prefixIcon: Icon(Icons.person))),
        const SizedBox(height: 16),
        TextField(controller: passwordController, obscureText: !isPasswordVisible, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('LOGIN'),
          ),
        ),
      ],
    );
  }
}
