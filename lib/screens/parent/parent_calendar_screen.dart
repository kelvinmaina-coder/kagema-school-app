import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ParentCalendarScreen extends StatefulWidget {
  const ParentCalendarScreen({super.key});

  @override
  State<ParentCalendarScreen> createState() => _ParentCalendarScreenState();
}

class _ParentCalendarScreenState extends State<ParentCalendarScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      // MIGRATED: Now pulls events from Supabase
      final events = await SupabaseService.instance.getEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Calendar Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('School Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
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
              : _events.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final e = _events[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getEventColor(e['type']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.event, color: _getEventColor(e['type'])),
                            ),
                            title: Text(e['title'] ?? 'Event', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${e['date'] ?? ''} • ${e['type'] ?? ''}'),
                            trailing: const Icon(Icons.info_outline, size: 20),
                            onTap: () => _showEventDetails(e),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No upcoming school events.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e['title'] ?? 'Event Details', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('${e['date'] ?? ''} | ${e['type'] ?? ''}', style: TextStyle(color: _getEventColor(e['type']), fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            Text(e['description'] ?? 'No description available.', style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(String? type) {
    switch (type) {
      case 'Exam': return Colors.red;
      case 'Holiday': return Colors.green;
      case 'Meeting': return Colors.orange;
      case 'Sports': return Colors.blue;
      default: return Colors.indigo;
    }
  }
}
