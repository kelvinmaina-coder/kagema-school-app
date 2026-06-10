import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/school_models.dart';
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
      debugPrint("Library Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBookForm({Map<String, dynamic>? book}) {
    final titleController = TextEditingController(text: book?['title']);
    final authorController = TextEditingController(text: book?['author']);
    final isbnController = TextEditingController(text: book?['isbn']);
    final qtyController = TextEditingController(text: book?['total_copies']?.toString() ?? '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(book == null ? 'Catalog New Book' : 'Update Catalog Entry', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Book Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: authorController, decoration: const InputDecoration(labelText: 'Author Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: isbnController, decoration: const InputDecoration(labelText: 'ISBN Number', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Copies', border: OutlineInputBorder())),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    await SupabaseService.instance.saveBook({
                      'bookId': book?['book_id'],
                      'title': titleController.text.trim(),
                      'author': authorController.text.trim(),
                      'isbn': isbnController.text.trim(),
                      'category': 'General',
                      'availableCopies': int.tryParse(qtyController.text) ?? 1,
                      'totalCopies': int.tryParse(qtyController.text) ?? 1,
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      _loadBooks();
                    }
                  }
                },
                child: const Text('SYNC TO CATALOG'),
              ),
            ),
            const SizedBox(height: 30),
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
      appBar: AppBar(
        title: const Text('Library Catalog'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _books.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _books.length,
                    itemBuilder: (context, index) {
                      final book = _books[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.brown, child: Icon(Icons.menu_book, color: Colors.white, size: 20)),
                          title: Text(book['title'] ?? 'Unknown Book', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('By ${book['author']} • ${book['available_copies']}/${book['total_copies']} In Stock'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note, color: Colors.blue),
                                onPressed: () => _showBookForm(book: book),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                                onPressed: () async {
                                  await SupabaseService.instance.deleteBook(book['book_id']);
                                  _loadBooks();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookForm(),
        backgroundColor: Colors.brown.shade700,
        label: const Text('New Book', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
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
          Text('Your library catalog is empty.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
