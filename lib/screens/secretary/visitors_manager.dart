import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class VisitorsManagerScreen extends StatefulWidget {
  const VisitorsManagerScreen({super.key});

  @override
  State<VisitorsManagerScreen> createState() => _VisitorsManagerScreenState();
}

class _VisitorsManagerScreenState extends State<VisitorsManagerScreen> {
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getVisitors();
      if (mounted) {
        setState(() {
          _visitors = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Visitor Log Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLogVisitorDialog({Map<String, dynamic>? visitorToEdit}) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isEditing = visitorToEdit != null;
    final nameController = TextEditingController(text: visitorToEdit?['name']);
    final phoneController = TextEditingController(text: visitorToEdit?['phone']);
    final purposeController = TextEditingController(text: visitorToEdit?['purpose']);

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text(isEditing ? 'MODIFY LOG' : 'VISITOR ENTRY', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                  ),
                  const SizedBox(height: 8),
                  Text(isEditing ? 'Change Profile' : 'Identity Verification', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                  const SizedBox(height: 32),
                  _buildFormField('Legal Full Name', Icons.person_outline_rounded, nameController, theme),
                  const SizedBox(height: 16),
                  _buildFormField('Contact Number', Icons.phone_android_rounded, phoneController, theme, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildFormField('Visit Purpose', Icons.info_outline_rounded, purposeController, theme),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isNotEmpty) {
                          final data = {
                            'visitor_id': visitorToEdit?['visitor_id'],
                            'name': nameController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'purpose': purposeController.text.trim(),
                            'date': visitorToEdit?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                            'time_in': visitorToEdit?['time_in'] ?? DateTime.now().toIso8601String(),
                          };
                          
                          try {
                            await SupabaseService.instance.insertVisitor(data);
                            if (mounted) {
                              Navigator.pop(context);
                              _loadVisitors();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('System Synced: Visitor Logged', style: TextStyle(fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.teal.shade800,
                                  behavior: SnackBarBehavior.floating,
                                )
                              );
                            }
                          } catch (e) {
                            if (mounted) _loadVisitors();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700, 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: Text(isEditing ? 'COMMIT SYNC' : 'AUTHORIZE ENTRY', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ) ?? const SizedBox(),
      ),
    );
  }

  Widget _buildFormField(String label, IconData icon, TextEditingController ctrl, ThemeData theme, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.teal, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _deleteVisitor(Map<String, dynamic> v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Log?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to erase the log for "${v['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ABORT')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.client.from('visitors').delete().eq('visitor_id', v['visitor_id']);
      _loadVisitors();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Visitor Logs', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
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
              colors: [Colors.teal.shade900, Colors.teal.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.shield_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
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
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : _visitors.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: _visitors.length,
                    itemBuilder: (context, index) {
                      final v = _visitors[index];
                      final content = ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.badge_rounded, color: Colors.teal, size: 24),
                        ),
                        title: Text(v['name'] ?? 'Visitor', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${v['purpose']} \nTimestamp: ${v['date']}', 
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Text('VERIFIED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onSelected: (val) {
                                if (val == 'edit') _showLogVisitorDialog(visitorToEdit: v);
                                if (val == 'delete') _deleteVisitor(v);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note_rounded, size: 20), title: Text('Edit Info', style: TextStyle(fontWeight: FontWeight.bold)), dense: true)),
                                const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20), title: Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), dense: true)),
                              ],
                            ),
                          ],
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: gemini?.buildGlowContainer(
                          borderRadius: 28,
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
        backgroundColor: Colors.teal.shade700,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showLogVisitorDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Log New Visitor', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('VISITOR LOGS EMPTY', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
