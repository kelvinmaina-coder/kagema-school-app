import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/authentication_service.dart';
import '../../app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignup() async {
    final dt = context.dt;
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Phone Number and Password Required', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: dt.warning,
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthenticationService>(context, listen: false);
      final result = await authService.registerParent(_phoneController.text, _passwordController.text);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']), 
              backgroundColor: dt.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: dt.error, behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('ACCOUNT REGISTRATION', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: Colors.white)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        maxWidth: 500,
        useAIBorder: true,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildBranding(dt, theme),
                const SizedBox(height: 48),
                _buildRegistrationForm(dt, theme),
                const SizedBox(height: 48),
                Text(
                  'SYSTEM SECURITY: SHA-256 ENCRYPTION ACTIVE',
                  style: TextStyle(fontSize: 8, color: dt.success, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
      ) ?? const SizedBox(),
    );
  }

  Widget _buildBranding(DT dt, GeminiThemeExtension? theme) {
    final primaryColor = RoleColors.of('parent');
    return Column(
      children: [
        theme?.buildGlowContainer(
          accentColor: primaryColor,
          borderRadius: 50,
          padding: const EdgeInsets.all(20),
          useAIBorder: true,
          child: const Icon(Icons.family_restroom_rounded, size: 50, color: Colors.white),
        ) ?? Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.family_restroom_rounded, size: 50, color: primaryColor),
        ),
        const SizedBox(height: 24),
        Text('Join the Portal', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, color: dt.textPrimary)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          child: Text(
            'Register your phone number to access your children\'s academic records in real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(DT dt, GeminiThemeExtension? theme) {
    final primaryColor = RoleColors.of('parent');
    final content = Column(
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
          decoration: InputDecoration(
            labelText: 'Phone Number',
            labelStyle: const TextStyle(fontSize: 13),
            prefixIcon: Icon(Icons.phone_android_rounded, color: primaryColor),
            hintText: 'e.g. 0712345678',
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
          decoration: InputDecoration(
            labelText: 'Set Password',
            labelStyle: const TextStyle(fontSize: 13),
            prefixIcon: Icon(Icons.lock_person_rounded, color: primaryColor),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
              : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
          ),
        ),
      ],
    );

    return theme?.buildGlowContainer(
      accentColor: primaryColor,
      borderRadius: 30,
      padding: const EdgeInsets.all(24),
      child: content,
    ) ?? Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: dt.cardBg, borderRadius: BorderRadius.circular(30)),
      child: content,
    );
  }
}
