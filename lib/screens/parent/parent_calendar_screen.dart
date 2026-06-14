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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
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
        title: const Text('School Calendar', 
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
              colors: [theme.primaryColor, Colors.indigo.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
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
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
              : _events.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final e = _events[index];
                        final color = _getEventColor(e['type']);
                        final content = ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.event_note_rounded, color: color, size: 24),
                          ),
                          title: Text(e['title'] ?? 'School Event', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${e['date'] ?? ''} • ${e['type'] ?? ''}', 
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
                            ),
                          ),
                          trailing: const Icon(Icons.info_outline_rounded, size: 20, color: Colors.grey),
                          onTap: () => _showEventDetails(e),
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
          Text('NO UPCOMING EVENTS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> e) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: gemini?.buildCreativeBackground(
          isDark: theme.brightness == Brightness.dark,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 32),
                Text('EVENT DETAILS', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
                const SizedBox(height: 12),
                Text(e['title'] ?? 'Event Information', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _getEventColor(e['type']).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(e['type']?.toString().toUpperCase() ?? 'GENERAL', 
                    style: TextStyle(color: _getEventColor(e['type']), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)
                  ),
                ),
                const SizedBox(height: 32),
                Text(e['description'] ?? 'No additional information available for this event.', 
                  style: TextStyle(fontSize: 15, height: 1.6, color: theme.colorScheme.onSurface.withOpacity(0.8), fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                    child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ) ?? const SizedBox(),
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
