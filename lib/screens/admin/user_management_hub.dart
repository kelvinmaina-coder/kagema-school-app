import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../common/student_management_screen.dart';
import '../secretary/student_registration.dart';
import 'staff_registration_screen.dart';
import 'parent_registration_screen.dart';
import 'hr_management_screen.dart';
import '../common/parent_directory_screen.dart';

class UserManagementHub extends StatefulWidget {
  const UserManagementHub({super.key});

  @override
  State<UserManagementHub> createState() => _UserManagementHubState();
}

class _UserManagementHubState extends State<UserManagementHub> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('School Registry', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5, color: Colors.white)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, Colors.indigo.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [
              BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.people_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'STUDENTS', icon: Icon(Icons.school_rounded, size: 20)),
            Tab(text: 'STAFF', icon: Icon(Icons.badge_rounded, size: 20)),
            Tab(text: 'PARENTS', icon: Icon(Icons.family_restroom_rounded, size: 20)),
          ],
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildManagementTab(
              context, gemini,
              'Student Records',
              'Enroll new students and manage academic profiles',
              Icons.person_add_alt_1_rounded,
              Colors.blue,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen())),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentManagementScreen(role: 'Admin'))),
            ),
            _buildManagementTab(
              context, gemini,
              'Staff Directory',
              'Register Teachers, Accountants, and Support Staff',
              Icons.group_add_rounded,
              Colors.teal,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffRegistrationScreen())),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRManagementScreen())),
            ),
            _buildManagementTab(
              context, gemini,
              'Parent Directory',
              'Register guardians and link them to their children',
              Icons.person_add_rounded,
              Colors.orange,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentRegistrationScreen())),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentDirectoryScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementTab(
    BuildContext context,
    GeminiThemeExtension? gemini,
    String title,
    String subtitle,
    IconData actionIcon,
    Color color,
    VoidCallback onAdd,
    VoidCallback onView,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 200, 24, 40),
      children: [
        _buildActionCard(
          context, gemini,
          'Register New Entry',
          subtitle,
          actionIcon,
          color,
          onAdd,
        ),
        const SizedBox(height: 24),
        _buildActionCard(
          context, gemini,
          'Manage Existing Records',
          'Search, edit, and update information easily',
          Icons.manage_accounts_rounded,
          Colors.blueGrey,
          onView,
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'REGISTRY OVERVIEW',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2),
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickStat(context, 'Verified profiles', '98%', Colors.green),
        _buildQuickStat(context, 'Sync status', 'Connected', Colors.blue),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, 
    GeminiThemeExtension? gemini,
    String title, 
    String sub, 
    IconData icon, 
    Color color, 
    VoidCallback onTap
  ) {
    final theme = Theme.of(context);
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(sub, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.4, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 24, color: theme.dividerColor),
          ],
        ),
      ),
    );

    return gemini?.buildGlowContainer(
      borderRadius: 30,
      borderThickness: 1.5,
      backgroundColor: theme.cardColor.withOpacity(0.85),
      padding: EdgeInsets.zero,
      child: content,
    ) ?? Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: content,
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blueGrey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
