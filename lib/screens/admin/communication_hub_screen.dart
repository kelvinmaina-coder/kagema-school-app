import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

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
          const SnackBar(content: Text('Broadcast Transmitted Successfully!'), backgroundColor: Colors.pink),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Broadcast Hub', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.pink.shade900, Colors.pink.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.campaign_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, left: 24, right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('INITIATE GLOBAL BROADCAST'),
              const SizedBox(height: 16),
              _buildNoticeForm(theme, gemini),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeForm(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Column(
      children: [
        TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Notice Headline', prefixIcon: const Icon(Icons.title, color: Colors.pink), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)))),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedRole,
          items: ['all', 'staff', 'teacher', 'parent'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
          onChanged: (v) => setState(() => _selectedRole = v!),
          decoration: InputDecoration(labelText: 'Target Neural Audience', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))),
        ),
        const SizedBox(height: 20),
        TextField(controller: _msgController, maxLines: 5, decoration: InputDecoration(labelText: 'Intelligence Message', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)))),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _isPosting ? null : _postNotice, 
            icon: const Icon(Icons.send_rounded), 
            label: Text(_isPosting ? 'TRANSMITTING...' : 'AUTHORIZE BROADCAST', style: const TextStyle(fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          ),
        ),
      ],
    );
    return gemini?.buildGlowContainer(borderRadius: 30, borderThickness: 1.5, backgroundColor: theme.cardColor.withOpacity(0.9), padding: const EdgeInsets.all(24), child: content) ?? Container(padding: const EdgeInsets.all(24), child: content);
  }

  Widget _buildSectionLabel(String text) => Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2));
}
