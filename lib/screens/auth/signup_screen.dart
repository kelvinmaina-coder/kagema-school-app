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
        const SnackBar(content: Text('Identity required: Enter Phone & Password')),
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
            SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
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
        title: const Text('Parent Registration', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildBranding(theme),
                const SizedBox(height: 40),
                _buildRegistrationForm(theme),
                const SizedBox(height: 40),
                const Text(
                  'SYSTEM SECURITY: SHA-256 ENCRYPTION ACTIVE',
                  style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.family_restroom_rounded, size: 60, color: theme.primaryColor),
        ),
        const SizedBox(height: 20),
        const Text(
          'Join the Community',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Link your phone number to automatically sync your children\'s academic records.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(ThemeData theme) {
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
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Parent Phone Number',
              prefixIcon: Icon(Icons.phone_android_rounded),
              hintText: 'e.g. 0712345678',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Create Access Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('INITIALIZE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }
}
