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

  void _showLogVisitorDialog({Map<String, dynamic>? visitorToEdit}) {
    final theme = Theme.of(context);
    final isEditing = visitorToEdit != null;
    final nameController = TextEditingController(text: visitorToEdit?['name']);
    final phoneController = TextEditingController(text: visitorToEdit?['phone']);
    final purposeController = TextEditingController(text: visitorToEdit?['purpose']);

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
              Text(isEditing ? 'Update Visitor Info' : 'Log New Visitor', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green)),
              const SizedBox(height: 24),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Visitor Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 16),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder(), prefixIcon: Icon(Icons.info_outline))),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final data = {
                        'name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'purpose': purposeController.text.trim(),
                        'date': visitorToEdit?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        'time_in': visitorToEdit?['time_in'] ?? DateTime.now().toIso8601String(),
                      };
                      
                      if (isEditing) {
                        await SupabaseService.instance.client.from('visitors').update(data).eq('visitor_id', visitorToEdit['visitor_id']);
                      } else {
                        await SupabaseService.instance.insertVisitor(data);
                      }
                      
                      if (mounted) {
                        Navigator.pop(context);
                        _loadVisitors();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(isEditing ? 'UPDATE RECORD' : 'LOG ENTRY', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteVisitor(Map<String, dynamic> v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text('Remove visitor log for "${v['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.client.from('visitors').delete().eq('visitor_id', v['visitor_id']);
      _loadVisitors();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Visitor Logs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green.shade800, Colors.green.shade400]),
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
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _visitors.length,
                itemBuilder: (context, index) {
                  final v = _visitors[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: const Icon(Icons.badge, color: Colors.green)),
                      title: Text(v['name'] ?? 'Visitor', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${v['purpose']} • ${v['date']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('IN', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'edit') _showLogVisitorDialog(visitorToEdit: v);
                              if (val == 'delete') _deleteVisitor(v);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, size: 20), title: Text('Edit'), dense: true)),
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
        onPressed: () => _showLogVisitorDialog(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Log Visitor', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
