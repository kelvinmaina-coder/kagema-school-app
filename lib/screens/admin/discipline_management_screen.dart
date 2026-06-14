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
        title: const Text('Discipline Records', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)
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
              colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.gavel_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
            : _incidents.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: _incidents.length,
                  itemBuilder: (context, index) {
                    final incident = _incidents[index];
                    final content = ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.gavel_rounded, color: Colors.red, size: 24),
                      ),
                      title: Text(incident['title'] ?? 'Incident Entry', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${incident['date']} • ADM: ${incident['admission_number']}', 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
                        ),
                      ),
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
                  },
                ),
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: Colors.blueGrey.shade800,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddIncidentDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_alert_rounded),
          label: const Text('Log Discipline Incident', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  void _showAddIncidentDialog({Map<String, dynamic>? incidentToEdit}) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
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
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: gemini?.buildCreativeBackground(
          isDark: theme.brightness == Brightness.dark,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text(isEditing ? 'MODIFY RECORD' : 'LOG DISCIPLINE ALERT', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                  ),
                  const SizedBox(height: 8),
                  Text(isEditing ? 'Update Incident Details' : 'New Conduct Report', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                  const SizedBox(height: 32),
                  _buildInputField('Student Admission Number', Icons.badge_outlined, admCtrl, theme),
                  const SizedBox(height: 16),
                  _buildInputField('Incident Classification', Icons.title_rounded, titleCtrl, theme),
                  const SizedBox(height: 16),
                  _buildInputField('Incident Description', Icons.notes_rounded, descCtrl, theme, maxLines: 3),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
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
                          
                          await SupabaseService.instance.upsertIncident(data);
                          if (mounted) {
                            Navigator.pop(context);
                            _loadIncidents();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade800, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: Text(isEditing ? 'COMMIT UPDATES' : 'SAVE TO RECORDS', 
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ) ?? const SizedBox(),
      ),
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController ctrl, ThemeData theme, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.blueGrey, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _deleteIncident(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Record?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to erase this discipline entry for ADM: ${item['admission_number']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
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
          Text('ALL CLEAR: NO INCIDENTS RECORDED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
