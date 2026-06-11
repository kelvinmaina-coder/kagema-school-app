import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class LibraryManagementScreen extends StatefulWidget {
  const LibraryManagementScreen({super.key});

  @override
  State<LibraryManagementScreen> createState() => _LibraryManagementScreenState();
}

class _LibraryManagementScreenState extends State<LibraryManagementScreen> {
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getBooks();
      if (mounted) {
        setState(() {
          _books = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddBookDialog() {
    final theme = Theme.of(context);
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final qtyController = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catalog New Volume', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.primaryColor)),
            const SizedBox(height: 8),
            const Text('Add a new book record to the cloud library', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Book Title', border: OutlineInputBorder(), prefixIcon: Icon(Icons.book))),
            const SizedBox(height: 16),
            TextField(controller: authorController, decoration: const InputDecoration(labelText: 'Author Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 16),
            TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Copies Available', border: OutlineInputBorder(), prefixIcon: Icon(Icons.copy)), keyboardType: TextInputType.number),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    await SupabaseService.instance.saveBook({
                      'title': titleController.text.trim(),
                      'author': authorController.text.trim(),
                      'total_copies': int.tryParse(qtyController.text) ?? 1,
                      'available_copies': int.tryParse(qtyController.text) ?? 1,
                    });
                    Navigator.pop(context);
                    _loadBooks();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('SYNC TO LIBRARY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Knowledge Base', style: TextStyle(fontWeight: FontWeight.bold)),
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
            : _books.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final b = _books[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey.withOpacity(0.1),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.blueGrey),
                        ),
                        title: Text(b['title'] ?? 'Unknown Volume', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Author: ${b['author'] ?? "N/A"} • Available: ${b['available_copies'] ?? 0}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            await SupabaseService.instance.deleteBook(b['book_id']);
                            _loadBooks();
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBookDialog,
        backgroundColor: Colors.blueGrey.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.library_add_rounded),
        label: const Text('Add Book', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Cloud library is currently empty.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
