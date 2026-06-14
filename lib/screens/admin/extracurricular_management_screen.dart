import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class ExtracurricularManagementScreen extends StatefulWidget {
  const ExtracurricularManagementScreen({super.key});

  @override
  State<ExtracurricularManagementScreen> createState() => _ExtracurricularManagementScreenState();
}

class _ExtracurricularManagementScreenState extends State<ExtracurricularManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _activities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = await SupabaseService.instance.getActivities();
      if (mounted) {
        setState(() {
          _activities = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
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
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
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
                const Text('AUTHORIZE SCHOOL ACTIVITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
                const SizedBox(height: 32),
                _buildNeuralField('Activity Name', Icons.hub_rounded, titleCtrl, theme),
                const SizedBox(height: 16),
                _buildNeuralField('Participants (e.g. 24 Pupils)', Icons.groups_rounded, statsCtrl, theme),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  items: ['Sports', 'Clubs', 'Music', 'Arts'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => category = v!,
                  decoration: InputDecoration(labelText: 'Classification', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))),
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
                        if (mounted) { Navigator.pop(context); _loadData(); }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('COMMIT TO CLOUD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeuralField(String label, IconData icon, TextEditingController ctrl, ThemeData theme) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.pink), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Activity Matrix', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.primaryColor, Colors.pink.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)))),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'CLUBS', icon: Icon(Icons.groups)), Tab(text: 'SPORTS', icon: Icon(Icons.sports_basketball))]),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
          child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.pink))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildList(theme, gemini, 'Clubs'),
                  _buildList(theme, gemini, 'Sports'),
                ],
              ),
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(borderRadius: 30, borderThickness: 2, backgroundColor: Colors.pink.shade700, padding: EdgeInsets.zero, child: FloatingActionButton.extended(onPressed: _showAddDialog, icon: const Icon(Icons.add), label: const Text('Add Neural Record', style: TextStyle(fontWeight: FontWeight.w900)))),
    );
  }

  Widget _buildList(ThemeData theme, GeminiThemeExtension? gemini, String cat) {
    final filtered = _activities.where((a) => a['category'] == cat || (cat == 'Clubs' && a['category'] == 'Arts')).toList();
    if (filtered.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final a = filtered[index];
        final content = ListTile(leading: const CircleAvatar(backgroundColor: Colors.pink, child: Icon(Icons.hub, color: Colors.white)), title: Text(a['title'] ?? 'Activity', style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(a['stats'] ?? '0 Nodes'));
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content));
      },
    );
  }

  Widget _buildEmptyState() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.layers_clear, size: 80, color: Colors.grey), SizedBox(height: 16), Text('NO ACTIVITIES LOGGED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))]));
}
