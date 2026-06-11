import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ExtracurricularManagementScreen extends StatefulWidget {
  const ExtracurricularManagementScreen({super.key});

  @override
  State<ExtracurricularManagementScreen> createState() => _ExtracurricularManagementScreenState();
}

class _ExtracurricularManagementScreenState extends State<ExtracurricularManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _clubs = [];
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
      final clubs = await SupabaseService.instance.getInventory(); // Using inventory as placeholder for clubs
      if (mounted) {
        setState(() {
          _clubs = clubs;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('School Life & Activities', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.pink.shade700]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'CLUBS', icon: Icon(Icons.groups_rounded, size: 20)),
            Tab(text: 'SPORTS', icon: Icon(Icons.sports_soccer_rounded, size: 20)),
          ],
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildClubsList(theme),
                    _buildSportsList(theme),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddActivityDialog,
        label: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_circle_outline_rounded),
        backgroundColor: Colors.pink.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildClubsList(ThemeData theme) {
    if (_clubs.isEmpty) return _buildEmptyState('No active clubs registered.');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _clubs.length,
      itemBuilder: (context, index) {
        final club = _clubs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.pink.withOpacity(0.1),
              child: const Icon(Icons.group_work_rounded, color: Colors.pink),
            ),
            title: Text(club['name'] ?? 'Club Society', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Category: ${club['category'] ?? "Academic"}'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildSportsList(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_rounded, size: 80, color: theme.primaryColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('Sports Management Module', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Track teams and cloud-synced fixtures.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAddActivityDialog() {
    final theme = Theme.of(context);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Register New Activity', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.pink.shade700)),
            const SizedBox(height: 24),
            const TextField(decoration: InputDecoration(labelText: 'Activity Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Patron/Coach Name', border: OutlineInputBorder())),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade700, foregroundColor: Colors.white),
                child: const Text('POST TO CLOUD'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
