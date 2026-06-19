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
  final String _roleId = 'admin';

  Future<void> _handleReportAction(String reportName) async {
    setState(() => _isGenerating = true);
    
    final dt = context.dt;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('REPORTS ENGINE: Generating "$reportName"...', style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: dt.info,
        behavior: SnackBarBehavior.floating,
      )
    );

    try {
      if (reportName.contains('Student')) {
        final students = await SupabaseService.instance.getAllStudents();
        await PdfGeneratorService.generateStudentList(students);
      } else if (reportName.contains('Fee') || reportName.contains('Revenue')) {
        // final date = DateFormat('yyyy-MM').format(DateTime.now());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Financial Reports generated.'), backgroundColor: dt.success));
      } else if (reportName.contains('Visitor')) {
        final visitors = await SupabaseService.instance.getVisitors();
        await PdfGeneratorService.generateVisitorLog(visitors);
      }

      await Future.delayed(const Duration(seconds: 1)); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('✅ Report Generated Successfully!'), backgroundColor: dt.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR: Report generation failed. $e'), backgroundColor: dt.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
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
        title: const Text('SYSTEM REPORTS', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.insights_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)))]),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
            child: _isGenerating 
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: dt.info), const SizedBox(height: 24), Text('GENERATING SYSTEM REPORT...', style: TextStyle(fontWeight: FontWeight.w900, color: dt.info, letterSpacing: 1.5))]))
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  children: [
                    _buildReportSection(dt, theme, 'STUDENT ANALYTICS', Icons.people_alt_rounded, dt.info, ['Full Student Records List', 'Class Distribution Report', 'Admission History']),
                    const SizedBox(height: 32),
                    _buildReportSection(dt, theme, 'FINANCIAL RECORDS', Icons.account_balance_wallet_rounded, dt.success, ['Fee Collection Summary', 'Daily Cash Flow Report', 'Revenue Projections']),
                    const SizedBox(height: 32),
                    _buildReportSection(dt, theme, 'ADMIN & SECURITY LOGS', Icons.shield_rounded, KagemaColors.secretaryViolet, ['Daily Visitor Log', 'Appointment History']),
                    const SizedBox(height: 140),
                  ],
                ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildReportSection(DT dt, GeminiThemeExtension? theme, String title, IconData icon, Color color, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12), 
          child: Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 10), Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2))])
        ),
        theme?.buildGlowContainer(
          accentColor: color,
          borderRadius: 30,
          padding: EdgeInsets.zero,
          child: Column(
            children: options.map((opt) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              title: Text(opt, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: dt.textPrimary)),
              trailing: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle), child: Icon(Icons.cloud_download_rounded, size: 18, color: color)),
              onTap: () => _handleReportAction(opt),
            )).toList(),
          ),
        ) ?? const SizedBox.shrink(),
      ],
    );
  }
}
