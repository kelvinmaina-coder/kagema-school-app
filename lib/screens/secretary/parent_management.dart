import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ParentManagementScreen extends StatefulWidget {
  const ParentManagementScreen({super.key});

  @override
  State<ParentManagementScreen> createState() => _ParentManagementScreenState();
}

class _ParentManagementScreenState extends State<ParentManagementScreen> {
  List<Map<String, dynamic>> _parents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParents();
  }

  Future<void> _loadParents() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getParents();
      if (mounted) {
        setState(() {
          _parents = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load Parents Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian Records'), backgroundColor: Colors.blueGrey),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _parents.length,
            itemBuilder: (context, index) {
              final p = _parents[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.family_restroom)),
                  title: Text(p['name'] ?? 'Guardian'),
                  subtitle: Text(p['phone'] ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
