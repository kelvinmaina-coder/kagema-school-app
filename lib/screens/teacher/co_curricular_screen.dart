import 'package:flutter/material.dart';
import '../../app_theme.dart';

class CoCurricularScreen extends StatelessWidget {
  const CoCurricularScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clubs & Coaching', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel(theme, 'MY RESPONSIBILITIES'),
              const SizedBox(height: 16),
              _buildDutyCard('Drama Club Patron', '35 Members', 'Meets: Thursdays 4:00 PM', Colors.purple),
              const SizedBox(height: 12),
              _buildDutyCard('Football Head Coach', '22 Players', 'Next Match: Sat vs St. Peters', Colors.green),
              const SizedBox(height: 32),
              _buildSectionLabel(theme, 'UPCOMING EVENTS'),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const ListTile(
                  leading: Icon(Icons.event, color: Colors.orange),
                  title: Text('Inter-School Music Fest', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Nov 15, 2023 • City Hall'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const ListTile(
                  leading: Icon(Icons.event, color: Colors.blue),
                  title: Text('Annual Sports Day', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Dec 02, 2023 • Main Field'),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Add Club Record'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor.withOpacity(0.5), letterSpacing: 1.5));
  }

  Widget _buildDutyCard(String title, String stats, String detail, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.group_work, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$stats\n$detail'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
