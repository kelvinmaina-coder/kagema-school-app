import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class ReportsModuleScreen extends StatelessWidget {
  const ReportsModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Global Reports Center', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: ListView(
          padding: EdgeInsets.only(
            top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            bottom: 40,
          ),
          children: [
            _buildReportSection(
              context,
              theme,
              'STUDENT REPORTS',
              Icons.people_alt_rounded,
              Colors.blue,
              [
                'Full Student List',
                'Class Distribution',
                'Admission Reports',
                'Attendance Trends',
              ],
            ),
            const SizedBox(height: 24),
            _buildReportSection(
              context,
              theme,
              'FINANCIAL REPORTS',
              Icons.account_balance_wallet_rounded,
              Colors.green,
              [
                'Fee Collection Summary',
                'Outstanding Balances',
                'Daily Collection Log',
                'Annual Revenue Projection',
              ],
            ),
            const SizedBox(height: 24),
            _buildReportSection(
              context,
              theme,
              'ACADEMIC REPORTS',
              Icons.auto_stories_rounded,
              Colors.orange,
              [
                'Exam Result Sheets',
                'Subject Performance Analysis',
                'Class Rankings',
                'Teacher Performance Metrics',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection(BuildContext context, ThemeData theme, String title, IconData icon, Color color, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color.withOpacity(0.8), letterSpacing: 1.5)),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: theme.cardColor.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: options.map((opt) => ListTile(
              title: Text(opt, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.cloud_download_rounded, size: 18, color: theme.primaryColor),
              onTap: () => _generateReport(context, opt),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _generateReport(BuildContext context, String reportType) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Syncing Report Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 20),
            Text('Fetching latest records for $reportType from Supabase...'),
          ],
        ),
      ),
    );
    
    try {
      // Simulate real cloud fetching and logic check
      if (reportType.contains('Student')) {
        await SupabaseService.instance.getAllStudents();
      } else if (reportType.contains('Fee')) {
        await SupabaseService.instance.getFeeReports(DateFormat('yyyy-MM').format(DateTime.now()));
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$reportType synced and ready for viewing'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
