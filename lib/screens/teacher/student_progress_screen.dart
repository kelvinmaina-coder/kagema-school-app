import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _progressData = [];
  final String _roleId = 'teacher';

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getActionableInsights();
      if (mounted) {
        setState(() {
          _progressData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('STUDENT ANALYTICS', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
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
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.query_stats_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
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
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20,
                  left: 20, right: 20, bottom: 40
                ),
                children: [
                  _buildAnalyticsHero(dt, theme, roleColor),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('PERFORMANCE INSIGHTS', 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2.5)
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._progressData.map((item) => _buildInsightCard(dt, theme, item, roleColor)),
                ],
              ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildAnalyticsHero(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    return theme?.buildGlowContainer(
      accentColor: KagemaColors.staffSky,
      borderRadius: 35,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          RolePlasma(
            color: KagemaColors.staffSky,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.staffSky), shape: BoxShape.circle),
              child: const Icon(Icons.auto_graph_rounded, size: 40, color: KagemaColors.staffSky),
            ),
          ),
          const SizedBox(height: 20),
          Text('AVERAGE PERFORMANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text('88.4%', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1, color: dt.textPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.teacherGreen), borderRadius: BorderRadius.circular(10)),
            child: const Text('IMPROVEMENT: +4.2%', style: TextStyle(fontSize: 10, color: KagemaColors.teacherGreen, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildInsightCard(DT dt, GeminiThemeExtension? theme, Map<String, dynamic> item, Color roleColor) {
    final accent = item['type'] == 'success' ? KagemaColors.teacherGreen : KagemaColors.accountantAmber;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: theme?.buildGlowContainer(
        accentColor: accent,
        borderRadius: 28,
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: dt.roleSoftBg(accent), shape: BoxShape.circle),
            child: Icon(Icons.tips_and_updates_rounded, color: accent, size: 24),
          ),
          title: Text(item['title'] ?? 'Insight', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary, letterSpacing: 0.5)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(item['subtitle'] ?? '', style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: dt.textSecondary)),
          ),
          trailing: Icon(Icons.chevron_right_rounded, size: 24, color: dt.iconInactive),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }
}
