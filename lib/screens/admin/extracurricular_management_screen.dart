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
    setState(() => isLoading = true);
    try {
      final clubs = await SupabaseService.instance.getClubs();
      if (mounted) {
        setState(() {
          _clubs = clubs;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Extracurricular Load Error: $e");
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
        title: const Text('Extracurricular Activities', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Clubs & Societies', icon: Icon(Icons.groups_rounded)),
            Tab(text: 'Sports Teams', icon: Icon(Icons.sports_soccer_rounded)),
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
                    _buildSportsPlaceholder(theme),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Add Activity'),
        icon: const Icon(Icons.add_circle_outline_rounded),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildClubsList(ThemeData theme) {
    if (_clubs.isEmpty) return const Center(child: Text('No clubs found.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _clubs.length,
      itemBuilder: (context, index) {
        final club = _clubs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.group_work_rounded, color: theme.primaryColor),
            ),
            title: Text(club['name'] ?? 'Unknown Club', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Patron: ${club['patron'] ?? 'Not Assigned'} • Members: ${club['members'] ?? 0}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildSportsPlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_rounded, size: 80, color: theme.primaryColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('Sports Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Track team rosters, fixtures, and results.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
