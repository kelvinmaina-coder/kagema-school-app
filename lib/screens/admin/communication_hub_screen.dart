import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class CommunicationHubScreen extends StatefulWidget {
  const CommunicationHubScreen({super.key});

  @override
  State<CommunicationHubScreen> createState() => _CommunicationHubScreenState();
}

class _CommunicationHubScreenState extends State<CommunicationHubScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedRole = 'All';
  bool _isSending = false;

  final List<String> _roles = ['All', 'Teacher', 'Parent', 'Staff', 'Admin'];

  void _sendAnnouncement() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Identity sync error: Fill all fields')));
      return;
    }
    setState(() => _isSending = true);
    try {
      await SupabaseService.instance.postAnnouncement(
        _titleController.text.trim(),
        _messageController.text.trim(),
        _selectedRole,
      );
      if (mounted) {
        setState(() => _isSending = false);
        _titleController.clear();
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud Broadcast Successful!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Broadcast Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Intelligence Broadcast', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.purple.shade900]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, left: 24, right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildComposeSection(theme),
              const SizedBox(height: 40),
              const Text('LIVE ANNOUNCEMENT FEED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
              const SizedBox(height: 16),
              _buildLiveFeed(theme),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposeSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: 'Target Audience', prefixIcon: Icon(Icons.groups_rounded)),
            items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (val) => setState(() => _selectedRole = val!),
          ),
          const SizedBox(height: 20),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Headline', prefixIcon: Icon(Icons.title))),
          const SizedBox(height: 20),
          TextField(controller: _messageController, maxLines: 3, decoration: const InputDecoration(labelText: 'Message Body', prefixIcon: Icon(Icons.notes))),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendAnnouncement,
              icon: _isSending ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.rocket_launch_rounded),
              label: const Text('AUTHORIZE BROADCAST', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveFeed(ThemeData theme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.instance.notificationStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.reversed.toList();
        return Column(
          children: data.map((n) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.campaign, color: Colors.white, size: 20)),
              title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(n['message'] ?? '', maxLines: 2),
              trailing: Text(n['target_role'] ?? 'All', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          )).toList(),
        );
      },
    );
  }
}
