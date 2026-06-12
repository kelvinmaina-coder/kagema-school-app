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

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.instance.client
          .from('expenses')
          .select()
          .order('date', ascending: false);
      if (mounted) {
        setState(() {
          _expenses = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddExpenseDialog({Map<String, dynamic>? expenseToEdit}) {
    final theme = Theme.of(context);
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
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditing ? 'Adjust Expense Record' : 'Record Cloud Expense', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.redAccent)),
              const SizedBox(height: 8),
              Text(isEditing ? 'Update the details of this expenditure' : 'Log a new expenditure record to the school treasury', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(
                controller: categoryController, 
                decoration: const InputDecoration(labelText: 'Expense Category', prefixIcon: Icon(Icons.category_rounded), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController, 
                keyboardType: TextInputType.number, 
                decoration: const InputDecoration(labelText: 'Amount (Ksh)', prefixIcon: Icon(Icons.payments), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController, 
                decoration: const InputDecoration(labelText: 'Description / Purpose', prefixIcon: Icon(Icons.notes), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (categoryController.text.isNotEmpty && amountController.text.isNotEmpty) {
                      final data = {
                        'category': categoryController.text.trim(),
                        'amount': double.tryParse(amountController.text) ?? 0.0,
                        'description': descController.text.trim(),
                        'date': expenseToEdit?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      };
                      
                      if (isEditing) {
                        await SupabaseService.instance.client.from('expenses').update(data).eq('expense_id', expenseToEdit['expense_id']);
                      } else {
                        await SupabaseService.instance.client.from('expenses').insert(data);
                      }
                      
                      if (mounted) {
                        Navigator.pop(context);
                        _loadExpenses();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(isEditing ? 'UPDATE RECORD' : 'AUTHORIZE DISBURSEMENT', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteExpense(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text('Remove this record of Ksh ${item['amount']}? This will permanently adjust financial reports.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.client.from('expenses').delete().eq('expense_id', item['expense_id']);
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
        title: const Text('Expense Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.redAccent, Colors.red.shade900]),
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
            : _expenses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final item = _expenses[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            child: const Icon(Icons.money_off_rounded, color: Colors.redAccent),
                          ),
                          title: Text(item['category'] ?? 'General Expense', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item['date']} • ${item['description'] ?? "No details"}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('-Ksh ${item['amount']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent, fontSize: 16)),
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'edit') _showAddExpenseDialog(expenseToEdit: item);
                                  if (val == 'delete') _deleteExpense(item);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, size: 20), title: Text('Edit'), dense: true)),
                                  const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red, size: 20), title: Text('Delete'), dense: true)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No expenditure records found.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
