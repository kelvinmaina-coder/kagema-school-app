import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  List<Map<String, dynamic>> _resources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchResources();
  }

  Future<void> _fetchResources() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getResources();
      if (mounted) {
        setState(() {
          _resources = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUploadDialog() {
    final titleController = TextEditingController();
    String selectedSubject = 'Mathematics';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload Learning Material', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Document Title', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedSubject,
              items: ['Mathematics', 'English', 'Science'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => selectedSubject = v!,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    await SupabaseService.instance.client.from('resources').insert({
                      'title': titleController.text.trim(),
                      'subject': selectedSubject,
                      'grade': 'Grade 1',
                      'file_path': 'https://placeholder.com/sample.pdf', // In production, use Supabase Storage
                    });
                    Navigator.pop(context);
                    _fetchResources();
                  }
                },
                icon: const Icon(Icons.cloud_upload),
                label: const Text('SYNC TO CLOUD'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Library'), backgroundColor: Colors.brown, foregroundColor: Colors.white),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12),
            itemCount: _resources.length,
            itemBuilder: (context, index) {
              final r = _resources[index];
              return Card(
                child: InkWell(
                  onTap: () async {
                    final url = Uri.parse(r['file_path'] ?? '');
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(r['title'] ?? 'Document', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      Text(r['subject'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog, 
        label: const Text('New Resource'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.brown,
      ),
    );
  }
}
