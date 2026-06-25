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
  final String _roleId = 'teacher';

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

  void _showIncidentDialog(DT dt, Color roleColor, {Map<String, dynamic>? incidentToEdit}) {
    final isEditing = incidentToEdit != null;
    final nameCtrl = TextEditingController(text: incidentToEdit?['student_name']);
    final descCtrl = TextEditingController(text: incidentToEdit?['description']);
    String selectedCategory = incidentToEdit?['category'] ?? 'Positive';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: LiquidGlassCard(
          borderRadius: 35,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(isEditing ? 'EDIT BEHAVIOR LOG' : 'RECORD BEHAVIOR OBSERVATION', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(isEditing ? 'Sync Profile' : 'Student Assessment', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)
                ),
                const SizedBox(height: 32),
                _buildFormField(dt, 'Student Name / ADM', Icons.person_pin_rounded, nameCtrl, roleColor),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: dt.cardBg,
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  items: ['Positive', 'Warning', 'Incident'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => selectedCategory = v!,
                  decoration: _inputDecoration(dt, 'Behavior Category', Icons.category_rounded, roleColor),
                ),
                const SizedBox(height: 16),
                _buildFormField(dt, 'Observation Details', Icons.notes_rounded, descCtrl, roleColor, maxLines: 3),
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
                      backgroundColor: roleColor, 
                      foregroundColor: Colors.white, 
                    ),
                    child: Text(isEditing ? 'COMMIT SYNC' : 'SAVE AND SYNC', 
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(DT dt, String label, IconData icon, Color color) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildFormField(DT dt, String label, IconData icon, TextEditingController ctrl, Color color, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: _inputDecoration(dt, label, icon, color),
    );
  }

  Future<void> _deleteIncident(DT dt, Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Delete Record?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Text('Are you sure you want to erase this behavior entry for ${item['student_name']}?', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ABORT', style: TextStyle(color: dt.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: KagemaColors.parentRed, fontWeight: FontWeight.bold))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = DT.of(context);
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('BEHAVIOR CENTER', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
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
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.psychology_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: NeuralBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: roleColor))
                : _incidents.isEmpty
                    ? _buildEmptyState(dt)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        itemCount: _incidents.length,
                        itemBuilder: (context, index) {
                          final item = _incidents[index];
                          final isPositive = item['category'] == 'Positive';
                          final itemColor = isPositive ? KagemaColors.teacherGreen : KagemaColors.parentRed;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: LiquidGlassCard(
                              accentColor: itemColor,
                              borderRadius: 28,
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: dt.roleSoftBg(itemColor), shape: BoxShape.circle),
                                  child: Icon(
                                    isPositive ? Icons.auto_awesome_rounded : Icons.warning_amber_rounded,
                                    color: itemColor, size: 24,
                                  ),
                                ),
                                title: Text(item['student_name'] ?? 'Student', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(item['description'] ?? 'No details provided.', 
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4, color: dt.textSecondary)
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(item['date'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted)),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert_rounded, size: 20, color: dt.iconInactive),
                                      color: dt.cardBg,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      onSelected: (val) {
                                        if (val == 'edit') _showIncidentDialog(dt, roleColor, incidentToEdit: item);
                                        if (val == 'delete') _deleteIncident(dt, item);
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note_rounded, size: 20, color: dt.textPrimary), title: Text('Edit Info', style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary)), dense: true)),
                                        const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever_rounded, color: KagemaColors.parentRed, size: 20), title: Text('Remove', style: TextStyle(color: KagemaColors.parentRed, fontWeight: FontWeight.bold)), dense: true)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
      floatingActionButton: RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showIncidentDialog(dt, roleColor),
          backgroundColor: roleColor,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_moderator_rounded),
          label: const Text('LOG STUDENT BEHAVIOR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_rounded, size: 80, color: KagemaColors.teacherGreen),
          const SizedBox(height: 16),
          Text('BEHAVIOR RECORDS CLEAN', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
