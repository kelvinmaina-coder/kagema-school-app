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
        title: const Text('Library Activity', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade400]),
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
            : _borrowedBooks.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _borrowedBooks.length,
                  itemBuilder: (context, index) {
                    final record = _borrowedBooks[index];
                    final book = record['library_books'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey.withOpacity(0.1),
                          child: const Icon(Icons.book_rounded, color: Colors.blueGrey),
                        ),
                        title: Text(book?['title'] ?? 'Borrowed Book', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Due: ${record['due_date'] ?? "N/A"}'),
                        trailing: _statusChip(record['status'] ?? 'Borrowed'),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    bool isOverdue = status.toLowerCase() == 'overdue';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isOverdue ? Colors.red : Colors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: isOverdue ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_library_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No books currently borrowed.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
