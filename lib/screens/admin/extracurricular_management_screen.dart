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
  bool _isLoading = true;
  final String _roleId = 'admin';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
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

  void _showAddDialog(DT dt, Color roleColor) {
    final titleCtrl = TextEditingController();
    final statsCtrl = TextEditingController();
    String category = 'Sports';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: LiquidGlassCard(
          borderRadius: 35,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('ADD SCHOOL ACTIVITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
              const SizedBox(height: 32),
              _buildInputField(dt, 'Activity Name', Icons.groups_rounded, titleCtrl),
              const SizedBox(height: 16),
              _buildInputField(dt, 'Number of Participants', Icons.person_add_rounded, statsCtrl),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                dropdownColor: dt.cardBg,
                style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                items: ['Sports', 'Clubs', 'Music', 'Arts'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => category = v!,
                decoration: const InputDecoration(labelText: 'Classification'),
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
                  style: ElevatedButton.styleFrom(backgroundColor: roleColor, foregroundColor: Colors.white),
                  child: const Text('SAVE ACTIVITY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(DT dt, String label, IconData icon, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: RoleColors.of(_roleId))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = DT.of(context);
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('SCHOOL ACTIVITIES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          tabs: const [Tab(text: 'CLUBS', icon: Icon(Icons.groups)), Tab(text: 'SPORTS', icon: Icon(Icons.sports_basketball))]
        ),
      ),
      body: NeuralBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
            child: _isLoading
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(dt, 'Clubs'),
                    _buildList(dt, 'Sports'),
                  ],
                ),
          ),
        ),
      ),
      floatingActionButton: RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(dt, roleColor), 
          icon: const Icon(Icons.add), 
          label: const Text('ADD ACTIVITY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
          backgroundColor: roleColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildList(DT dt, String cat) {
    final filtered = _activities.where((a) => a['category'] == cat || (cat == 'Clubs' && a['category'] == 'Arts')).toList();
    if (filtered.isEmpty) return _buildEmptyState(dt);
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final a = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12), 
          child: LiquidGlassCard(
            accentColor: KagemaColors.secretaryViolet, 
            borderRadius: 24, 
            padding: EdgeInsets.zero, 
            child: ListTile(
              leading: CircleAvatar(backgroundColor: dt.roleSoftBg(KagemaColors.secretaryViolet), child: const Icon(Icons.star_rounded, color: KagemaColors.secretaryViolet)), 
              title: Text(a['title'] ?? 'Activity', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)), 
              subtitle: Text(a['stats'] ?? '0 Students', style: TextStyle(color: dt.textSecondary))
            )
          )
        );
      },
    );
  }

  Widget _buildEmptyState(DT dt) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.layers_clear, size: 80, color: dt.iconInactive), const SizedBox(height: 16), Text('NO ACTIVITIES RECORDED', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2))]));
}
