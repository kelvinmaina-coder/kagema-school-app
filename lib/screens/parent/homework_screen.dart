import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/school_models.dart';
import '../../app_theme.dart';

class HomeworkScreen extends StatefulWidget {
  final String grade;
  final String stream;
  const HomeworkScreen({super.key, required this.grade, required this.stream});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  List<Homework> _assignments = [];
  bool _isLoading = true;
  String? _error;
  final String _roleId = 'parent';

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await SupabaseService.instance.getHomeworkByClass(widget.grade, widget.stream);
      if (mounted) {
        setState(() {
          _assignments = list.map((m) => Homework.fromMap(m)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load Homework Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "NODE DISCONNECTED. SWIPE TO SYNC.";
        });
      }
    }
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
        title: const Text('HOMEWORK FEED', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 4, color: Colors.white)
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
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -30, top: -10,
                child: Icon(Icons.auto_stories_rounded, size: 160, color: Colors.white.withValues(alpha: 0.12)),
              ),
            ],
          ),
        ),
      ),
      body: NeuralBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Column(
            children: [
              SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
              if (_error != null) _buildErrorBanner(_error!),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: roleColor, strokeWidth: 3))
                    : RefreshIndicator(
                        onRefresh: _loadHomework,
                        color: roleColor,
                        child: _assignments.isEmpty
                            ? _buildEmptyState(dt)
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                itemCount: _assignments.length,
                                itemBuilder: (context, index) {
                                  final h = _assignments[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 18),
                                    child: LiquidGlassCard(
                                      accentColor: KagemaColors.secretaryViolet,
                                      borderRadius: 30,
                                      padding: EdgeInsets.zero,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                        child: ExpansionTile(
                                          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          iconColor: KagemaColors.secretaryViolet,
                                          collapsedIconColor: dt.iconInactive,
                                          leading: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: dt.roleSoftBg(KagemaColors.secretaryViolet), 
                                              shape: BoxShape.circle,
                                              border: Border.all(color: KagemaColors.secretaryViolet.withValues(alpha: 0.2))
                                            ),
                                            child: const Icon(Icons.auto_awesome_rounded, color: KagemaColors.secretaryViolet, size: 24),
                                          ),
                                          title: Text(h.title.toUpperCase(), 
                                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: dt.textPrimary)
                                          ),
                                          subtitle: Text('${h.subject.toUpperCase()} â€¢ DUE: ${h.dueDate}', 
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: KagemaColors.secretaryViolet.withValues(alpha: 0.7), letterSpacing: 1)
                                          ),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Divider(color: dt.divider),
                                                  const SizedBox(height: 20),
                                                  Row(
                                                    children: [
                                                      Container(width: 4, height: 12, decoration: BoxDecoration(color: KagemaColors.secretaryViolet, borderRadius: BorderRadius.circular(2))),
                                                      const SizedBox(width: 8),
                                                      Text('MISSION OBJECTIVES:', 
                                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(h.description, 
                                                    style: TextStyle(height: 1.8, fontSize: 15, fontWeight: FontWeight.w500, color: dt.textSecondary)
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: dt.roleSoftBg(KagemaColors.teacherGreen), 
                                                          borderRadius: BorderRadius.circular(10),
                                                          border: Border.all(color: KagemaColors.teacherGreen.withValues(alpha: 0.2))
                                                        ),
                                                        child: const Text('STATUS: ACTIVE', 
                                                          style: TextStyle(fontSize: 9, color: KagemaColors.teacherGreen, fontWeight: FontWeight.w900, letterSpacing: 1)
                                                        ),
                                                      ),
                                                      Text('POSTED: ${h.postedDate}', 
                                                        style: TextStyle(fontSize: 9, color: dt.textMuted, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: KagemaColors.parentRed.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: KagemaColors.parentRed.withValues(alpha: 0.1))
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: KagemaColors.parentRed, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(color: KagemaColors.parentRed, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 24),
          Text('MISSION ACCOMPLISHED', 
            style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 3, fontSize: 12)
          ),
          const SizedBox(height: 8),
          Text('NO PENDING HOMEWORK TASKS', 
            style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 1)
          ),
        ],
      ),
    );
  }
}
