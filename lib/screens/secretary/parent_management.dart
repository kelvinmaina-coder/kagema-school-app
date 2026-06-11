import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ParentManagementScreen extends StatefulWidget {
  const ParentManagementScreen({super.key});

  @override
  State<ParentManagementScreen> createState() => _ParentManagementScreenState();
}

class _ParentManagementScreenState extends State<ParentManagementScreen> {
  List<Map<String, dynamic>> _parents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParents();
  }

  Future<void> _loadParents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getParents();
      if (mounted) {
        setState(() {
          _parents = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddParentDialog() {
    final theme = Theme.of(context);
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

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
            Text('Register New Guardian', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.primaryColor)),
            const SizedBox(height: 8),
            const Text('Link a parent/guardian to the school system', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 32),
            _buildDialogField(nameCtrl, 'Guardian Full Name', Icons.person_outline),
            const SizedBox(height: 16),
            _buildDialogField(phoneCtrl, 'Active Phone Number', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildDialogField(emailCtrl, 'Email Address (Optional)', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                    await SupabaseService.instance.insertParent({
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                    });
                    Navigator.pop(context);
                    _loadParents();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                ),
                child: const Text('AUTHORIZE & SYNC', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Guardian Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.indigo]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _parents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _parents.length,
                    itemBuilder: (context, index) {
                      final p = _parents[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: theme.primaryColor.withOpacity(0.1),
                            child: Icon(Icons.family_restroom, color: theme.primaryColor),
                          ),
                          title: Text(p['name'] ?? 'Guardian', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(p['phone'] ?? ''),
                          trailing: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 20),
                        ),
                      );
                    },
                  ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddParentDialog,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Guardian', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No guardian records found.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
