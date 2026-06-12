import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class IncomeManagementScreen extends StatefulWidget {
  const IncomeManagementScreen({super.key});

  @override
  State<IncomeManagementScreen> createState() => _IncomeManagementScreenState();
}

class _IncomeManagementScreenState extends State<IncomeManagementScreen> {
  List<Map<String, dynamic>> _incomes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.instance.client
          .from('income')
          .select()
          .order('date', ascending: false);
      if (mounted) {
        setState(() {
          _incomes = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddIncomeDialog({Map<String, dynamic>? incomeToEdit}) {
    final theme = Theme.of(context);
    final isEditing = incomeToEdit != null;
    final sourceCtrl = TextEditingController(text: incomeToEdit?['source']);
    final amountCtrl = TextEditingController(text: incomeToEdit?['amount']?.toString());

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
            Text(isEditing ? 'Adjust Revenue Record' : 'New Income Record', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green.shade700)),
            const SizedBox(height: 24),
            TextField(controller: sourceCtrl, decoration: const InputDecoration(labelText: 'Income Source', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business_center_rounded))),
            const SizedBox(height: 16),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (Ksh)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.payments)), keyboardType: TextInputType.number),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (sourceCtrl.text.isNotEmpty) {
                    final data = {
                      'source': sourceCtrl.text.trim(),
                      'amount': double.parse(amountCtrl.text),
                      'date': incomeToEdit?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    };
                    
                    if (isEditing) {
                      await SupabaseService.instance.client.from('income').update(data).eq('income_id', incomeToEdit['income_id']);
                    } else {
                      await SupabaseService.instance.client.from('income').insert(data);
                    }
                    
                    if (mounted) {
                      Navigator.pop(context);
                      _loadIncomes();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(isEditing ? 'UPDATE ENTRY' : 'AUTHORIZE ENTRY', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteIncome(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Revenue?'),
        content: Text('Delete income record for "${item['source']}"? This affects financial totals.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('VOID', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.client.from('income').delete().eq('income_id', item['income_id']);
      _loadIncomes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Revenue Streams', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green.shade800, Colors.green.shade400]),
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
            : _incomes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _incomes.length,
                  itemBuilder: (context, index) {
                    final item = _incomes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          child: const Icon(Icons.add_chart_rounded, color: Colors.green),
                        ),
                        title: Text(item['source'] ?? 'General Income', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item['date'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Ksh ${item['amount']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 16)),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') _showAddIncomeDialog(incomeToEdit: item);
                                if (val == 'delete') _deleteIncome(item);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, size: 20), title: Text('Edit'), dense: true)),
                                const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red, size: 20), title: Text('Void'), dense: true)),
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
        onPressed: () => _showAddIncomeDialog(),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Revenue', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No external revenue records.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
