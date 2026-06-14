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
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.red.shade900, Colors.red.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.gavel_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
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
                    final isPositive = item['category'] == 'Positive';
                    final color = isPositive ? Colors.green : Colors.red;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: gemini?.buildGlowContainer(
                        borderRadius: 28, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: Icon(isPositive ? Icons.auto_awesome_rounded : Icons.warning_rounded, color: color),
                          title: Text(item['title'] ?? 'Incident', style: const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Text(item['date'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_rounded, size: 80, color: Colors.green.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('CONDUCT MATRIX CLEAR', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
          const Text('No recent incidents logged.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
