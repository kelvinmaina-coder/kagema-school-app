import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
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
      if (mounted) {
        setState(() {
          _appointments = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Appointment Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAppointmentDialog({Map<String, dynamic>? appointment}) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: appointment?['visitor_name']);
    final phoneController = TextEditingController(text: appointment?['phone']);
    final purposeController = TextEditingController(text: appointment?['purpose']);
    final dateController = TextEditingController(text: appointment?['appointment_date']);
    final timeController = TextEditingController(text: appointment?['appointment_time']);
    String status = appointment?['status'] ?? 'Scheduled';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(appointment == null ? 'Schedule Appointment' : 'Edit Appointment', 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Visitor Name', prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose', prefixIcon: Icon(Icons.info))),
              const SizedBox(height: 12),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_month)),
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) dateController.text = DateFormat('yyyy-MM-dd').format(d);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time', prefixIcon: Icon(Icons.access_time)),
                readOnly: true,
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (t != null) timeController.text = t.format(context);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                items: ['Scheduled', 'Completed', 'Cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => status = v!,
                decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.check_circle)),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  if (appointment != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await SupabaseService.instance.deleteAppointment(appointment['appointment_id']);
                          if (mounted) {
                            Navigator.pop(context);
                            _loadAppointments();
                          }
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('DELETE'),
                      ),
                    ),
                  if (appointment != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isNotEmpty) {
                          await SupabaseService.instance.saveAppointment({
                            'appointmentId': appointment?['appointment_id'],
                            'visitorName': nameController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'purpose': purposeController.text.trim(),
                            'date': dateController.text.trim(),
                            'time': timeController.text.trim(),
                            'status': status,
                          });
                          if (mounted) {
                            Navigator.pop(context);
                            _loadAppointments();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('SYNC TO CLOUD'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
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
        title: const Text('Appointments'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.teal, Colors.teal.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadAppointments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final a = _appointments[index];
                      Color statusColor = a['status'] == 'Scheduled' ? Colors.blue : (a['status'] == 'Cancelled' ? Colors.red : Colors.green);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.event, color: Colors.white)),
                          title: Text(a['visitor_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${a['purpose']}\n${a['appointment_date']} at ${a['appointment_time']}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(a['status'] ?? 'Scheduled', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          onTap: () => _showAppointmentDialog(appointment: a),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAppointmentDialog(),
        backgroundColor: Colors.teal,
        label: const Text('New Appt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
