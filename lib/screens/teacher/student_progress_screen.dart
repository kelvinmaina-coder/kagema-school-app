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
    setState(() => _isLoading = true);
    try {
      // Pull latest performance analytics from Supabase
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
        title: const Text('Performance Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.cyan.shade700]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.only(
                top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20,
                left: 20, right: 20, bottom: 40
              ),
              children: [
                _buildAnalyticsHero(theme),
                const SizedBox(height: 32),
                _buildSectionLabel('CLOUD-SYNCED INSIGHTS'),
                const SizedBox(height: 16),
                ..._progressData.map((item) => _buildInsightCard(theme, item)),
              ],
            ),
      ),
    );
  }

  Widget _buildAnalyticsHero(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_graph_rounded, size: 50, color: Colors.cyan),
          const SizedBox(height: 16),
          const Text('OVERALL ACADEMIC INDEX', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text('88.4%', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: theme.primaryColor)),
          const Text('Cloud analysis shows +4.2% growth this month', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(ThemeData theme, Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          child: const Icon(Icons.bolt_rounded, color: Colors.orange),
        ),
        title: Text(item['title'] ?? 'Insight', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item['subtitle'] ?? ''),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5));
  }
}
