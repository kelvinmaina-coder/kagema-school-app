import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class FeeManagementScreen extends StatefulWidget {
  final String? mode;
  const FeeManagementScreen({super.key, this.mode});

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
    final gemini = theme.extension<GeminiThemeExtension>();
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
                  Text(isEditing ? 'MODIFY TRANSACTION' : 'SECURE REVENUE ENTRY', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                  ),
                  const SizedBox(height: 8),
                  Text(isEditing ? 'Adjust Record' : 'Log Cloud Treasury', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                  const SizedBox(height: 32),
                  DropdownButtonFormField<String>(
                    value: selectedStudentId,
                    hint: const Text('Select Pupil'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    items: _students.map((s) => DropdownMenuItem(value: s['student_id'].toString(), child: Text('${s['name']} (${s['admission_number']})'))).toList(),
                    onChanged: isEditing ? null : (v) => selectedStudentId = v,
                    decoration: _neuralInputDecoration('Student Reference', Icons.person_search_rounded, theme),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController, 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: _neuralInputDecoration('Amount (Ksh)', Icons.payments_rounded, theme),
                    keyboardType: TextInputType.number
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    items: ['Cash', 'M-Pesa', 'Bank Transfer', 'Cheque'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => selectedMethod = v!,
                    decoration: _neuralInputDecoration('Payment Gateway', Icons.account_balance_rounded, theme),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: receiptController,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: _neuralInputDecoration('Receipt / Ref Number', Icons.qr_code_scanner_rounded, theme),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: Text(isEditing ? 'COMMIT UPDATES' : 'AUTHORIZE TREASURY SYNC', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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

  InputDecoration _neuralInputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.green, size: 20),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Void Transaction?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to delete this payment of Ksh ${payment['amount_paid']}? This will affect financial reports.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('VOID', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
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
        title: const Text('Quantum Treasury', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
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
              colors: [Colors.green.shade900, Colors.green.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.account_balance_wallet_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : Column(
                children: [
                  _buildStatsHeader(theme, gemini),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _payments.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final p = _payments[index];
                            final content = ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.green.withOpacity(0.1),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 20),
                              ),
                              title: Text(p['students']?['name'] ?? 'Unknown Pupil', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                              subtitle: Text('${p['payment_method']} • ${p['payment_date']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Ksh ${p['amount_paid']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 15)),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    onSelected: (val) {
                                      if (val == 'edit') _showPaymentDialog(paymentToEdit: p);
                                      if (val == 'delete') _confirmDelete(p);
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note_rounded, size: 20), title: Text('Edit Info', style: TextStyle(fontWeight: FontWeight.bold)), dense: true)),
                                      const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20), title: Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), dense: true)),
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
                ],
              ),
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: Colors.green.shade700,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showPaymentDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_card_rounded), 
          label: const Text('Log Neural Payment', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ) ?? FloatingActionButton.extended(
        onPressed: () => _showPaymentDialog(),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatsHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TOTAL REVENUE COLLECTED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Ksh ${NumberFormat('#,###.##').format(_totalCollected)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.trending_up_rounded, color: Colors.green, size: 30),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 28,
        borderThickness: 2,
        backgroundColor: theme.cardColor.withOpacity(0.9),
        padding: const EdgeInsets.all(24),
        child: content,
      ) ?? Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(28)),
        child: content,
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
          Text('NO CLOUD RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
