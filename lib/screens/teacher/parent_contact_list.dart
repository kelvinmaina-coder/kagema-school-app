import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/school_models.dart';
import '../../services/database_service.dart';
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
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final list = await DatabaseService.instance.getStudentsByClass(widget.grade, widget.stream);
    if (mounted) {
      setState(() {
        students = list;
        isLoading = false;
      });
    }
  }

  void _makeCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not initiate call')));
      }
    }
  }

  void _sendSms(String phone) async {
    final Uri url = Uri.parse('sms:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open SMS')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Contacts: ${widget.grade} ${widget.stream}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : students.isEmpty
                ? const Center(child: Text('No pupils found in this class.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final s = students[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.1),
                            child: Text(s.parentName[0], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(s.parentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Pupil: ${s.name}\nPhone: ${s.parentPhone}'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.phone, color: Colors.green),
                                onPressed: () => _makeCall(s.parentPhone),
                              ),
                              IconButton(
                                icon: const Icon(Icons.message, color: Colors.blue),
                                onPressed: () => _sendSms(s.parentPhone),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
