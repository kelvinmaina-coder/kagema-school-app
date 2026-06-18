import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/pdf_generator_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class ReportsModuleScreen extends StatefulWidget {
  const ReportsModuleScreen({super.key});

  @override
  State<ReportsModuleScreen> createState() => _ReportsModuleScreenState();
}

class _ReportsModuleScreenState extends State<ReportsModuleScreen> {
  bool _isGenerating = false;

  Future<void> _handleReportAction(String reportName) async {
    setState(() => _isGenerating = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('REPORTS ENGINE: Generating "$reportName"...'),
        backgroundColor: Colors.cyan.shade900,
        behavior: SnackBarBehavior.floating,
      )
    );

    try {
      if (reportName.contains('Student')) {
        final students = await SupabaseService.instance.getAllStudents();
        await PdfGeneratorService.generateStudentList(students);
      } else if (reportName.contains('Fee') || reportName.contains('Revenue')) {
        final date = DateFormat('yyyy-MM').format(DateTime.now());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Financial Reports generated.')));
      } else if (reportName.contains('Visitor')) {
        final visitors = await SupabaseService.instance.getVisitors();
        await PdfGeneratorService.generateVisitorLog(visitors);
      }

      await Future.delayed(const Duration(seconds: 1)); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Report Generated Successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR: Report generation failed. $e'), backgroundColor: Colors.red),
        );
      }
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
        title: const Text('System Reports', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: Colors.white)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.cyan.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.insights_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isGenerating 
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Colors.cyan), SizedBox(height: 24), Text('GENERATING SYSTEM REPORT...', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.cyan, letterSpacing: 1.5))]))
          : ListView(
              padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, left: 20, right: 20, bottom: 40),
              children: [
                _buildReportSection(context, gemini, 'STUDENT ANALYTICS', Icons.people_alt_rounded, Colors.blue, ['Full Student Records List', 'Class Distribution Report', 'Admission History']),
                const SizedBox(height: 32),
                _buildReportSection(context, gemini, 'FINANCIAL RECORDS', Icons.account_balance_wallet_rounded, Colors.green, ['Fee Collection Summary', 'Daily Cash Flow Report', 'Revenue Projections']),
                const SizedBox(height: 32),
                _buildReportSection(context, gemini, 'ADMIN & SECURITY LOGS', Icons.shield_rounded, Colors.teal, ['Daily Visitor Log', 'Appointment History']),
              ],
            ),
      ),
    );
  }

  Widget _buildReportSection(BuildContext context, GeminiThemeExtension? gemini, String title, IconData icon, Color color, List<String> options) {
    final theme = Theme.of(context);
    final content = Column(
      children: options.map((opt) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(opt, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        trailing: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.05), shape: BoxShape.circle), child: Icon(Icons.cloud_download_rounded, size: 18, color: color)),
        onTap: () => _handleReportAction(opt),
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
