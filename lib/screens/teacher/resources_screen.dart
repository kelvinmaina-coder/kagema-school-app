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
    final gemini = theme.extension<GeminiThemeExtension>();
    final isEditing = resourceToEdit != null;
    final titleController = TextEditingController(text: resourceToEdit?['title']);
    String selectedSubject = resourceToEdit?['subject'] ?? 'Mathematics';

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
                  Text(isEditing ? 'EDIT RESOURCE' : 'ADD LEARNING MATERIAL', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                  ),
                  const SizedBox(height: 8),
                  Text(isEditing ? 'Update Material Details' : 'Upload Study Material', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                  const SizedBox(height: 32),
                  _buildInputField('Document Title', Icons.title_rounded, titleController, theme),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedSubject,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    items: ['Mathematics', 'English', 'Science', 'Social Studies', 'CRE'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => selectedSubject = v!,
                    decoration: _inputDecoration('Subject', Icons.subject_rounded, theme),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
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
                      icon: Icon(isEditing ? Icons.save_rounded : Icons.cloud_upload_rounded),
                      label: Text(isEditing ? 'UPDATE RECORDS' : 'UPLOAD TO SYSTEM', 
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown.shade700, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
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

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.brown, size: 20),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController ctrl, ThemeData theme) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: _inputDecoration(label, icon, theme),
    );
  }

  Future<void> _deleteResource(Map<String, dynamic> r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Material?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to remove "${r['title']}" from the resources list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
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
        title: const Text('Learning Resources', 
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
              colors: [Colors.brown.shade900, Colors.brown.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.auto_stories_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
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
            ? const Center(child: CircularProgressIndicator(color: Colors.brown))
            : _resources.isEmpty 
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      mainAxisSpacing: 16, 
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _resources.length,
                    itemBuilder: (context, index) {
                      final r = _resources[index];
                      final content = InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () async {
                          final url = Uri.parse(r['file_path'] ?? '');
                          if (await canLaunchUrl(url)) await launchUrl(url);
                        },
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                              ),
                              child: SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 20),
                                    ListTile(
                                      leading: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                                      title: const Text('Edit Details', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showUploadDialog(resourceToEdit: r);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                                      title: const Text('Remove Permanently', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _deleteResource(r);
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
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
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.picture_as_pdf_rounded, size: 36, color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                r['title']?.toString().toUpperCase() ?? 'DOCUMENT', 
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5), 
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.brown.withOpacity(0.1), 
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.brown.withOpacity(0.2)),
                                ),
                                child: Text(r['subject'] ?? 'General', 
                                  style: const TextStyle(fontSize: 9, color: Colors.brown, fontWeight: FontWeight.w900, letterSpacing: 1)
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      return gemini?.buildGlowContainer(
                        borderRadius: 28,
                        borderThickness: 1,
                        backgroundColor: theme.cardColor.withOpacity(0.85),
                        padding: EdgeInsets.zero,
                        child: content,
                      ) ?? Card(child: content);
                    },
                  ),
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: Colors.brown,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showUploadDialog(), 
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.cloud_upload_rounded),
          label: const Text('Add New Material', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
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
          Text('NO RESOURCES FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
