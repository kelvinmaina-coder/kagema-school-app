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
  final String _roleId = 'parent';

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = DT.of(context);
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('SCHOOL ANNOUNCEMENTS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : _notices.isEmpty 
                ? _buildEmptyState(dt)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: _notices.length,
                    itemBuilder: (context, index) {
                      final n = _notices[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16), 
                        child: LiquidGlassCard(
                          accentColor: KagemaColors.secretaryViolet, 
                          borderRadius: 28, 
                          padding: EdgeInsets.zero, 
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Container(
                              padding: const EdgeInsets.all(12), 
                              decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.secretaryViolet), shape: BoxShape.circle), 
                              child: const Icon(Icons.notifications_active_rounded, color: KagemaColors.secretaryViolet, size: 24)
                            ),
                            title: Text(n['title'] ?? 'Notice', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary)),
                            subtitle: Text(n['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: dt.textSecondary)),
                            trailing: Icon(Icons.chevron_right_rounded, color: dt.iconInactive),
                            onTap: () => _showNoticeDetail(dt, n),
                          )
                        )
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  void _showNoticeDetail(DT dt, Map<String, dynamic> n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => LiquidGlassCard(
        borderRadius: 35,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SCHOOL NOTICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: KagemaColors.secretaryViolet, letterSpacing: 2)),
              const SizedBox(height: 12),
              Text(n['title'] ?? 'Notice Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dt.textPrimary)),
              const SizedBox(height: 16),
              Text(n['message'] ?? '', style: TextStyle(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500, color: dt.textSecondary)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context), 
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), 
                  child: Text('DISMISS', style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary))
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.campaign_outlined, size: 80, color: dt.iconInactive), const SizedBox(height: 16), Text('NO ANNOUNCEMENTS', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2))]));
}
