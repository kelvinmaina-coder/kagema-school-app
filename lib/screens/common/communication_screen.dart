import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/school_models.dart';
import '../../app_theme.dart';

class CommunicationScreen extends StatefulWidget {
  final String senderRole;
  final String senderId;

  const CommunicationScreen({super.key, required this.senderRole, required this.senderId});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getNotifications(widget.senderRole);
      if (mounted) {
        setState(() {
          _messages = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Communication Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('School Notices')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.campaign)),
                  title: Text(msg['title'] ?? 'Notice'),
                  subtitle: Text(msg['message'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      await SupabaseService.instance.deleteNotification(msg['notification_id']);
                      _loadMessages();
                    },
                  ),
                ),
              );
            },
          ),
    );
  }
}
