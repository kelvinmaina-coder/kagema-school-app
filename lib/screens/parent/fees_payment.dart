import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class FeesPaymentScreen extends StatefulWidget {
  final Student student;
  const FeesPaymentScreen({super.key, required this.student});

  @override
  State<FeesPaymentScreen> createState() => _FeesPaymentScreenState();
}

class _FeesPaymentScreenState extends State<FeesPaymentScreen> with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  late TabController _tabController;
  
  double _totalExpected = 0.0;
  double _totalPaid = 0.0;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  String selectedTerm = 'Term 1';
  String selectedMethod = 'M-Pesa (Stk Push)';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeeData();
  }

  Future<void> _loadFeeData() async {
    setState(() => _isLoading = true);
    try {
      // Get balance details from Supabase
      final balanceData = await SupabaseService.instance.getStudentBalance(
        widget.student.studentId, 
        widget.student.grade
      );
      
      // Get history from Supabase
      final history = await SupabaseService.instance.getFeeHistory(widget.student.studentId);
      
      if (mounted) {
        setState(() {
          _totalExpected = balanceData['required'];
          _totalPaid = balanceData['paid'];
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fee Data Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processPayment() async {
    if (_amountController.text.isEmpty) return;
    
    setState(() => _isProcessing = true);
    
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final receiptNo = 'RCP-${DateTime.now().millisecondsSinceEpoch}';

    final payment = {
      'student_id': widget.student.studentId,
      'student_name': widget.student.name,
      'amount_paid': amount,
      'term': selectedTerm,
      'year': DateTime.now().year,
      'payment_date': DateTime.now().toIso8601String(),
      'receipt_number': receiptNo,
      'payment_method': selectedMethod,
    };

    try {
      await SupabaseService.instance.insertFeePayment(payment);
      if (mounted) {
        _amountController.clear();
        await _loadFeeData();
        setState(() => _isProcessing = false);
        _tabController.animateTo(1);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful! Synced to Cloud.'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Failed: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Fee Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green, Colors.green.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'MAKE PAYMENT'), Tab(text: 'HISTORY')],
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPaymentTab(theme),
                  _buildHistoryTab(),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildPaymentTab(ThemeData theme) {
    double balance = _totalExpected - _totalPaid;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryHeader(theme, balance),
          const SizedBox(height: 32),
          Text('NEW PAYMENT FOR ${widget.student.name.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _buildDropdown('Select Term', selectedTerm, ['Term 1', 'Term 2', 'Term 3'], (v) => setState(() => selectedTerm = v!)),
                const SizedBox(height: 16),
                _buildDropdown('Payment Method', selectedMethod, ['M-Pesa (Stk Push)', 'Visa Card', 'Bank Transfer'], (v) => setState(() => selectedMethod = v!)),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (Ksh)', 
                    prefixIcon: Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isProcessing 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('AUTHORIZE CLOUD PAYMENT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(ThemeData theme, double balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _summaryRow('Total Fee (Term)', 'Ksh $_totalExpected'),
          const Divider(),
          _summaryRow('Amount Paid', 'Ksh $_totalPaid', color: Colors.green),
          const Divider(),
          _summaryRow('Current Balance', 'Ksh $balance', color: balance > 0 ? Colors.red : Colors.green, bold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String l, String v, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.bold, color: color, fontSize: bold ? 18 : 14)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) return const Center(child: Text('No cloud payment records found.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.receipt_long, color: Colors.white),
            ),
            title: Text('Ksh ${item['amount_paid']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${item['term']} • Ref: ${item['receipt_number']}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item['payment_date'].toString().split('T')[0], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label, 
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }
}
