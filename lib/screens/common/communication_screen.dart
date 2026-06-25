import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
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
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(widget.senderRole);
    final compColor = RoleColors.complement(widget.senderRole);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('SCHOOL COMMUNICATIONS', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 3, color: Colors.white)
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
            gradient: RoleColors.gradient(widget.senderRole, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.forum_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: roleColor))
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, 20, 40),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: theme.buildGlowContainer(
                      accentColor: roleColor,
                      borderRadius: 28,
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: dt.roleSoftBg(roleColor), shape: BoxShape.circle),
                          child: Icon(Icons.campaign_rounded, color: roleColor, size: 24),
                        ),
                        title: Text(msg['title']?.toString().toUpperCase() ?? 'NOTICE', 
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary, letterSpacing: 0.5)
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(msg['message'] ?? 'No message content.',
                            style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: dt.textSecondary)
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_sweep_rounded, color: dt.error, size: 22),
                          onPressed: () async {
                            // Assuming deleteNotification exists or using generic delete
                            await SupabaseService.instance.client.from('notifications').delete().eq('notification_id', msg['notification_id']);
                            _loadMessages();
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }
}
