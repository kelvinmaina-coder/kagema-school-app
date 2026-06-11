import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class DisciplineManagementScreen extends StatefulWidget {
  const DisciplineManagementScreen({super.key});

  @override
  State<DisciplineManagementScreen> createState() => _DisciplineManagementScreenState();
}

class _DisciplineManagementScreenState extends State<DisciplineManagementScreen> {
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getClassStatistics(); // Simplified fetch for now
      if (mounted) {
        setState(() {
          _incidents = data;
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
        title: const Text('Discipline Records', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade600]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _incidents.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _incidents.length,
                  itemBuilder: (context, index) {
                    final incident = _incidents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          child: const Icon(Icons.gavel_rounded, color: Colors.red),
                        ),
                        title: Text(incident['title'] ?? 'Incident Entry', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(incident['subtitle'] ?? 'Action pending cloud review'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () => _showIncidentDetail(incident),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddIncidentDialog,
        label: const Text('Log Incident', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_alert_rounded),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddIncidentDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report New Incident', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.primaryColor)),
            const SizedBox(height: 24),
            const TextField(decoration: InputDecoration(labelText: 'Pupil Admission Number', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Description of Event', border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
                child: const Text('POST TO CLOUD LOG'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showIncidentDetail(Map<String, dynamic> incident) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gavel_rounded, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            Text(incident['title'] ?? 'Record Detail', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(incident['subtitle'] ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_rounded, size: 80, color: Colors.green),
          SizedBox(height: 16),
          Text('All clear! No cloud-synced incidents.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
