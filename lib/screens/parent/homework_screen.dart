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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Intelligence Link Interrupted. Swipe down to re-sync.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Neural Task Feed', 
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
              colors: [Colors.purple.shade900, Colors.purple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.assignment_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: Column(
            children: [
              if (_error != null) _buildErrorBanner(_error!),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                    : RefreshIndicator(
                        onRefresh: _loadHomework,
                        color: Colors.purple,
                        child: _assignments.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                itemCount: _assignments.length,
                                itemBuilder: (context, index) {
                                  final h = _assignments[index];
                                  final content = ExpansionTile(
                                    shape: const Border(),
                                    iconColor: Colors.purple,
                                    collapsedIconColor: Colors.grey,
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                                      child: const Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.purple, size: 22),
                                    ),
                                    title: Text(h.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
                                    subtitle: Text('${h.subject} • Due: ${h.dueDate}', 
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Divider(color: Colors.white10, height: 1),
                                            const SizedBox(height: 16),
                                            Text('INTELLIGENCE PARAMETERS:', 
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 1.5)
                                            ),
                                            const SizedBox(height: 12),
                                            Text(h.description, style: const TextStyle(height: 1.6, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blueGrey)),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                                  child: Text('POSTED: ${h.postedDate}', 
                                                    style: TextStyle(fontSize: 9, color: theme.primaryColor, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                                                  ),
                                                ),
                                                const Text('NEURAL SYNCED', 
                                                  style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 1)
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red.withOpacity(0.1))),
      child: Row(
        children: [
          const Icon(Icons.sync_problem_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
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
          Text('QUANTUM TASKS COMPLETE', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
