import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/authentication_service.dart';
import '../parent/parent_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'TEACHER';
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;

  final List<Map<String, dynamic>> roles = [
    {'title': 'ADMIN', 'icon': Icons.shield_rounded, 'color': const Color(0xFF2563EB), 'id': 'admin', 'hint': 'Admin ID'},
    {'title': 'TEACHER', 'icon': Icons.school_rounded, 'color': const Color(0xFF10B981), 'id': 'teacher', 'hint': 'Staff ID'},
    {'title': 'PARENT', 'icon': Icons.family_restroom_rounded, 'color': const Color(0xFFEF4444), 'id': 'parent', 'hint': 'Phone Number'},
    {'title': 'ACCOUNTANT', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFFF59E0B), 'id': 'accountant', 'hint': 'Treasury ID'},
    {'title': 'SECRETARY', 'icon': Icons.assignment_ind_rounded, 'color': const Color(0xFF8B5CF6), 'id': 'secretary', 'hint': 'Office ID'},
    {'title': 'STAFF', 'icon': Icons.badge_rounded, 'color': const Color(0xFF0EA5E9), 'id': 'staff', 'hint': 'Staff ID'},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  _buildBranding(),
                  const SizedBox(height: 40),
                  _buildSectionHeader('SELECT ACCESS LEVEL'),
                  const SizedBox(height: 20),
                  _buildRoleGrid(screenWidth),
                  const SizedBox(height: 30),
                  _buildAuthCard(),
                  const SizedBox(height: 40),
                  _buildSystemStatus(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFF4D00).withValues(alpha: 0.15), width: 1.5),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: const Icon(Icons.hub_rounded, size: 50, color: Color(0xFFFF4D00)),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'KAGEMA SCHOOL',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBE8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'INTELLIGENT EDUCATION HUB',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFFF4D00), letterSpacing: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 14, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildRoleGrid(double screenWidth) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 20,
        childAspectRatio: 0.9,
      ),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        final isSelected = selectedRole == role['title'];

        return GestureDetector(
          onTap: () => setState(() => selectedRole = role['title']),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? role['color'].withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isSelected ? role['color'] : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    role['icon'],
                    color: isSelected ? role['color'] : const Color(0xFF94A3B8),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                role['title'],
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthCard() {
    final activeRole = roles.firstWhere((r) => r['title'] == selectedRole);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          _buildInput(Icons.fingerprint_rounded, 'IDENTIFICATION', activeRole['hint'], identifierController),
          const SizedBox(height: 18),
          _buildInput(Icons.lock_person_rounded, 'ACCESS KEY', '••••••••', passwordController, isPass: true),
          const SizedBox(height: 35),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildInput(IconData icon, String label, String hint, TextEditingController ctrl, {bool isPass = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF4D00), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFFF4D00), letterSpacing: 2)),
                TextField(
                  controller: ctrl,
                  obscureText: isPass && !isPasswordVisible,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 4),
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
          if (isPass)
            IconButton(
              icon: Icon(isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20, color: const Color(0xFF94A3B8)),
              onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4D00), Color(0xFFFF7A00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D00).withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Text(
                'AUTHENTICATE & ENTER',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13, letterSpacing: 1.5),
              ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        const Text(
          'ENCRYPTED NODE ACTIVE',
          style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      ],
    );
  }

  void _handleLogin() async {
    setState(() => isLoading = true);
    final authService = Provider.of<AuthenticationService>(context, listen: false);
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
            MaterialPageRoute(builder: (_) => ParentDashboard(parentPhone: identifierController.text.trim())),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/${roleData['id']}_dashboard');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('INVALID CREDENTIALS')),
        );
      }
    }
  }
}
