import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class AcademicManagementScreen extends StatefulWidget {
  const AcademicManagementScreen({super.key});

  @override
  State<AcademicManagementScreen> createState() => _AcademicManagementScreenState();
}

class _AcademicManagementScreenState extends State<AcademicManagementScreen> {
  List<String> _classes = [];
  List<String> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAcademicData();
  }

  Future<void> _loadAcademicData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final classes = await SupabaseService.instance.getClasses();
      final subjects = await SupabaseService.instance.getSubjects();
      if (mounted) {
        setState(() {
          _classes = classes;
          _subjects = subjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDialog(String type) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
        child: gemini?.buildCreativeBackground(
          isDark: theme.brightness == Brightness.dark,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ADD NEW ${type.toUpperCase()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
                const SizedBox(height: 24),
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(labelText: 'Name', prefixIcon: Icon(type == 'Class' ? Icons.school : Icons.book, color: theme.primaryColor), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        setState(() { if (type == 'Class') _classes.add(ctrl.text.trim()); else _subjects.add(ctrl.text.trim()); });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('SAVE TO RECORDS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Academic Management', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.primaryColor, Colors.indigo.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)))),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : SingleChildScrollView(
              padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, left: 20, right: 20),
              child: Column(
                children: [
                  _buildSection('STREAMS & GRADES', _classes, Icons.class_rounded, Colors.blue, gemini, () => _showAddDialog('Class')),
                  const SizedBox(height: 32),
                  _buildSection('SUBJECT DIRECTORY', _subjects, Icons.menu_book_rounded, Colors.orange, gemini, () => _showAddDialog('Subject')),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon, Color color, GeminiThemeExtension? gemini, VoidCallback onAdd) {
    final theme = Theme.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 10), Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 1.5))]),
          IconButton(icon: Icon(Icons.add_circle_outline_rounded, color: color, size: 20), onPressed: onAdd),
        ]),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: items.map((i) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.1))), child: Text(i, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)))).toList()),
      ],
    );
    return gemini?.buildGlowContainer(borderRadius: 28, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: const EdgeInsets.all(24), child: content) ?? Card(child: content);
  }
}
