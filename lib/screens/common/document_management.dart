import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DocumentManagementScreen extends StatefulWidget {
  final String role;
  const DocumentManagementScreen({super.key, required this.role});

  @override
  State<DocumentManagementScreen> createState() => _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  final List<Map<String, dynamic>> _documents = [
    {'title': 'Admission Form Template', 'type': 'PDF', 'size': '1.2 MB', 'date': '2024-01-15', 'category': 'Forms'},
    {'title': 'Transfer Letter Header', 'type': 'DOCX', 'size': '500 KB', 'date': '2024-01-10', 'category': 'Letters'},
    {'title': 'School Leaving Certificate', 'type': 'PDF', 'size': '800 KB', 'date': '2024-02-05', 'category': 'Certificates'},
    {'title': 'Annual School Calendar', 'type': 'PDF', 'size': '2.1 MB', 'date': '2024-01-01', 'category': 'Archive'},
  ];

  void _showUploadSheet() {
    final titleController = TextEditingController();
    String category = 'Forms';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload New Document', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Document Title')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              items: ['Forms', 'Letters', 'Certificates', 'Archive'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => category = v!,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    _documents.insert(0, {
                      'title': titleController.text,
                      'type': 'PDF',
                      'size': '0 KB',
                      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      'category': category,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.cloud_upload),
              label: const Text('SELECT & UPLOAD'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Document Management'),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final doc = _documents[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _getCatColor(doc['category']).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.description, color: _getCatColor(doc['category'])),
              ),
              title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${doc['category']} • ${doc['date']} • ${doc['size']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.print, size: 20), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.download_rounded, color: Colors.blue), onPressed: () {}),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: (widget.role == 'Admin' || widget.role == 'Secretary')
          ? FloatingActionButton.extended(
              onPressed: _showUploadSheet,
              backgroundColor: Colors.blueGrey.shade800,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Upload Document', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Color _getCatColor(String cat) {
    switch (cat) {
      case 'Forms': return Colors.blue;
      case 'Letters': return Colors.orange;
      case 'Certificates': return Colors.purple;
      default: return Colors.blueGrey;
    }
  }
}
