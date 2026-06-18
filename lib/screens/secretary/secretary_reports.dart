import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/pdf_generator_service.dart';
import '../../app_theme.dart';

class SecretaryReportsScreen extends StatefulWidget {
  const SecretaryReportsScreen({super.key});

  @override
  State<SecretaryReportsScreen> createState() => _SecretaryReportsScreenState();
}

class _SecretaryReportsScreenState extends State<SecretaryReportsScreen> {
  bool _isGenerating = false;

  Future<void> _handleReportAction(String reportName) async {
    setState(() => _isGenerating = true);
    
    try {
      if (reportName == 'Current Student List') {
        final students = await SupabaseService.instance.getAllStudents();
        await PdfGeneratorService.generateStudentList(students);
      } else if (reportName == 'Daily Visitor Summary') {
        final visitors = await SupabaseService.instance.getVisitors();
        await PdfGeneratorService.generateVisitorLog(visitors);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('System: Exporting "$reportName"...'), backgroundColor: Colors.indigo)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error connecting to system'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Administrative Center', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.primaryColor, Colors.indigo.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)))),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isGenerating 
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : ListView(
              padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, left: 20, right: 20, bottom: 40),
              children: [
                _reportCategory(context, theme, gemini, 'ENROLLMENT RECORDS', Icons.person_add_rounded, Colors.blue, ['Current Student List', 'Class Stream Summary']),
                const SizedBox(height: 32),
                _reportCategory(context, theme, gemini, 'OFFICE LOGS', Icons.business_center_rounded, Colors.teal, ['Daily Visitor Summary', 'Appointment History']),
                const SizedBox(height: 32),
                _reportCategory(context, theme, gemini, 'COMMUNICATION', Icons.campaign_rounded, Colors.orange, ['Broadcast Archive', 'Parent Notification Log']),
              ],
            ),
      ),
    );
  }

  Widget _reportCategory(BuildContext context, ThemeData theme, GeminiThemeExtension? gemini, String title, IconData icon, Color color, List<String> items) {
    final content = Column(
      children: items.map((item) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(item, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        trailing: Icon(Icons.download_for_offline_rounded, size: 20, color: color),
        onTap: () => _handleReportAction(item),
      )).toList(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 8, bottom: 12), child: Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 10), Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2))])),
        gemini?.buildGlowContainer(borderRadius: 30, borderThickness: 1.5, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content),
      ],
    );
  }
}
