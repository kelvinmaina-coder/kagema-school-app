import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';

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

  void _showUploadSheet(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    final titleController = TextEditingController();
    String category = 'Forms';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 35,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('SYSTEM REPOSITORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('Upload New Document', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)),
                const SizedBox(height: 32),
                _buildInputField(dt, 'Document Name', Icons.title_rounded, titleController, roleColor),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: dt.cardBg,
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  decoration: InputDecoration(labelText: 'Document Category', prefixIcon: Icon(Icons.category_rounded, color: roleColor)),
                  items: ['Forms', 'Letters', 'Certificates', 'Archive'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => category = v!,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: roleColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text('AUTHORIZE UPLOAD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(widget.role);
    final compColor = RoleColors.complement(widget.role);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('SCHOOL VAULT', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
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
            gradient: RoleColors.gradient(widget.role, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.inventory_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, 20, 100),
            itemCount: _documents.length,
            itemBuilder: (context, index) {
              final doc = _documents[index];
              final color = _getCatColor(doc['category'], dt);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: theme.buildGlowContainer(
                  accentColor: color,
                  borderRadius: 28,
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
                      child: Icon(Icons.description_rounded, color: color, size: 24),
                    ),
                    title: Text(doc['title']?.toString().toUpperCase() ?? 'DOCUMENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${doc['category']} • ${doc['date']} • ${doc['size']}', 
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dt.textSecondary)
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.print_rounded, size: 20, color: dt.iconInactive), onPressed: () {}),
                        IconButton(icon: Icon(Icons.cloud_download_rounded, color: dt.info, size: 20), onPressed: () {}),
                      ],
                    ),
                  ),
                ) ?? const SizedBox.shrink(),
              );
            },
          ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: (widget.role.toLowerCase() == 'admin' || widget.role.toLowerCase() == 'secretary')
          ? RolePlasma(
              color: roleColor,
              child: FloatingActionButton.extended(
                onPressed: () => _showUploadSheet(dt, theme, roleColor),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('SYNC NEW DOCUMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
              ),
            )
          : null,
    );
  }

  Color _getCatColor(String cat, DT dt) {
    switch (cat) {
      case 'Forms': return dt.info;
      case 'Letters': return KagemaColors.accountantAmber;
      case 'Certificates': return KagemaColors.secretaryViolet;
      default: return KagemaColors.teacherGreen;
    }
  }
}
