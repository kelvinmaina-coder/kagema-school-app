import 'package:flutter/material.dart';
import '../../models/school_models.dart';
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
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getRecentIncidents();
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

  void _addRecord() {
    // Implementation for adding a new behavior record to Supabase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Behavior recording module active.'))
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavior & Discipline'),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _incidents.length,
                itemBuilder: (context, index) {
                  final item = _incidents[index];
                  final isPositive = item['category'] == 'Positive';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        isPositive ? Icons.thumb_up_rounded : Icons.warning_rounded,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      title: Text(item['student_name'] ?? 'Pupil'),
                      subtitle: Text(item['description'] ?? ''),
                      trailing: Text(item['date'] ?? ''),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        backgroundColor: Colors.blueGrey.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
