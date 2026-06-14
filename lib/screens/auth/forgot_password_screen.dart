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
        SnackBar(
          content: const Text('Email or Phone Number Required', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    setState(() => _isSending = true);
    // Simulate cloud reset request
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset link sent to your registered email!', style: TextStyle(fontWeight: FontWeight.bold)), 
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
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
        title: const Text('PASSWORD RECOVERY', 
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(theme, gemini),
                const SizedBox(height: 48),
                _buildResetForm(theme, gemini),
                const SizedBox(height: 48),
                const Text(
                  'SYSTEM SECURITY: MFA SECURE',
                  style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    return Column(
      children: [
        gemini?.buildGlowContainer(
          borderRadius: 50,
          borderThickness: 2,
          backgroundColor: theme.primaryColor.withOpacity(0.05),
          padding: const EdgeInsets.all(20),
          child: Icon(Icons.lock_reset_rounded, size: 50, color: theme.primaryColor),
        ) ?? Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_reset_rounded, size: 50, color: theme.primaryColor),
        ),
        const SizedBox(height: 24),
        const Text(
          'Password Reset',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          child: Text(
            'Enter your registered email or phone number to receive a secure reset link.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Column(
      children: [
        TextField(
          controller: _identifierController,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Email or Phone Number',
            labelStyle: const TextStyle(fontSize: 13),
            prefixIcon: Icon(Icons.alternate_email_rounded, color: theme.primaryColor),
            filled: true,
            fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            hintText: 'e.g. user@kagema.com',
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isSending ? null : _handleReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: theme.primaryColor.withOpacity(0.4),
            ),
            child: _isSending 
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
              : const Text('SEND RESET LINK',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
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
}
