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
  final String _roleId = 'teacher';

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

  void _showUploadDialog(DT dt, GeminiThemeExtension? theme, Color roleColor, {Map<String, dynamic>? resourceToEdit}) {
    final isEditing = resourceToEdit != null;
    final titleController = TextEditingController(text: resourceToEdit?['title']);
    String selectedSubject = resourceToEdit?['subject'] ?? 'Mathematics';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 35,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(isEditing ? 'EDIT RESOURCE' : 'ADD LEARNING MATERIAL', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(isEditing ? 'Update Material Details' : 'Upload Study Material', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)
                ),
                const SizedBox(height: 32),
                _buildInputField(dt, 'Document Title', Icons.title_rounded, titleController, roleColor),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  dropdownColor: dt.cardBg,
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  items: ['Mathematics', 'English', 'Science', 'Social Studies', 'CRE'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => selectedSubject = v!,
                  decoration: InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.subject_rounded, color: roleColor)),
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
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildInputField(DT dt, String label, IconData icon, TextEditingController ctrl, Color color) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Future<void> _deleteResource(DT dt, Map<String, dynamic> r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Delete Material?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Text('Are you sure you want to remove "${r['title']}" from the resources list?', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: TextStyle(color: dt.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: KagemaColors.parentRed, fontWeight: FontWeight.bold))),
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
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('RESOURCES', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.auto_stories_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : _resources.isEmpty 
                  ? _buildEmptyState(dt)
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
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
                        return theme.buildGlowContainer(
                          accentColor: KagemaColors.accountantAmber,
                          borderRadius: 28,
                          padding: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () async {
                              final url = Uri.parse(r['file_path'] ?? '');
                              if (await canLaunchUrl(url)) await launchUrl(url);
                            },
                            onLongPress: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) => theme.buildGlowContainer(
                                  accentColor: roleColor,
                                  borderRadius: 35,
                                  child: SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 20),
                                        ListTile(
                                          leading: const Icon(Icons.edit_note_rounded, color: KagemaColors.staffSky),
                                          title: Text('Edit Details', style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary)),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _showUploadDialog(dt, theme, roleColor, resourceToEdit: r);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.delete_forever_rounded, color: KagemaColors.parentRed),
                                          title: const Text('Remove Permanently', style: TextStyle(fontWeight: FontWeight.bold, color: KagemaColors.parentRed)),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _deleteResource(dt, r);
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
                                    decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.parentRed), shape: BoxShape.circle),
                                    child: const Icon(Icons.picture_as_pdf_rounded, size: 36, color: KagemaColors.parentRed),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    r['title']?.toString().toUpperCase() ?? 'DOCUMENT', 
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: dt.textPrimary), 
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: dt.roleSoftBg(KagemaColors.accountantAmber), 
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: KagemaColors.accountantAmber.withValues(alpha: 0.2)),
                                    ),
                                    child: Text(r['subject'] ?? 'General', 
                                      style: const TextStyle(fontSize: 9, color: KagemaColors.accountantAmber, fontWeight: FontWeight.w900, letterSpacing: 1)
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ) ?? const SizedBox.shrink();
                      },
                    ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showUploadDialog(dt, theme, roleColor),
          icon: const Icon(Icons.cloud_upload_rounded),
          label: const Text('ADD NEW MATERIAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO RESOURCES FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
