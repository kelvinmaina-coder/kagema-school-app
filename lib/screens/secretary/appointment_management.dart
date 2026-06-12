import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
        SnackBar(content: Text('Error loading appointments: $e')),
      );
    }
  }

  void _showAddDialog([Map<String, dynamic>? appointment]) {
    final bool isEditing = appointment != null;
    final titleController = TextEditingController(text: appointment?['title']);
    final descController = TextEditingController(text: appointment?['description']);
    final visitorController = TextEditingController(text: appointment?['visitor_name']);
    DateTime selectedDate = appointment != null ? DateTime.parse(appointment['appointment_date']) : DateTime.now();
    TimeOfDay selectedTime = appointment != null ? TimeOfDay.fromDateTime(DateTime.parse(appointment['appointment_date'])) : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Appointment' : 'Schedule Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Purpose/Subject')),
                TextField(controller: visitorController, decoration: const InputDecoration(labelText: 'Visitor Name')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setDialogState(() => selectedDate = date);
                  },
                ),
                ListTile(
                  title: Text('Time: ${selectedTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: selectedTime);
                    if (time != null) setDialogState(() => selectedTime = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
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
              child: Text(isEditing ? 'Update' : 'Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Registry', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAppointments)],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _appointments.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final appt = _appointments[index];
                      final dt = DateTime.parse(appt['appointment_date']);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          onTap: () => _showAddDialog(appt),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.teal.shade100, shape: BoxShape.circle),
                            child: const Icon(Icons.event, color: Colors.teal),
                          ),
                          title: Text(appt['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${appt['visitor_name']} • ${DateFormat('MMM dd, hh:mm a').format(dt)}'),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
                              const PopupMenuItem(value: 'cancel', child: Text('Cancel Appointment')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.event),
        label: const Text('Schedule New', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.teal.shade200),
          const SizedBox(height: 16),
          const Text('No appointments scheduled', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tap "Schedule New" to add a visitor.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
