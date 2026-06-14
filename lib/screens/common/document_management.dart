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

  void _showUploadSheet() {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final titleController = TextEditingController();
    String category = 'Forms';

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('NEURAL REPOSITORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('Upload New Volume', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 32),
                _buildNeuralField('Document Designation', Icons.title_rounded, titleController, theme),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  decoration: _neuralInputDecoration('Intelligence Category', Icons.category_rounded, theme),
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
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text('AUTHORIZE UPLOAD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _neuralInputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, color: theme.primaryColor, size: 20),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }

  Widget _buildNeuralField(String label, IconData icon, TextEditingController ctrl, ThemeData theme) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: _neuralInputDecoration(label, icon, theme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Knowledge Vault', 
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
                child: Icon(Icons.inventory_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(20, AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, 20, 100),
          itemCount: _documents.length,
          itemBuilder: (context, index) {
            final doc = _documents[index];
            final color = _getCatColor(doc['category']);
            final content = ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.description_rounded, color: color, size: 24),
              ),
              title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${doc['category']} • ${doc['date']} • ${doc['size']}', 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.print_rounded, size: 20), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.cloud_download_rounded, color: Colors.blue, size: 20), onPressed: () {}),
                ],
              ),
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: gemini?.buildGlowContainer(
                borderRadius: 28,
                borderThickness: 1,
                backgroundColor: theme.cardColor.withOpacity(0.85),
                padding: EdgeInsets.zero,
                child: content,
              ) ?? Card(child: content),
            );
          },
        ),
      ),
      floatingActionButton: (widget.role == 'Admin' || widget.role == 'Secretary')
          ? gemini?.buildGlowContainer(
              borderRadius: 30,
              borderThickness: 2,
              backgroundColor: Colors.blueGrey.shade800,
              padding: EdgeInsets.zero,
              child: FloatingActionButton.extended(
                onPressed: _showUploadSheet,
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('SYNC NEW VOLUME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            )
          : null,
    );
  }

  Color _getCatColor(String cat) {
    switch (cat) {
      case 'Forms': return Colors.blue;
      case 'Letters': return Colors.orange;
      case 'Certificates': return Colors.purple;
      default: return Colors.teal;
    }
  }
}
