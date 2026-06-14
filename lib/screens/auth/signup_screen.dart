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
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Neural Identification Required', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange.shade800,
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
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: Colors.red.shade800, behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('NEURAL ONBOARDING', 
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
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        maxWidth: 500, // Stay professional on desktop
        useAIBorder: true, // IMPORTANT: AI Spectrum Visuals Applied
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildBranding(theme, gemini),
                const SizedBox(height: 48),
                _buildRegistrationForm(theme, gemini),
                const SizedBox(height: 48),
                const Text(
                  'SYSTEM SECURITY: SHA-256 NEURAL ENCRYPTION ACTIVE',
                  style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
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
          child: Icon(Icons.family_restroom_rounded, size: 50, color: theme.primaryColor),
        ) ?? Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.family_restroom_rounded, size: 50, color: theme.primaryColor),
        ),
        const SizedBox(height: 24),
        const Text('Join the Network', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          child: Text(
            'Link your neural identifier to synchronize your children\'s academic logs in real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Column(
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Neural Phone Identifier',
            labelStyle: const TextStyle(fontSize: 13),
            prefixIcon: Icon(Icons.phone_android_rounded, color: theme.primaryColor),
            filled: true,
            fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            hintText: 'e.g. 0712345678',
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Set Neural Access Key',
            labelStyle: const TextStyle(fontSize: 13),
            prefixIcon: Icon(Icons.lock_person_rounded, color: theme.primaryColor),
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
            onPressed: _isLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: theme.primaryColor.withOpacity(0.4),
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
              : const Text('INITIALIZE NEURAL HANDSHAKE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
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
      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(30)),
      child: content,
    );
  }
}
