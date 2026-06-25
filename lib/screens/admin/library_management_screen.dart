import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class LibraryManagementScreen extends StatefulWidget {
  const LibraryManagementScreen({super.key});

  @override
  State<LibraryManagementScreen> createState() => _LibraryManagementScreenState();
}

class _LibraryManagementScreenState extends State<LibraryManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _borrowedBooks = [];
  final String _roleId = 'admin';

  @override
  void initState() {
    super.initState();
    _loadLibraryData();
  }

  Future<void> _loadLibraryData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Fetching all borrowed books for management
      final data = await SupabaseService.instance.client
          .from('borrowed_books')
          .select('*, students(name), library_books(title)')
          .order('due_date');
      
      if (mounted) {
        setState(() {
          _borrowedBooks = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('LIBRARY CENTER', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.local_library_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)))]),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : _borrowedBooks.isEmpty 
                ? _buildEmptyState(dt)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _borrowedBooks.length,
                    itemBuilder: (context, index) {
                      final item = _borrowedBooks[index];
                      final isOverdue = DateTime.parse(item['due_date']).isBefore(DateTime.now());
                      final itemColor = isOverdue ? dt.error : dt.info;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: theme.buildGlowContainer(
                          accentColor: itemColor,
                          borderRadius: 24,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: dt.roleSoftBg(itemColor), shape: BoxShape.circle),
                              child: Icon(Icons.book_rounded, color: itemColor, size: 24),
                            ),
                            title: Text(item['library_books']?['title']?.toString().toUpperCase() ?? 'BOOK', 
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)
                            ),
                            subtitle: Text('Pupil: ${item['students']?['name']}\nDue: ${item['due_date']}', 
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dt.textSecondary, height: 1.4)
                            ),
                            trailing: isOverdue 
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: dt.roleSoftBg(dt.error), borderRadius: BorderRadius.circular(8)),
                                  child: Text('OVERDUE', style: TextStyle(color: dt.error, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1)),
                                )
                              : Icon(Icons.chevron_right_rounded, color: dt.iconInactive),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO ACTIVE LENDING RECORDS', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
