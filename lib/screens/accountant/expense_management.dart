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

  void _showAddExpenseDialog() {
    final theme = Theme.of(context);
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();

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
              Text('Record Cloud Expense', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.redAccent)),
              const SizedBox(height: 8),
              const Text('Log a new expenditure record to the school treasury', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                      await SupabaseService.instance.client.from('expenses').insert({
                        'category': categoryController.text.trim(),
                        'amount': double.tryParse(amountController.text) ?? 0.0,
                        'description': descController.text.trim(),
                        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      });
                      Navigator.pop(context);
                      _loadExpenses();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('AUTHORIZE DISBURSEMENT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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
                          trailing: Text('-Ksh ${item['amount']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent, fontSize: 16)),
                        ),
                      );
                    },
                  ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
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
