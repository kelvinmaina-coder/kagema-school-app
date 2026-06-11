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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Academic Structures', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo.shade800, Colors.indigo.shade400]),
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
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: color.withOpacity(0.8))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((item) => Chip(
              label: Text(item, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              backgroundColor: color.withOpacity(0.1),
              side: BorderSide(color: color.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
