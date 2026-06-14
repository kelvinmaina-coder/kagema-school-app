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

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getAppointments();
      setState(() {
        _appointments = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Neural Link Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddDialog([Map<String, dynamic>? appointment]) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
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
                  Text(isEditing ? 'MODIFY SCHEDULE' : 'INITIATE APPOINTMENT', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                  ),
                  const SizedBox(height: 8),
                  Text(isEditing ? 'Update Protocol' : 'Neural Schedule Entry', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                  const SizedBox(height: 32),
                  _buildNeuralField('Purpose / Subject', Icons.title_rounded, titleController, theme),
                  const SizedBox(height: 16),
                  _buildNeuralField('Visitor Identity', Icons.person_pin_rounded, visitorController, theme),
                  const SizedBox(height: 16),
                  _buildNeuralField('Intelligence Details', Icons.notes_rounded, descController, theme, maxLines: 2),
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
                          child: _buildDateTimePickerBox('Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}', Icons.calendar_today_rounded, theme),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(context: context, initialTime: selectedTime);
                            if (time != null) setState(() => selectedTime = time);
                          },
                          child: _buildDateTimePickerBox('Time: ${selectedTime.format(context)}', Icons.access_time_rounded, theme),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: Text(isEditing ? 'COMMIT UPDATES' : 'AUTHORIZE SCHEDULE', 
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

  Widget _buildNeuralField(String label, IconData icon, TextEditingController ctrl, ThemeData theme, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.orange.shade800, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDateTimePickerBox(String text, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          FittedBox(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Appointment Matrix', 
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
              colors: [Colors.orange.shade900, Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.event_available_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _loadAppointments)],
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : _appointments.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 160, 20, 100),
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final appt = _appointments[index];
                      final dt = DateTime.parse(appt['appointment_date']);
                      final status = appt['status'] ?? 'Scheduled';
                      final color = status == 'Completed' ? Colors.green : (status == 'Cancelled' ? Colors.red : Colors.orange);
                      
                      final content = ListTile(
                        onTap: () => _showAddDialog(appt),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.event_note_rounded, color: color, size: 24),
                        ),
                        title: Text(appt['title'] ?? 'Neural Session', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${appt['visitor_name']} \n${DateFormat('MMM dd • hh:mm a').format(dt)}', 
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)
                          ),
                        ),
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'completed', child: ListTile(leading: Icon(Icons.check_circle_rounded, color: Colors.green), title: Text('Verified'), dense: true)),
                            const PopupMenuItem(value: 'cancel', child: ListTile(leading: Icon(Icons.cancel_rounded, color: Colors.orange), title: Text('Cancel'), dense: true)),
                            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever_rounded, color: Colors.red), title: Text('Purge'), dense: true)),
                          ],
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
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: Colors.orange.shade800,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Schedule Quantum Visit', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('NO NEURAL APPOINTMENTS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
