import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ChildDisciplineScreen extends StatefulWidget {
  final Student student;
  const ChildDisciplineScreen({super.key, required this.student});

  @override
  State<ChildDisciplineScreen> createState() => _ChildDisciplineScreenState();
}

class _ChildDisciplineScreenState extends State<ChildDisciplineScreen> {
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiscipline();
  }

  Future<void> _loadDiscipline() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getStudentDiscipline(widget.student.studentId);
      if (mounted) {
        setState(() {
          _incidents = data;
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
        title: Text('${widget.student.name}\'s Conduct', 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)
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
              colors: [Colors.red.shade900, Colors.red.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.gavel_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
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
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : _incidents.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: _incidents.length,
                  itemBuilder: (context, index) {
                    final item = _incidents[index];
                    final content = ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                      ),
                      title: Text(item['title'] ?? 'Incident Entry', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(item['description'] ?? 'No details provided.', 
                          style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500)
                        ),
                      ),
                      trailing: Text(item['date'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_rounded, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          const Text('DISCIPLINE RECORD CLEAR', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
