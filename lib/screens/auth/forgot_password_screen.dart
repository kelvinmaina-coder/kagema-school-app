import 'package:flutter/material.dart';
import '../../app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  bool _isSending = false;

  void _handleReset() async {
    if (_identifierController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email or phone')),
      );
      return;
    }

    setState(() => _isSending = true);
    // Simulate cloud reset request
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery link sent to your cloud-registered address!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Recovery Center', style: TextStyle(fontWeight: FontWeight.bold)),
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
                _buildHeader(theme),
                const SizedBox(height: 40),
                _buildResetForm(theme),
                const SizedBox(height: 40),
                const Text(
                  'SYSTEM SECURITY: MFA READY',
                  style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_reset_rounded, size: 60, color: theme.primaryColor),
        ),
        const SizedBox(height: 20),
        const Text(
          'Account Recovery',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Enter your registered credentials to receive a secure password restoration link.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm(ThemeData theme) {
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
            controller: _identifierController,
            decoration: const InputDecoration(
              labelText: 'Email or Phone Number',
              prefixIcon: Icon(Icons.alternate_email_rounded),
              hintText: 'e.g. user@kagema.com',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSending ? null : _handleReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
              ),
              child: _isSending 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('SEND RECOVERY LINK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }
}
