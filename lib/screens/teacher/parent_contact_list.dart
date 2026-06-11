import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Contacts: ${widget.grade}'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(child: Text('No contacts found in cloud.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey.withOpacity(0.1),
                          child: Text(s.name[0], style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Guardian: ${s.parentName}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () => _makeCall(s.parentPhone),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
