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
          _error = "NODE DISCONNECTED. SWIPE TO SYNC.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('HOMEWORK FEED', 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 16, 
            letterSpacing: 4, 
            color: Colors.white, 
            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)]
          )
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A148C), Color(0xFF7C4DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                right: -30, top: -10,
                child: Icon(Icons.auto_stories_rounded, size: 160, color: Colors.white.withValues(alpha: 0.12)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        child: Column(
          children: [
            SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
            if (_error != null) _buildErrorBanner(_error!),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.primaryColor, strokeWidth: 3))
                  : RefreshIndicator(
                      onRefresh: _loadHomework,
                      color: const Color(0xFF7C4DFF),
                      child: _assignments.isEmpty
                          ? _buildEmptyState(isDark)
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: _assignments.length,
                              itemBuilder: (context, index) {
                                final h = _assignments[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: gemini?.buildGlowContainer(
                                    borderRadius: 30,
                                    borderThickness: 1.2,
                                    backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
                                    padding: EdgeInsets.zero,
                                    child: Theme(
                                      data: theme.copyWith(dividerColor: Colors.transparent),
                                      child: ExpansionTile(
                                        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        iconColor: const Color(0xFF7C4DFF),
                                        collapsedIconColor: isDark ? Colors.white24 : Colors.black12,
                                        leading: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7C4DFF).withValues(alpha: 0.1), 
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.2))
                                          ),
                                          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C4DFF), size: 24),
                                        ),
                                        title: Text(h.title.toUpperCase(), 
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: isDark ? Colors.white : Colors.black87)
                                        ),
                                        subtitle: Text('${h.subject.toUpperCase()} • DUE: ${h.dueDate}', 
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF7C4DFF).withValues(alpha: 0.7), letterSpacing: 1)
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1)),
                                                const SizedBox(height: 20),
                                                Row(
                                                  children: [
                                                    Container(width: 4, height: 12, decoration: BoxDecoration(color: const Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(2))),
                                                    const SizedBox(width: 8),
                                                    const Text('MISSION OBJECTIVES:', 
                                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                Text(h.description, 
                                                  style: TextStyle(height: 1.8, fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)
                                                ),
                                                const SizedBox(height: 24),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF00E676).withValues(alpha: 0.1), 
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.2))
                                                      ),
                                                      child: const Text('STATUS: ACTIVE', 
                                                        style: TextStyle(fontSize: 9, color: Color(0xFF00E676), fontWeight: FontWeight.w900, letterSpacing: 1)
                                                      ),
                                                    ),
                                                    Text('POSTED: ${h.postedDate}', 
                                                      style: TextStyle(fontSize: 9, color: isDark ? Colors.white24 : Colors.black26, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3D00).withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFFF3D00).withValues(alpha: 0.1))
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFFF3D00), size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(color: Color(0xFFFF3D00), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 80, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 24),
          const Text('MISSION ACCOMPLISHED', 
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 3, fontSize: 12)
          ),
          const SizedBox(height: 8),
          Text('NO PENDING HOMEWORK TASKS', 
            style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1), fontSize: 10, letterSpacing: 1)
          ),
        ],
      ),
    );
  }
}
