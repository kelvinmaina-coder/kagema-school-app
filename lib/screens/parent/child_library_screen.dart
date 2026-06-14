import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ChildLibraryScreen extends StatefulWidget {
  final Student student;
  const ChildLibraryScreen({super.key, required this.student});

  @override
  State<ChildLibraryScreen> createState() => _ChildLibraryScreenState();
}

class _ChildLibraryScreenState extends State<ChildLibraryScreen> {
  List<Map<String, dynamic>> _borrowedBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLibraryData();
  }

  Future<void> _loadLibraryData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getStudentBorrowedBooks(widget.student.studentId);
      if (mounted) {
        setState(() {
          _borrowedBooks = data;
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
        title: Text('${widget.student.name}\'s Library', 
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
              colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade500],
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
                child: Icon(Icons.local_library_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
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
            ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
            : _borrowedBooks.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: _borrowedBooks.length,
                  itemBuilder: (context, index) {
                    final record = _borrowedBooks[index];
                    final book = record['library_books'];
                    final content = ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.book_rounded, color: Colors.blueGrey, size: 24),
                      ),
                      title: Text(book?['title'] ?? 'Neural Volume', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Return Threshold: ${record['due_date'] ?? "N/A"}', 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
                        ),
                      ),
                      trailing: _statusChip(record['status'] ?? 'Borrowed'),
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

  Widget _statusChip(String status) {
    bool isOverdue = status.toLowerCase() == 'overdue';
    Color color = isOverdue ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('NO ACTIVE LOANS IN MATRIX', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
