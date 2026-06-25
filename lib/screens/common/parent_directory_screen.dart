import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import '../admin/parent_registration_screen.dart';

class ParentDirectoryScreen extends StatefulWidget {
  const ParentDirectoryScreen({super.key});

  @override
  State<ParentDirectoryScreen> createState() => _ParentDirectoryScreenState();
}

class _ParentDirectoryScreenState extends State<ParentDirectoryScreen> {
  List<Map<String, dynamic>> _parents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParents();
  }

  Future<void> _loadParents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await SupabaseService.instance.getParents();
      if (mounted) {
        setState(() {
          _parents = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading parents: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Parent directory sync failed. Please check your connection.";
        });
      }
    }
  }

  void _showParentForm({Map<String, dynamic>? parent}) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final nameCtrl = TextEditingController(text: parent?['name']);
    final phoneCtrl = TextEditingController(text: parent?['phone']);
    final emailCtrl = TextEditingController(text: parent?['email']);

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
                Text(parent == null ? 'NEW PARENT REGISTRATION' : 'EDIT PARENT DATA', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(parent == null ? 'Parent Onboarding' : 'Update Profile', 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                ),
                const SizedBox(height: 32),
                _buildInputField('Full Name', Icons.person_outline_rounded, nameCtrl, theme),
                const SizedBox(height: 16),
                _buildInputField('Phone Number', Icons.phone_android_rounded, phoneCtrl, theme, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildInputField('Email Address (Optional)', Icons.alternate_email_rounded, emailCtrl, theme, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Required: Name & Phone Number'), backgroundColor: Colors.orange.shade800)
                        );
                        return;
                      }
                      
                      final data = {
                        'parentId': parent?['parentId'] ?? parent?['parent_id'] ?? 'PAR-${DateTime.now().millisecondsSinceEpoch}',
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                      };

                      try {
                        await SupabaseService.instance.insertParent(data);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadParents();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Parent ${parent == null ? 'Registered' : 'Updated'} Successfully'), 
                              backgroundColor: Colors.green.shade800,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (e == "OFFLINE_QUEUED") {
                           Navigator.pop(context);
                           _loadParents();
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: theme.primaryColor.withOpacity(0.4),
                    ),
                    child: Text(parent == null ? 'REGISTER & SAVE' : 'UPDATE RECORDS', 
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)
                    ),
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

  Widget _buildInputField(String label, IconData icon, TextEditingController ctrl, ThemeData theme, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: theme.primaryColor, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
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
        title: const Text('Parent Directory', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)
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
              colors: [theme.primaryColor, Colors.indigo.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.family_restroom_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
            : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sync_problem_rounded, color: Colors.red.withOpacity(0.5), size: 60),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: _loadParents, child: const Text('RE-SYNC DIRECTORY'))
                    ],
                  ),
                )
              : _parents.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _parents.length,
                      itemBuilder: (context, index) {
                        final p = _parents[index];
                        final content = ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: theme.primaryColor.withOpacity(0.1),
                            child: Icon(Icons.family_restroom_rounded, color: theme.primaryColor, size: 24),
                          ),
                          title: Text(p['name'] ?? 'Parent Name', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          subtitle: Text(p['phone'] ?? 'No Phone Number', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                                onPressed: () => _showParentForm(parent: p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                onPressed: () => _confirmDelete(p['parentId'] ?? p['parent_id']),
                              ),
                            ],
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: gemini?.buildGlowContainer(
                            borderRadius: 24,
                            borderThickness: 1,
                            backgroundColor: theme.cardColor.withOpacity(0.85),
                            padding: EdgeInsets.zero,
                            child: content,
                          ) ?? Card(child: content),
                        );
                      },
                    ),
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: theme.primaryColor,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showParentForm(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add New Parent', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String? id) async {
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Parent?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('This will remove the parent record and unlink their children.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteParent(id);
        _loadParents();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted successfully.')));
      } catch (e) {
        if (e == "OFFLINE_QUEUED") {
          _loadParents();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('PARENT DIRECTORY EMPTY', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
