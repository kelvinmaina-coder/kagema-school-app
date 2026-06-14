import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ChildListScreen extends StatefulWidget {
  final String parentPhone;
  const ChildListScreen({super.key, required this.parentPhone});

  @override
  State<ChildListScreen> createState() => _ChildListScreenState();
}

class _ChildListScreenState extends State<ChildListScreen> {
  List<Student> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final list = await SupabaseService.instance.getStudentsByParentPhone(widget.parentPhone);
      if (mounted) {
        setState(() {
          _children = list.map((json) => Student.fromMap(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading children: $e");
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
        title: const Text('Family Matrix', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.indigo.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.people_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
              : _children.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _children.length,
                      itemBuilder: (context, index) {
                        final s = _children[index];
                        final content = Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              CircleAvatar(radius: 40, backgroundColor: Colors.indigo.withOpacity(0.1), child: Text(s.name[0], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.indigo))),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(s.name.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                  const SizedBox(height: 6),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), child: Text('ADM: ${s.admissionNumber}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 1))),
                                  const SizedBox(height: 8),
                                  Text('${s.grade} • ${s.stream}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.blueGrey)),
                                  const SizedBox(height: 12),
                                  _infoRow(Icons.cake_outlined, s.dateOfBirth),
                                  _infoRow(Icons.wc_rounded, s.gender),
                                ]),
                              ),
                            ],
                          ),
                        );
                        return Padding(padding: const EdgeInsets.only(bottom: 20), child: gemini?.buildGlowContainer(borderRadius: 30, borderThickness: 1.5, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, useAIBorder: true, child: content) ?? Card(child: content));
                      },
                    ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [Icon(icon, size: 14, color: Colors.grey.shade500), const SizedBox(width: 8), Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600))]));

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('NO NEURAL NODES LINKED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
          const Text('Please visit the school registry to link your child.', style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
