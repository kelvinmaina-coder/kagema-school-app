import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ParentContactList extends StatefulWidget {
  final String grade;
  final String stream;

  const ParentContactList({super.key, required this.grade, required this.stream});

  @override
  State<ParentContactList> createState() => _ParentContactListState();
}

class _ParentContactListState extends State<ParentContactList> {
  List<Student> students = [];
  bool isLoading = true;
  final String _roleId = 'teacher';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;
    try {
      final list = await SupabaseService.instance.getStudentsByClass(widget.grade, widget.stream);
      if (mounted) {
        setState(() {
          students = list.map((m) => Student.fromMap(m)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _makeCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('PARENT DIRECTORY', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
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
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.contact_phone_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: roleColor))
                : students.isEmpty
                    ? _buildEmptyState(dt)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final s = students[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: theme.buildGlowContainer(
                              accentColor: KagemaColors.staffSky,
                              borderRadius: 24,
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: dt.roleSoftBg(KagemaColors.staffSky),
                                  child: Text(s.name[0].toUpperCase(), 
                                    style: const TextStyle(color: KagemaColors.staffSky, fontWeight: FontWeight.w900, fontSize: 18)
                                  ),
                                ),
                                title: Text(s.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)),
                                subtitle: Text('Guardian: ${s.parentName}', 
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dt.textSecondary)
                                ),
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    color: dt.roleSoftBg(KagemaColors.teacherGreen),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: KagemaColors.teacherGreen.withValues(alpha: 0.2)),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.phone_enabled_rounded, color: KagemaColors.teacherGreen, size: 20),
                                    onPressed: () => _makeCall(s.parentPhone),
                                  ),
                                ),
                              ),
                            ),
                          ) ?? const SizedBox.shrink();
                        },
                      ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contact_emergency_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO CONTACTS DETECTED', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
