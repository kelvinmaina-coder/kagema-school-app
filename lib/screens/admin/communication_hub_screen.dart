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
  Map<String, dynamic>? _editingNotification;

  final List<String> _roles = ['All', 'Teacher', 'Parent', 'Staff', 'Admin'];

  void _sendAnnouncement() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Identity sync error: Fill all fields')));
      return;
    }
    setState(() => _isSending = true);
    try {
      if (_editingNotification != null) {
        await SupabaseService.instance.client.from('notifications').update({
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'target_role': _selectedRole,
        }).eq('notification_id', _editingNotification!['notification_id']);
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast Updated Successfully!'), backgroundColor: Colors.blue));
      } else {
        await SupabaseService.instance.postAnnouncement(
          _titleController.text.trim(),
          _messageController.text.trim(),
          _selectedRole,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud Broadcast Successful!'), backgroundColor: Colors.green));
      }
      
      if (mounted) {
        setState(() {
          _isSending = false;
          _editingNotification = null;
        });
        _titleController.clear();
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Broadcast Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _editNotification(Map<String, dynamic> n) {
    setState(() {
      _editingNotification = n;
      _titleController.text = n['title'] ?? '';
      _messageController.text = n['message'] ?? '';
      _selectedRole = n['target_role'] ?? 'All';
    });
  }

  void _deleteNotification(Map<String, dynamic> n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retract Broadcast?'),
        content: Text('Delete "${n['title']}"? It will disappear from all portals.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('RETRACT', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.deleteNotification(n['notification_id'].toString());
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_editingNotification != null ? 'EDIT BROADCAST' : 'NEW BROADCAST', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
              if (_editingNotification != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => setState(() {
                    _editingNotification = null;
                    _titleController.clear();
                    _messageController.clear();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
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
              icon: _isSending ? const CircularProgressIndicator(color: Colors.white) : Icon(_editingNotification != null ? Icons.save_rounded : Icons.rocket_launch_rounded),
              label: Text(_editingNotification != null ? 'UPDATE CLOUD BROADCAST' : 'AUTHORIZE BROADCAST', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(backgroundColor: _editingNotification != null ? Colors.blue.shade700 : theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(n['target_role'] ?? 'All', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') _editNotification(n);
                      if (val == 'delete') _deleteNotification(n);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded, size: 20), title: Text('Edit'), dense: true)),
                      const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 20), title: Text('Delete'), dense: true)),
                    ],
                  ),
                ],
              ),
            ),
          )).toList(),
        );
      },
    );
  }
}
