import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class CoCurricularScreen extends StatefulWidget {
  const CoCurricularScreen({super.key});

  @override
  State<CoCurricularScreen> createState() => _CoCurricularScreenState();
}

class _CoCurricularScreenState extends State<CoCurricularScreen> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getActivities();
      if (mounted) {
        setState(() {
          _activities = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDialog() {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final titleCtrl = TextEditingController();
    final statsCtrl = TextEditingController();
    String category = 'Sports';

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                const Text('LOG ACTIVITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('New Activity Record', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 32),
                _buildInputField('Activity Name (e.g. Drama)', Icons.hub_rounded, titleCtrl, theme),
                const SizedBox(height: 16),
                _buildInputField('Participant Stats (e.g. 35 Students)', Icons.groups_rounded, statsCtrl, theme),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  items: ['Sports', 'Clubs', 'Music', 'Drama'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => category = v!,
                  decoration: _inputDecoration('Category', Icons.category_rounded, theme),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.isNotEmpty) {
                        final data = {
                          'title': titleCtrl.text.trim(),
                          'stats': statsCtrl.text.trim(),
                          'category': category,
                          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        };
                        await SupabaseService.instance.upsertActivity(data);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadActivities();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade800, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                    child: const Text('SAVE ACTIVITY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox(),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.purple, size: 20),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController ctrl, ThemeData theme) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: _inputDecoration(label, icon, theme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Activities', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: Colors.white)
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
              colors: [Colors.purple.shade900, Colors.purple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.sports_basketball_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.purple))
            : _activities.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.only(
                      top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20,
                      left: 20, right: 20, bottom: 100
                    ),
                    itemCount: _activities.length,
                    itemBuilder: (context, index) {
                      final act = _activities[index];
                      return _buildDutyCard(theme, gemini, act['title'], act['stats'], act['date'], Colors.purple);
                    },
                  ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: Colors.purple.shade700,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildDutyCard(ThemeData theme, GeminiThemeExtension? gemini, String title, String stats, String detail, Color color) {
    final content = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(Icons.groups_rounded, color: color, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text('$stats\nDate: $detail', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
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
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('NO ACTIVITIES RECORDED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
