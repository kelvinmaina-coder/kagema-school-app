import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
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
      final data = await SupabaseService.instance.getIncidents();
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
                        subtitle: Text('${incident['date']} • ADM: ${incident['admission_number']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                              onPressed: () => _showAddIncidentDialog(incidentToEdit: incident),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              onPressed: () => _deleteIncident(incident),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIncidentDialog(),
        label: const Text('Log Incident', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_alert_rounded),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddIncidentDialog({Map<String, dynamic>? incidentToEdit}) {
    final theme = Theme.of(context);
    final isEditing = incidentToEdit != null;
    final admCtrl = TextEditingController(text: incidentToEdit?['admission_number']);
    final titleCtrl = TextEditingController(text: incidentToEdit?['title']);
    final descCtrl = TextEditingController(text: incidentToEdit?['description']);

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditing ? 'Modify Incident Report' : 'Report New Incident', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade900)),
              const SizedBox(height: 24),
              TextField(controller: admCtrl, decoration: const InputDecoration(labelText: 'Pupil Admission Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge))),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Incident Type (e.g. Lateness)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title))),
              const SizedBox(height: 16),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Detailed Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)), maxLines: 3),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (admCtrl.text.isNotEmpty && titleCtrl.text.isNotEmpty) {
                      final data = {
                        'admission_number': admCtrl.text.trim(),
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'date': incidentToEdit?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      };
                      if (isEditing) {
                        data['incident_id'] = incidentToEdit['incident_id'];
                      } else {
                        data['incident_id'] = 'INC-${const Uuid().v4().substring(0, 8).toUpperCase()}';
                      }
                      
                      await SupabaseService.instance.upserIncident(data); // Typo in my previous upsert name? I'll check SupabaseService
                      if (mounted) {
                        Navigator.pop(context);
                        _loadIncidents();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(isEditing ? 'UPDATE REPORT' : 'POST TO CLOUD LOG', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteIncident(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expunge Record?'),
        content: Text('Delete this discipline entry for ADM: ${item['admission_number']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.deleteIncident(item['incident_id'].toString());
      _loadIncidents();
    }
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
