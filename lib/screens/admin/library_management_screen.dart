import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:uuid/uuid.dart';

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
      final data = await SupabaseService.instance.client.from('library_books').select().order('title');
      setState(() {
        _books = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddBookDialog({Map<String, dynamic>? book}) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final titleCtrl = TextEditingController(text: book?['title']);
    final authorCtrl = TextEditingController(text: book?['author']);
    final copiesCtrl = TextEditingController(text: book?['total_copies']?.toString() ?? '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LIBRARY BOOK ENTRY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
            const SizedBox(height: 24),
            _buildField(titleCtrl, 'Book Title', Icons.book_rounded, theme),
            const SizedBox(height: 16),
            _buildField(authorCtrl, 'Author', Icons.person_outline, theme),
            const SizedBox(height: 16),
            _buildField(copiesCtrl, 'Number of Copies', Icons.copy_rounded, theme, keyboardType: TextInputType.number),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty) {
                    final data = {
                      'book_id': book?['book_id'] ?? const Uuid().v4(),
                      'title': titleCtrl.text.trim(),
                      'author': authorCtrl.text.trim(),
                      'total_copies': int.tryParse(copiesCtrl.text) ?? 1,
                      'available_copies': int.tryParse(copiesCtrl.text) ?? 1,
                    };
                    await SupabaseService.instance.client.from('library_books').upsert(data);
                    if (mounted) { Navigator.pop(context); _loadBooks(); }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text('SAVE TO LIBRARY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String l, IconData i, ThemeData t, {TextInputType? keyboardType}) => TextField(controller: c, keyboardType: keyboardType, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: t.primaryColor), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Library Management', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.blueGrey.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20)],
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.local_library_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty 
            ? _buildEmptyState()
            : ListView.builder(
                padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, left: 20, right: 20, bottom: 100),
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index];
                  final content = ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.menu_book_rounded, color: Colors.blueGrey, size: 24)),
                    title: Text(book['title'] ?? 'Book Title', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    subtitle: Text('Author: ${book['author']}\nAvailable: ${book['available_copies']}/${book['total_copies']}', style: const TextStyle(fontSize: 11, height: 1.4)),
                    trailing: IconButton(icon: const Icon(Icons.edit_note_rounded), onPressed: () => _showAddBookDialog(book: book)),
                  );
                  return Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content));
                },
              ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30, borderThickness: 2, backgroundColor: theme.primaryColor, padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(onPressed: () => _showAddBookDialog(), backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, icon: const Icon(Icons.add_rounded), label: const Text('Add New Book', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1))),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.local_library_rounded, size: 80, color: Colors.grey), SizedBox(height: 16), Text('NO BOOKS RECORDED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5))]));
}
