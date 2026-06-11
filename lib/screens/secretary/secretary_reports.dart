import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class SecretaryReportsScreen extends StatelessWidget {
  const SecretaryReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Administrative Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.indigo.shade800]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: ListView(
          padding: EdgeInsets.only(
            top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20,
            left: 20, right: 20, bottom: 40
          ),
          children: [
            _reportCategory(theme, 'ENROLLMENT ANALYTICS', Icons.person_add_rounded, Colors.blue, [
              'Current Student List',
              'Class Stream Summary',
              'Admission Log (This Term)',
            ]),
            const SizedBox(height: 24),
            _reportCategory(theme, 'OFFICE LOGS', Icons.business_center_rounded, Colors.teal, [
              'Daily Visitor Summary',
              'Appointment History',
              'Staff Attendance Export',
            ]),
            const SizedBox(height: 24),
            _reportCategory(theme, 'COMMUNICATION', Icons.campaign_rounded, Colors.orange, [
              'Broadcast Archive',
              'Parent Notification Log',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _reportCategory(ThemeData theme, String title, IconData icon, Color color, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withOpacity(0.7), letterSpacing: 1.5)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: items.map((item) => ListTile(
              title: Text(item, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.download_for_offline_rounded, size: 20, color: Colors.blueGrey),
              onTap: () {}, // Future PDF export logic
            )).toList(),
          ),
        ),
      ],
    );
  }
}
