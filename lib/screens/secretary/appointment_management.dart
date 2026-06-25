import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../app_theme.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AppointmentManagementScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  final String _roleId = 'secretary';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getAppointments();
      if (mounted) {
        setState(() {
          _appointments = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDialog([Map<String, dynamic>? appointment]) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final roleColor = RoleColors.of(_roleId);
    final bool isEditing = appointment != null;
    
    final titleController = TextEditingController(text: appointment?['title']);
    final descController = TextEditingController(text: appointment?['description']);
    final visitorController = TextEditingController(text: appointment?['visitor_name']);
    DateTime selectedDate = appointment != null ? DateTime.parse(appointment['appointment_date']) : DateTime.now();
    TimeOfDay selectedTime = appointment != null ? TimeOfDay.fromDateTime(DateTime.parse(appointment['appointment_date'])) : TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 35,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(isEditing ? 'EDIT APPOINTMENT' : 'NEW APPOINTMENT', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(isEditing ? 'Update Details' : 'Add to Schedule', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)
                ),
                const SizedBox(height: 32),
                _buildInputField(dt, 'Purpose / Subject', Icons.title_rounded, titleController, roleColor),
                const SizedBox(height: 16),
                _buildInputField(dt, 'Visitor Name', Icons.person_pin_rounded, visitorController, roleColor),
                const SizedBox(height: 16),
                _buildInputField(dt, 'Additional Details', Icons.notes_rounded, descController, roleColor, maxLines: 2),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => selectedDate = date);
                        },
                        child: _buildDateTimePickerBox(dt, 'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}', Icons.calendar_today_rounded, roleColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(context: context, initialTime: selectedTime);
                          if (time != null) setState(() => selectedTime = time);
                        },
                        child: _buildDateTimePickerBox(dt, 'Time: ${selectedTime.format(context)}', Icons.access_time_rounded, roleColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      final DateTime fullDateTime = DateTime(
                        selectedDate.year, selectedDate.month, selectedDate.day,
                        selectedTime.hour, selectedTime.minute
                      );
                      
                      final data = {
                        'appointment_id': isEditing ? appointment['appointment_id'] : const Uuid().v4(),
                        'title': titleController.text.trim(),
                        'visitor_name': visitorController.text.trim(),
                        'description': descController.text.trim(),
                        'appointment_date': fullDateTime.toIso8601String(),
                        'status': appointment?['status'] ?? 'Scheduled',
                      };

                      await SupabaseService.instance.upsertAppointment(data);
                      if (mounted) {
                        Navigator.pop(context);
                        _loadAppointments();
                      }
                    },
                    child: Text(isEditing ? 'UPDATE APPOINTMENT' : 'SAVE APPOINTMENT', 
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildInputField(DT dt, String label, IconData icon, TextEditingController ctrl, Color roleColor, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: roleColor, size: 20),
      ),
    );
  }

  Widget _buildDateTimePickerBox(DT dt, String text, IconData icon, Color roleColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dt.inputBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dt.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: roleColor),
          const SizedBox(width: 10),
          FittedBox(child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: dt.textPrimary))),
        ],
      ),
    );
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
        title: const Text('APPOINTMENTS', 
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
                child: Icon(Icons.event_available_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _loadAppointments)],
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : _appointments.isEmpty
                  ? _buildEmptyState(dt)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(20, AppBar().preferredSize.height + context.pt + 20, 20, 100),
                      itemCount: _appointments.length,
                      itemBuilder: (context, index) {
                        final appt = _appointments[index];
                        final appointmentDate = DateTime.parse(appt['appointment_date']);
                        final status = appt['status'] ?? 'Scheduled';
                        final color = status == 'Completed' ? dt.success : (status == 'Cancelled' ? dt.error : dt.warning);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: theme.buildGlowContainer(
                            accentColor: color,
                            borderRadius: 28,
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              onTap: () => _showAddDialog(appt),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
                                child: Icon(Icons.event_note_rounded, color: color, size: 24),
                              ),
                              title: Text(appt['title']?.toString().toUpperCase() ?? 'APPOINTMENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary, letterSpacing: 0.5)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('${appt['visitor_name']} \n${DateFormat('MMM dd â€¢ hh:mm a').format(appointmentDate)}', 
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4, color: dt.textSecondary)
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, color: dt.iconInactive),
                                color: dt.cardBg,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onSelected: (val) async {
                                  if (val == 'delete') {
                                    await SupabaseService.instance.deleteAppointment(appt['appointment_id']);
                                    _loadAppointments();
                                  } else if (val == 'completed' || val == 'cancel') {
                                    final updated = Map<String, dynamic>.from(appt);
                                    updated['status'] = val == 'completed' ? 'Completed' : 'Cancelled';
                                    await SupabaseService.instance.upsertAppointment(updated);
                                    _loadAppointments();
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'completed', child: ListTile(leading: Icon(Icons.check_circle_rounded, color: dt.success, size: 20), title: Text('Completed', style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary)), dense: true)),
                                  PopupMenuItem(value: 'cancel', child: ListTile(leading: Icon(Icons.cancel_rounded, color: dt.warning, size: 20), title: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary)), dense: true)),
                                  PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever_rounded, color: dt.error, size: 20), title: Text('Delete', style: TextStyle(color: dt.error, fontWeight: FontWeight.bold)), dense: true)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(),
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('SCHEDULE APPOINTMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO APPOINTMENTS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
