import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Map<String, dynamic>> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Logic: Passing 'parent' fetches both 'parent' and 'all' notifications
      final data = await SupabaseService.instance.getNotifications('parent');
      if (mounted) {
        setState(() {
          _notices = data;
          _isLoading = false;
        });
      }
    } catch (e) {
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
        title: const Text('Intelligence Broadcasts', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.pink.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.campaign_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.pink))
            : _notices.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: _notices.length,
                  itemBuilder: (context, index) {
                    final n = _notices[index];
                    final content = ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.pink.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.notifications_active_rounded, color: Colors.pink, size: 24)),
                      title: Text(n['title'] ?? 'Notice', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      subtitle: Text(n['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: () => _showNoticeDetail(n),
                    );
                    return Padding(padding: const EdgeInsets.only(bottom: 16), child: gemini?.buildGlowContainer(borderRadius: 28, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content));
                  },
                ),
        ),
      ),
    );
  }

  void _showNoticeDetail(Map<String, dynamic> n) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NEURAL BROADCAST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.pink, letterSpacing: 2)),
            const SizedBox(height: 12),
            Text(n['title'] ?? 'Notice Node', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Text(n['message'] ?? '', style: const TextStyle(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('DISMISS NODE', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.campaign_outlined, size: 80, color: Colors.grey.withOpacity(0.3)), const SizedBox(height: 16), const Text('NO LIVE BROADCASTS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5))]));
}
