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
      debugPrint("Academic Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Structures'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('STREAMS & GRADES', _classes, Icons.class_rounded, Colors.blue),
                  const SizedBox(height: 30),
                  _buildSection('SUBJECT DIRECTORY', _subjects, Icons.menu_book_rounded, Colors.orange),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) => Chip(
            label: Text(item, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            backgroundColor: color.withOpacity(0.1),
            side: BorderSide(color: color.withOpacity(0.2)),
          )).toList(),
        ),
      ],
    );
  }
}
