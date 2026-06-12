import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class FeeManagementScreen extends StatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> {
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  double _totalCollected = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final payments = await SupabaseService.instance.client
          .from('fees')
          .select('*, students(name, admission_number)')
          .order('payment_date', ascending: false);
      
      final studentList = await SupabaseService.instance.getAllStudents();

      if (mounted) {
        setState(() {
          _payments = List<Map<String, dynamic>>.from(payments);
          _students = studentList;
          _totalCollected = _payments.fold(0.0, (sum, p) => sum + (p['amount_paid'] ?? 0));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fee Data Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPaymentDialog({Map<String, dynamic>? paymentToEdit}) {
    final theme = Theme.of(context);
    String? selectedStudentId = paymentToEdit?['student_id']?.toString();
    final amountController = TextEditingController(text: paymentToEdit?['amount_paid']?.toString() ?? '');
    final receiptController = TextEditingController(text: paymentToEdit?['receipt_number'] ?? 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    String selectedMethod = paymentToEdit?['payment_method'] ?? 'Cash';
    final isEditing = paymentToEdit != null;

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
              Text(isEditing ? 'Adjust Revenue Record' : 'Log Revenue Entry', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green.shade700)),
              const SizedBox(height: 8),
              Text(isEditing ? 'Modify the details of this financial transaction' : 'Record a student fee payment to the cloud treasury', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: selectedStudentId,
                hint: const Text('Select Pupil'),
                items: _students.map((s) => DropdownMenuItem(value: s['student_id'].toString(), child: Text('${s['name']} (${s['admission_number']})'))).toList(),
                onChanged: isEditing ? null : (v) => selectedStudentId = v,
                decoration: const InputDecoration(labelText: 'Student Reference', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController, 
                decoration: const InputDecoration(labelText: 'Amount (Ksh)', prefixIcon: Icon(Icons.payments), border: OutlineInputBorder()), 
                keyboardType: TextInputType.number
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                items: ['Cash', 'M-Pesa', 'Bank Transfer', 'Cheque'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => selectedMethod = v!,
                decoration: const InputDecoration(labelText: 'Payment Gateway', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: receiptController,
                decoration: const InputDecoration(labelText: 'Receipt / Ref Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedStudentId != null && amountController.text.isNotEmpty) {
                      final data = {
                        'student_id': selectedStudentId,
                        'amount_paid': double.parse(amountController.text),
                        'payment_method': selectedMethod,
                        'receipt_number': receiptController.text,
                        'payment_date': paymentToEdit?['payment_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        'term': paymentToEdit?['term'] ?? 'Term 1',
                        'year': paymentToEdit?['year'] ?? DateTime.now().year,
                      };
                      
                      if (isEditing) {
                        data['fee_id'] = paymentToEdit['fee_id'];
                        await SupabaseService.instance.updateFeePayment(data);
                      } else {
                        await SupabaseService.instance.insertFeePayment(data);
                      }
                      
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(isEditing ? 'UPDATE RECORD' : 'AUTHORIZE PAYMENT', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Transaction?'),
        content: Text('Are you sure you want to delete this payment of Ksh ${payment['amount_paid']}? This will affect financial reports.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('VOID', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteFeePayment(payment['fee_id'].toString());
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: const Text('Cloud Treasury', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green.shade800, Colors.green.shade500]),
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
            : Column(
                children: [
                  _buildStatsHeader(theme),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _payments.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final p = _payments[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.withOpacity(0.1),
                                  child: const Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
                                ),
                                title: Text(p['students']?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${p['payment_method']} • ${p['payment_date']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Ksh ${p['amount_paid']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green)),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                                      onSelected: (val) {
                                        if (val == 'edit') _showPaymentDialog(paymentToEdit: p);
                                        if (val == 'delete') _confirmDelete(p);
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
                ],
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentDialog(),
        backgroundColor: Colors.green.shade700, 
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card_rounded), 
        label: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatsHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL REVENUE COLLECTED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('Ksh ${NumberFormat('#,###').format(_totalCollected)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green)),
            ],
          ),
          const Icon(Icons.trending_up_rounded, color: Colors.green, size: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No cloud payment records found.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
