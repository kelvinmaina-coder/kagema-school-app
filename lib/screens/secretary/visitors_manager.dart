import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class VisitorsManagerScreen extends StatefulWidget {
  const VisitorsManagerScreen({super.key});

  @override
  State<VisitorsManagerScreen> createState() => _VisitorsManagerScreenState();
}

class _VisitorsManagerScreenState extends State<VisitorsManagerScreen> {
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getVisitors();
      if (mounted) {
        setState(() {
          _visitors = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Visitor Log Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLogVisitorDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final purposeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Log New Visitor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Visitor Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    await SupabaseService.instance.insertVisitor({
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'purpose': purposeController.text.trim(),
                      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      'time_in': DateTime.now().toIso8601String(),
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      _loadVisitors();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('LOG ENTRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      appBar: AppBar(title: const Text('Visitor Logs'), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _visitors.length,
            itemBuilder: (context, index) {
              final v = _visitors[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.badge, color: Colors.white)),
                  title: Text(v['name'] ?? 'Visitor'),
                  subtitle: Text('${v['purpose']} • ${v['date']}'),
                  trailing: const Text('IN', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogVisitorDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
