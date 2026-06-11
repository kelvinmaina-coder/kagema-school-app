import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/school_models.dart';
import '../../app_theme.dart';

class HomeworkScreen extends StatefulWidget {
  final String grade;
  final String stream;
  const HomeworkScreen({super.key, required this.grade, required this.stream});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  List<Homework> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    setState(() => _isLoading = true);
    try {
      final list = await SupabaseService.instance.getHomeworkByClass(widget.grade, widget.stream);
      if (mounted) {
        setState(() {
          _assignments = list.map((m) => Homework.fromMap(m)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load Homework Error: $e");
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
        title: const Text('Homework Assignments', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.purple.shade800, Colors.purple.shade400]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _assignments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _assignments.length,
                      itemBuilder: (context, index) {
                        final h = _assignments[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.assignment_rounded, color: Colors.purple, size: 20),
                            ),
                            title: Text(h.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${h.subject} • Due: ${h.dueDate}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('TEACHER INSTRUCTIONS:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                                    const SizedBox(height: 8),
                                    Text(h.description, style: const TextStyle(height: 1.5, fontSize: 13)),
                                    const Divider(height: 32),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Posted: ${h.postedDate}', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        const Text('PENDING SYNC', style: TextStyle(fontSize: 8, color: Colors.orange, fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
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
          Icon(Icons.assignment_turned_in_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('All assignments completed!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
