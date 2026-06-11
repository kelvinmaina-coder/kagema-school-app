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
      debugPrint("Appointment Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final purposeController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Schedule Appointment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Visitor Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose of Visit', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    await SupabaseService.instance.client.from('appointments').insert({
                      'visitor_name': nameController.text.trim(),
                      'purpose': purposeController.text.trim(),
                      'appointment_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                      'status': 'Scheduled',
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      _loadAppointments();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('CONFIRM SCHEDULE', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _appointments.isEmpty
            ? const Center(child: Text('No appointments scheduled.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  final a = _appointments[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.teal),
                      title: Text(a['visitor_name'] ?? 'Guest'),
                      subtitle: Text('${a['appointment_date']} • ${a['purpose'] ?? "No purpose"}'),
                      trailing: const Badge(label: Text('Scheduled'), backgroundColor: Colors.orange),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
