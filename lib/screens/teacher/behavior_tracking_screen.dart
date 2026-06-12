import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class BehaviorTrackingScreen extends StatefulWidget {
  const BehaviorTrackingScreen({super.key});

  @override
  State<BehaviorTrackingScreen> createState() => _BehaviorTrackingScreenState();
}

class _BehaviorTrackingScreenState extends State<BehaviorTrackingScreen> {
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

  void _showIncidentDialog({Map<String, dynamic>? incidentToEdit}) {
    final theme = Theme.of(context);
    final isEditing = incidentToEdit != null;
    final nameCtrl = TextEditingController(text: incidentToEdit?['student_name']);
    final descCtrl = TextEditingController(text: incidentToEdit?['description']);
    String selectedCategory = incidentToEdit?['category'] ?? 'Positive';

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
              Text(isEditing ? 'Update Behavior Log' : 'Record Pupil Behavior', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade800)),
              const SizedBox(height: 8),
              Text(isEditing ? 'Modify this academic character record' : 'Log a character observation to the pupil portal', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Pupil Name / ADM', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: ['Positive', 'Warning', 'Incident'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => selectedCategory = v!,
                decoration: const InputDecoration(labelText: 'Observation Category', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
              ),
              const SizedBox(height: 16),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Detailed Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)), maxLines: 3),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isNotEmpty) {
                      final data = {
                        'student_name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'category': selectedCategory,
                        'date': incidentToEdit?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      };
                      
                      if (isEditing) {
                        data['incident_id'] = incidentToEdit['incident_id'];
                      } else {
                        data['incident_id'] = 'BEH-${const Uuid().v4().substring(0, 8).toUpperCase()}';
                      }

                      await SupabaseService.instance.upsertIncident(data);
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(isEditing ? 'UPDATE LOG' : 'SYNC TO PORTAL', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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
        title: const Text('Retract Record?'),
        content: Text('Are you sure you want to delete this behavior entry for ${item['student_name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.deleteIncident(item['incident_id'].toString());
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Behavior tracking', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        final item = _incidents[index];
                        final isPositive = item['category'] == 'Positive';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPositive ? Icons.auto_awesome_rounded : Icons.warning_amber_rounded,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(item['student_name'] ?? 'Pupil', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(item['description'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item['date'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'edit') _showIncidentDialog(incidentToEdit: item);
                                    if (val == 'delete') _deleteIncident(item);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note, size: 20), title: Text('Edit'), dense: true)),
                                    const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red, size: 20), title: Text('Delete'), dense: true)),
                                  ],
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
        onPressed: () => _showIncidentDialog(),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_moderator_rounded),
        label: const Text('Log Behavior', style: TextStyle(fontWeight: FontWeight.bold)),
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
          Text('No behavioral records found.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
