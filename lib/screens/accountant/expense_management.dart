import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await SupabaseService.instance.getExpenses();
      if (mounted) {
        setState(() {
          _expenses = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Connection lost. Please refresh the list.";
        });
      }
    }
  }

  void _showAddExpenseDialog({Map<String, dynamic>? expenseToEdit}) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isEditing = expenseToEdit != null;
    final categoryController = TextEditingController(text: expenseToEdit?['category']);
    final amountController = TextEditingController(text: expenseToEdit?['amount']?.toString());
    final descController = TextEditingController(text: expenseToEdit?['description']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: gemini?.buildCreativeBackground(
          isDark: theme.brightness == Brightness.dark,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text(isEditing ? 'EDIT EXPENSE' : 'NEW EXPENSE RECORD', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                  ),
                  const SizedBox(height: 8),
                  Text(isEditing ? 'Update Details' : 'Record Expenditure', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                  const SizedBox(height: 32),
                  _buildInputField('Expense Category', Icons.category_rounded, categoryController, theme),
                  const SizedBox(height: 16),
                  _buildInputField('Amount (Ksh)', Icons.payments_rounded, amountController, theme, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildInputField('Description / Purpose', Icons.notes_rounded, descController, theme, maxLines: 3),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (categoryController.text.isNotEmpty && amountController.text.isNotEmpty) {
                          final data = {
                            'expense_id': expenseToEdit?['expense_id'],
                            'category': categoryController.text.trim(),
                            'amount': double.tryParse(amountController.text) ?? 0.0,
                            'description': descController.text.trim(),
                            'date': expenseToEdit?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          };
                          
                          try {
                            await SupabaseService.instance.upsertExpense(data);
                            if (mounted) {
                              Navigator.pop(context);
                              _loadExpenses();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Expense Recorded Successfully', style: TextStyle(fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.red.shade800,
                                  behavior: SnackBarBehavior.floating,
                                )
                              );
                            }
                          } catch (e) {
                             if (mounted) {
                               Navigator.pop(context);
                               _loadExpenses();
                             }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800, 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: Text(isEditing ? 'UPDATE RECORD' : 'SAVE EXPENSE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ) ?? const SizedBox(),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.redAccent, size: 20),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController ctrl, ThemeData theme, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: _inputDecoration(label, icon, theme),
    );
  }

  Future<void> _deleteExpense(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Record?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Remove this record of Ksh ${item['amount']}? This will permanently delete the record.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.deleteExpense(item['expense_id'].toString());
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Expense Records', 
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
              colors: [Colors.red.shade900, Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.money_off_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildSummaryHeader(theme, gemini),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                  : RefreshIndicator(
                      onRefresh: _loadExpenses,
                      color: Colors.redAccent,
                      child: _expenses.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: _expenses.length,
                              itemBuilder: (context, index) {
                                final item = _expenses[index];
                                final content = ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.money_off_rounded, color: Colors.redAccent, size: 24),
                                  ),
                                  title: Text(item['category'] ?? 'General Expense', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('${item['date']} • ${item['description'] ?? "No details"}', 
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('-Ksh ${item['amount']}', 
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent, fontSize: 16)
                                      ),
                                      const SizedBox(width: 8),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        onSelected: (val) {
                                          if (val == 'edit') _showAddExpenseDialog(expenseToEdit: item);
                                          if (val == 'delete') _deleteExpense(item);
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note_rounded, size: 20), title: Text('Edit details', style: TextStyle(fontWeight: FontWeight.bold)), dense: true)),
                                          const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20), title: Text('Delete entry', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), dense: true)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: gemini?.buildGlowContainer(
                                    borderRadius: 24,
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
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: Colors.redAccent,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddExpenseDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text('Log New Expense', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    double total = _expenses.fold(0.0, (sum, item) => sum + (item['amount'] as num? ?? 0.0).toDouble());
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TOTAL EXPENDITURE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.trending_down_rounded, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Text('Ksh ${NumberFormat("#,##0.##").format(total)}', 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.redAccent)
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.analytics_rounded, color: Colors.redAccent, size: 26),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: gemini?.buildGlowContainer(
        borderRadius: 28,
        borderThickness: 2,
        backgroundColor: theme.cardColor.withOpacity(0.9),
        padding: const EdgeInsets.all(24),
        child: content,
      ) ?? Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24)),
        child: content,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('NO EXPENSE RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
