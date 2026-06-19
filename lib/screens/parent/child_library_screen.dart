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
  final String _roleId = 'parent';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = DT.of(context);
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: Text('${widget.student.name.toUpperCase()}\'S LIBRARY', 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 3, color: Colors.white)
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
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.local_library_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: NeuralBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : _borrowedBooks.isEmpty 
                ? _buildEmptyState(dt)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: _borrowedBooks.length,
                    itemBuilder: (context, index) {
                      final record = _borrowedBooks[index];
                      final book = record['library_books'];
                      final status = record['status'] ?? 'Borrowed';
                      final isOverdue = status.toLowerCase() == 'overdue';
                      final itemColor = isOverdue ? KagemaColors.parentRed : KagemaColors.teacherGreen;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: LiquidGlassCard(
                          accentColor: itemColor,
                          borderRadius: 28,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: dt.roleSoftBg(itemColor), shape: BoxShape.circle),
                              child: Icon(Icons.book_rounded, color: itemColor, size: 24),
                            ),
                            title: Text(book?['title'] ?? 'Book Record', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Return Date: ${record['due_date'] ?? "N/A"}', 
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dt.textSecondary)
                              ),
                            ),
                            trailing: _statusChip(dt, status),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(DT dt, String status) {
    bool isOverdue = status.toLowerCase() == 'overdue';
    Color color = isOverdue ? KagemaColors.parentRed : KagemaColors.teacherGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: dt.roleSoftBg(color),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO ACTIVE BOOK LOANS', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
