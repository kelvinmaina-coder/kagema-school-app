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
    if (!mounted) return;
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
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Neural Handshakes', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, Colors.indigo.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.forum_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(20, AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, 20, 40),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final content = ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.campaign_rounded, color: Colors.indigo, size: 24),
                  ),
                  title: Text(msg['title'] ?? 'Neural Notice', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(msg['message'] ?? 'No transmission data.', 
                      style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500)
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () async {
                      await SupabaseService.instance.deleteNotification(msg['notification_id']);
                      _loadMessages();
                    },
                  ),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: gemini?.buildGlowContainer(
                    borderRadius: 28,
                    borderThickness: 1,
                    backgroundColor: theme.cardColor.withOpacity(0.85),
                    padding: EdgeInsets.zero,
                    child: content,
                  ) ?? Card(child: content),
                );
              },
            ),
      ),
    );
  }
}
