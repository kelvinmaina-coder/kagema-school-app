import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
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
    final gemini = theme.extension<GeminiThemeExtension>();
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
                  Text(isEditing ? 'MODIFY CHARACTER LOG' : 'RECORD NEURAL OBSERVATION', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                  ),
                  const SizedBox(height: 8),
                  Text(isEditing ? 'Update Profile' : 'Identity Assessment', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                  const SizedBox(height: 32),
                  _buildNeuralField('Pupil Identity / ADM', Icons.person_pin_rounded, nameCtrl, theme),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    items: ['Positive', 'Warning', 'Incident'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => selectedCategory = v!,
                    decoration: _neuralInputDecoration('Observation Matrix', Icons.category_rounded, theme),
                  ),
                  const SizedBox(height: 16),
                  _buildNeuralField('Detailed Intelligence', Icons.notes_rounded, descCtrl, theme, maxLines: 3),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade800, 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: Text(isEditing ? 'COMMIT UPDATES' : 'AUTHORIZE PORTAL SYNC', 
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

  InputDecoration _neuralInputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.blueGrey.shade700, size: 20),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }

  Widget _buildNeuralField(String label, IconData icon, TextEditingController ctrl, ThemeData theme, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: _neuralInputDecoration(label, icon, theme),
    );
  }

  Future<void> _deleteIncident(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Purge Record?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to erase this behavior entry for ${item['student_name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ABORT')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('PURGE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
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
        title: const Text('Behavior Matrix', 
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
                child: Icon(Icons.psychology_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
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
                        final item = _incidents[index];
                        final isPositive = item['category'] == 'Positive';
                        final color = isPositive ? Colors.green : Colors.red;
                        
                        final content = ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(
                              isPositive ? Icons.auto_awesome_rounded : Icons.warning_amber_rounded,
                              color: color, size: 24,
                            ),
                          ),
                          title: Text(item['student_name'] ?? 'Pupil Entity', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(item['description'] ?? 'No intelligence provided.', 
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item['date'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500)),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onSelected: (val) {
                                  if (val == 'edit') _showIncidentDialog(incidentToEdit: item);
                                  if (val == 'delete') _deleteIncident(item);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note_rounded, size: 20), title: Text('Edit Info', style: TextStyle(fontWeight: FontWeight.bold)), dense: true)),
                                  const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20), title: Text('Purge', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), dense: true)),
                                ],
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
          onPressed: () => _showIncidentDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_moderator_rounded),
          label: const Text('Log Neural Behavior', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
          Text('CHARACTER MATRIX CLEAN', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
