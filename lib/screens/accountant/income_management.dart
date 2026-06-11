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
                        trailing: Text('Ksh ${item['amount']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 16)),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddIncomeDialog,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Revenue', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddIncomeDialog() {
    final theme = Theme.of(context);
    final sourceCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

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
            Text('New Income Record', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green.shade700)),
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
                    await SupabaseService.instance.client.from('income').insert({
                      'source': sourceCtrl.text.trim(),
                      'amount': double.parse(amountCtrl.text),
                      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    });
                    Navigator.pop(context);
                    _loadIncomes();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('AUTHORIZE ENTRY', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
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
