import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class CommunicationHubScreen extends StatefulWidget {
  const CommunicationHubScreen({super.key});

  @override
  State<CommunicationHubScreen> createState() => _CommunicationHubScreenState();
}

class _CommunicationHubScreenState extends State<CommunicationHubScreen> {
  final _titleController = TextEditingController();
  final _msgController = TextEditingController();
  String _selectedRole = 'all';
  bool _isPosting = false;
  final String _roleId = 'admin';

  Future<void> _postNotice() async {
    if (_titleController.text.isEmpty || _msgController.text.isEmpty) return;
    setState(() => _isPosting = true);
    try {
      await SupabaseService.instance.postAnnouncement(
        _titleController.text.trim(), 
        _msgController.text.trim(), 
        _selectedRole
      );
      if (mounted) {
        _titleController.clear();
        _msgController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast Transmitted Successfully!', style: TextStyle(fontWeight: FontWeight.w700)), 
            backgroundColor: KagemaColors.teacherGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = DT.of(context);
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('BROADCAST HUB', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.campaign_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)))]),
        ),
      ),
      body: NeuralBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, left: 24, right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('INITIATE GLOBAL BROADCAST', dt),
                const SizedBox(height: 16),
                _buildNoticeForm(dt),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeForm(DT dt) {
    return LiquidGlassCard(
      accentColor: KagemaColors.secretaryViolet,
      borderRadius: 30,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _titleController, 
            style: TextStyle(color: dt.textPrimary, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Notice Headline', 
              prefixIcon: const Icon(Icons.title, color: KagemaColors.secretaryViolet),
            )
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            dropdownColor: dt.cardBg,
            style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
            items: ['all', 'staff', 'teacher', 'parent'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _selectedRole = v!),
            decoration: const InputDecoration(labelText: 'Target Neural Audience'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _msgController, 
            maxLines: 5, 
            style: TextStyle(color: dt.textPrimary),
            decoration: const InputDecoration(labelText: 'Intelligence Message'),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _isPosting ? null : _postNotice, 
              icon: const Icon(Icons.send_rounded), 
              label: Text(_isPosting ? 'TRANSMITTING...' : 'AUTHORIZE BROADCAST', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: KagemaColors.secretaryViolet, 
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, DT dt) => Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2));
}
