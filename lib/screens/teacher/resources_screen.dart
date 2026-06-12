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
    if (!mounted) return;
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

  void _showUploadDialog({Map<String, dynamic>? resourceToEdit}) {
    final theme = Theme.of(context);
    final isEditing = resourceToEdit != null;
    final titleController = TextEditingController(text: resourceToEdit?['title']);
    String selectedSubject = resourceToEdit?['subject'] ?? 'Mathematics';

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditing ? 'Update Resource' : 'Upload Learning Material', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.brown)),
              const SizedBox(height: 8),
              Text(isEditing ? 'Modify document details in the cloud repository' : 'Send academic materials to the pupil\'s digital library', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(
                controller: titleController, 
                decoration: InputDecoration(
                  labelText: 'Document Title', 
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedSubject,
                items: ['Mathematics', 'English', 'Science', 'Social Studies', 'CRE'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => selectedSubject = v!,
                decoration: InputDecoration(
                  labelText: 'Subject Category',
                  prefixIcon: const Icon(Icons.subject),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      final data = {
                        'title': titleController.text.trim(),
                        'subject': selectedSubject,
                        'grade': resourceToEdit?['grade'] ?? 'Grade 1',
                        'file_path': resourceToEdit?['file_path'] ?? 'https://placeholder.com/sample.pdf',
                      };
                      
                      if (isEditing) {
                        await SupabaseService.instance.client.from('resources').update(data).eq('resource_id', resourceToEdit['resource_id']);
                      } else {
                        await SupabaseService.instance.client.from('resources').insert(data);
                      }
                      
                      if (mounted) {
                        Navigator.pop(context);
                        _fetchResources();
                      }
                    }
                  },
                  icon: Icon(isEditing ? Icons.save_rounded : Icons.cloud_upload),
                  label: Text(isEditing ? 'UPDATE RESOURCE' : 'SYNC TO CLOUD', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteResource(Map<String, dynamic> r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material?'),
        content: Text('Are you sure you want to remove "${r['title']}"? It will no longer be available to pupils.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.client.from('resources').delete().eq('resource_id', r['resource_id']);
      _fetchResources();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Digital Library', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.brown.shade800, Colors.brown.shade400]),
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
            : _resources.isEmpty 
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      mainAxisSpacing: 16, 
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _resources.length,
                    itemBuilder: (context, index) {
                      final r = _resources[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () async {
                            final url = Uri.parse(r['file_path'] ?? '');
                            if (await canLaunchUrl(url)) await launchUrl(url);
                          },
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                                      title: const Text('Edit Details'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showUploadDialog(resourceToEdit: r);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                                      title: const Text('Delete Permanently'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _deleteResource(r);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                                  child: const Icon(Icons.picture_as_pdf_rounded, size: 32, color: Colors.red),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  r['title'] ?? 'Document', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.brown.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(r['subject'] ?? 'General', style: const TextStyle(fontSize: 9, color: Colors.brown, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(), 
        label: const Text('New Resource', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_to_photos_rounded),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Digital library is empty.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
