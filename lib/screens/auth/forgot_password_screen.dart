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
    final dt = context.dt;
    if (_identifierController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email or Phone Number Required', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: dt.warning,
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
          backgroundColor: dt.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
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
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(dt, theme),
                const SizedBox(height: 48),
                _buildResetForm(dt, theme),
                const SizedBox(height: 48),
                Text(
                  'SYSTEM SECURITY: MFA SECURE',
                  style: TextStyle(fontSize: 8, color: dt.success, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
      ) ?? const SizedBox(),
    );
  }

  Widget _buildHeader(DT dt, GeminiThemeExtension? theme) {
    final primaryColor = RoleColors.of('admin'); // Using admin orange as default brand color
    return Column(
      children: [
        theme?.buildGlowContainer(
          accentColor: primaryColor,
          borderRadius: 50,
          padding: const EdgeInsets.all(20),
          useAIBorder: true,
          child: const Icon(Icons.lock_reset_rounded, size: 50, color: Colors.white),
        ) ?? Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_reset_rounded, size: 50, color: primaryColor),
        ),
        const SizedBox(height: 24),
        Text(
          'Password Reset',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, color: dt.textPrimary),
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

  Widget _buildResetForm(DT dt, GeminiThemeExtension? theme) {
    final primaryColor = RoleColors.of('admin');
    final content = Column(
      children: [
        TextField(
          controller: _identifierController,
          style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
          decoration: InputDecoration(
            labelText: 'Email or Phone Number',
            labelStyle: const TextStyle(fontSize: 13),
            prefixIcon: Icon(Icons.alternate_email_rounded, color: primaryColor),
            hintText: 'e.g. user@kagema.com',
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isSending ? null : _handleReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            child: _isSending 
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
              : const Text('SEND RESET LINK',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
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
      decoration: BoxDecoration(
        color: dt.cardBg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: content,
    );
  }
}
