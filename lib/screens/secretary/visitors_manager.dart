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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _phoneController = TextEditingController();
  
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
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
      debugPrint("Load Visitors Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logVisitor() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final visitor = {
      'name': _nameController.text.trim(),
      'purpose': _purposeController.text.trim(),
      'phone': _phoneController.text.trim(),
      'timeIn': DateFormat('hh:mm a').format(now),
      'timeOut': '--:--',
      'date': DateFormat('yyyy-MM-dd').format(now),
    };

    try {
      await SupabaseService.instance.insertVisitor(visitor);
      _nameController.clear();
      _purposeController.clear();
      _phoneController.clear();
      
      if (mounted) {
        Navigator.pop(context);
        _loadVisitors();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor logged successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Log Visitor Error: $e");
    }
  }

  Future<void> _signOutVisitor(String id) async {
    try {
      final timeOut = DateFormat('hh:mm a').format(DateTime.now());
      await SupabaseService.instance.client
          .from('visitors')
          .update({'time_out': timeOut})
          .eq('visitor_id', id);
      _loadVisitors();
    } catch (e) {
      debugPrint("Sign Out Visitor Error: $e");
    }
  }

  void _showAddVisitorSheet() {
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Log New Visitor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Security protocol active. Ensure details are accurate.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Visitor Name', prefixIcon: Icon(Icons.person_outline_rounded)),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_android_rounded)),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Enter phone' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(labelText: 'Purpose of Visit', prefixIcon: Icon(Icons.info_outline_rounded)),
                validator: (v) => v!.isEmpty ? 'Enter purpose' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _logVisitor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('CHECK IN VISITOR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
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
        title: const Text('Visitors Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
                  _buildHeader(theme, gemini),
                  Expanded(
                    child: _visitors.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _visitors.length,
                            itemBuilder: (context, index) {
                              final v = _visitors[index];
                              final isSignedOut = v['time_out'] != null && v['time_out'] != '--:--';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: isSignedOut ? Colors.grey.shade100 : theme.primaryColor.withOpacity(0.1),
                                    child: Icon(Icons.person_pin_rounded, color: isSignedOut ? Colors.grey : theme.primaryColor),
                                  ),
                                  title: Text(v['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('Purpose: ${v['purpose'] ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.login_rounded, size: 12, color: Colors.green.shade600),
                                          const SizedBox(width: 4),
                                          Text(v['time_in'] ?? '--:--', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 12),
                                          Icon(Icons.logout_rounded, size: 12, color: isSignedOut ? Colors.red.shade600 : Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(v['time_out'] ?? '--:--', style: TextStyle(fontSize: 11, color: isSignedOut ? Colors.red.shade600 : Colors.grey, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: isSignedOut
                                      ? Icon(Icons.verified_rounded, color: Colors.green.shade400)
                                      : TextButton(
                                          onPressed: () => _signOutVisitor(v['visitor_id']),
                                          style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800, backgroundColor: Colors.orange.shade50),
                                          child: const Text('Sign Out', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVisitorSheet,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Visitor', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    int activeCount = _visitors.where((v) => v['time_out'] == null || v['time_out'] == '--:--').length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE VISITORS', style: TextStyle(color: theme.primaryColor.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Text('$activeCount Guests', style: TextStyle(color: theme.primaryColor, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
            Icon(Icons.security_rounded, size: 40, color: theme.primaryColor.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No visitor activity today', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
