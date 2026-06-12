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
        title: const Text('Registry & Controls', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.indigo.shade800]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          tabs: const [
            Tab(text: 'STUDENTS', icon: Icon(Icons.school_rounded)),
            Tab(text: 'STAFF', icon: Icon(Icons.badge_rounded)),
            Tab(text: 'PARENTS', icon: Icon(Icons.family_restroom_rounded)),
          ],
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildManagementTab(
              context,
              'Student Intelligence',
              'Enroll new pupils and manage academic profiles',
              Icons.person_add_alt_1_rounded,
              Colors.blue,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen())),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentManagementScreen(role: 'Admin'))),
            ),
            _buildManagementTab(
              context,
              'Staff Directory',
              'Register Teachers, Accountants, and Support Staff',
              Icons.group_add_rounded,
              Colors.teal,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffRegistrationScreen())),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRManagementScreen())),
            ),
            _buildManagementTab(
              context,
              'Parent Registry',
              'Onboard guardians and link them to their children',
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
    String title,
    String subtitle,
    IconData actionIcon,
    Color color,
    VoidCallback onAdd,
    VoidCallback onView,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 180, 24, 24),
      children: [
        _buildActionCard(
          context,
          'Register New Entry',
          subtitle,
          actionIcon,
          color,
          onAdd,
        ),
        const SizedBox(height: 20),
        _buildActionCard(
          context,
          'Manage Existing Records',
          'Search, edit, and update information in real-time',
          Icons.manage_accounts_rounded,
          Colors.blueGrey,
          onView,
        ),
        const SizedBox(height: 40),
        const Text(
          'REGISTRY OVERVIEW',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        _buildQuickStat('System verified profiles', '98%', Colors.green),
        _buildQuickStat('Pending cloud syncs', '0', Colors.blue),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
