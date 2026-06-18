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
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Student Analytics', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: Colors.white)
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
              colors: [theme.primaryColor, Colors.cyan.shade900],
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
                child: Icon(Icons.query_stats_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : ListView(
              padding: EdgeInsets.only(
                top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20,
                left: 20, right: 20, bottom: 40
              ),
              children: [
                _buildAnalyticsHero(theme, gemini),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('PERFORMANCE INSIGHTS', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2.5)
                  ),
                ),
                const SizedBox(height: 16),
                ..._progressData.map((item) => _buildInsightCard(theme, gemini, item)),
              ],
            ),
      ),
    );
  }

  Widget _buildAnalyticsHero(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.auto_graph_rounded, size: 40, color: Colors.cyan),
        ),
        const SizedBox(height: 20),
        const Text('AVERAGE PERFORMANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
        const SizedBox(height: 12),
        const Text('88.4%', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Text('IMPROVEMENT: +4.2%', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 35,
      borderThickness: 2,
      backgroundColor: theme.cardColor.withOpacity(0.9),
      padding: const EdgeInsets.all(32),
      child: content,
    ) ?? Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(30)),
      child: content,
    );
  }

  Widget _buildInsightCard(ThemeData theme, GeminiThemeExtension? gemini, Map<String, dynamic> item) {
    final content = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.tips_and_updates_rounded, color: Colors.orange, size: 24),
      ),
      title: Text(item['title'] ?? 'Insight', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(item['subtitle'] ?? '', style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
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
  }
}
