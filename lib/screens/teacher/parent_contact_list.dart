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
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Neural Contact Matrix', 
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
              colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.contact_phone_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
              : students.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        final content = ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blueGrey.withOpacity(0.1),
                            child: Text(s.name[0], 
                              style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w900, fontSize: 18)
                            ),
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          subtitle: Text('Guardian: ${s.parentName}', 
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.green.withOpacity(0.2)),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.phone_enabled_rounded, color: Colors.green, size: 20),
                              onPressed: () => _makeCall(s.parentPhone),
                            ),
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
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contact_emergency_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('NO NEURAL CONTACTS DETECTED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
