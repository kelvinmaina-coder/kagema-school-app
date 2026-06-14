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
      _showError('Please select your login role.');
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
        maxWidth: 500,
        useAIBorder: true, 
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                _buildBranding(theme, gemini),
                const SizedBox(height: 40),
                _buildSectionLabel('SECURE LOGIN ACCESS'),
                const SizedBox(height: 16),
                _buildRoleGrid(theme, gemini),
                const SizedBox(height: 32),
                _buildLoginForm(theme, gemini),
                const SizedBox(height: 24),
                if (selectedRole == 'Parent')
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('New Parent? Register Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 40),
                const Text('SYSTEM SECURITY: AUTHORIZED ACCESS ONLY', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ) ?? const SizedBox(),
    );
  }

  Widget _buildBranding(ThemeData theme, GeminiThemeExtension? gemini) {
    return Column(
      children: [
        gemini?.buildGlowContainer(
          borderRadius: 50,
          borderThickness: 2,
          backgroundColor: theme.primaryColor.withOpacity(0.05),
          padding: const EdgeInsets.all(20),
          child: Icon(Icons.school_rounded, size: 50, color: theme.primaryColor),
        ) ?? Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.school_rounded, size: 50, color: theme.primaryColor),
        ),
        const SizedBox(height: 20),
        const Text('Kagema School', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text('SCHOOL PORTAL HUB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 2)),
        ),
      ],
    );
  }

  Widget _buildRoleGrid(ThemeData theme, GeminiThemeExtension? gemini) {
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
        
        final content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(role['icon'], color: isSelected ? Colors.white : role['color'], size: 24),
            const SizedBox(height: 8),
            Text(role['title'].toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.grey[700])),
          ],
        );

        if (isSelected && gemini != null) {
          return gemini.buildGlowContainer(
            borderRadius: 20,
            borderThickness: 2,
            backgroundColor: role['color'],
            padding: EdgeInsets.zero,
            child: content,
          );
        }

        return InkWell(
          onTap: () => setState(() => selectedRole = role['title']),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? role['color'] : theme.cardColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? role['color'] : Colors.grey.withOpacity(0.2), width: 1.5),
            ),
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(ThemeData theme, GeminiThemeExtension? gemini) {
    String dynamicHint = selectedRole != null ? roles.firstWhere((r) => r['title'] == selectedRole)['hint'] : "Select Role Above";
    
    final content = Column(
      children: [
        TextField(
          controller: identifierController,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: dynamicHint,
            labelStyle: const TextStyle(fontSize: 13),
            prefixIcon: Icon(Icons.person_outline, color: theme.primaryColor),
            filled: true,
            fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: passwordController,
          obscureText: !isPasswordVisible,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Access Password',
            labelStyle: const TextStyle(fontSize: 13),
            prefixIcon: Icon(Icons.lock_outline, color: theme.primaryColor),
            suffixIcon: IconButton(
              icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 20),
              onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
            ),
            filled: true,
            fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: theme.primaryColor.withOpacity(0.4),
            ),
            child: isLoading 
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
              : const Text('LOGIN TO PORTAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
          ),
        ),
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 30,
      borderThickness: 2,
      backgroundColor: theme.cardColor.withOpacity(0.9),
      padding: const EdgeInsets.all(24),
      child: content,
    ) ?? Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: content,
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.blueGrey));
  }
}
