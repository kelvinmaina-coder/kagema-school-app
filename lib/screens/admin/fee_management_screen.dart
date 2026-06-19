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

  final String _roleId = 'admin';

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

  void _showPaymentDialog(DT dt, GeminiThemeExtension? theme, {Map<String, dynamic>? paymentToEdit}) {
    String? selectedStudentId = paymentToEdit?['student_id']?.toString();
    final amountController = TextEditingController(text: paymentToEdit?['amount_paid']?.toString() ?? '');
    final receiptController = TextEditingController(text: paymentToEdit?['receipt_number'] ?? 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    String selectedMethod = paymentToEdit?['payment_method'] ?? 'Cash';
    final isEditing = paymentToEdit != null;
    final roleColor = RoleColors.of(_roleId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 35,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(isEditing ? 'MODIFY TRANSACTION' : 'SECURE REVENUE ENTRY', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(isEditing ? 'Adjust Record' : 'Log Cloud Treasury', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)
                ),
                const SizedBox(height: 32),
                DropdownButtonFormField<String>(
                  value: selectedStudentId,
                  hint: Text('Select Pupil', style: TextStyle(color: dt.hint)),
                  dropdownColor: dt.cardBg,
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  items: _students.map((s) => DropdownMenuItem(value: s['student_id'].toString(), child: Text('${s['name']} (${s['admission_number']})'))).toList(),
                  onChanged: isEditing ? null : (v) => selectedStudentId = v,
                  decoration: _neuralInputDecoration('Student Reference', Icons.person_search_rounded, dt),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController, 
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  decoration: _neuralInputDecoration('Amount (Ksh)', Icons.payments_rounded, dt),
                  keyboardType: TextInputType.number
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  dropdownColor: dt.cardBg,
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  items: ['Cash', 'M-Pesa', 'Bank Transfer', 'Cheque'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => selectedMethod = v!,
                  decoration: _neuralInputDecoration('Payment Gateway', Icons.account_balance_rounded, dt),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: receiptController,
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  decoration: _neuralInputDecoration('Receipt / Ref Number', Icons.qr_code_scanner_rounded, dt),
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
                    child: Text(isEditing ? 'COMMIT UPDATES' : 'AUTHORIZE TREASURY SYNC', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox.shrink(),
      ),
    );
  }

  InputDecoration _neuralInputDecoration(String label, IconData icon, DT dt) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: KagemaColors.teacherGreen, size: 20),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> payment) async {
    final dt = context.dt;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Void Transaction?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Text('Are you sure you want to delete this payment of Ksh ${payment['amount_paid']}? This will affect financial reports.', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: TextStyle(color: dt.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('VOID', style: TextStyle(color: KagemaColors.parentRed, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteFeePayment(payment['fee_id'].toString());
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: KagemaColors.parentRed));
      }
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
        title: const Text('QUANTUM TREASURY', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3, fontSize: 16)),
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
                child: Icon(Icons.account_balance_wallet_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
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
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : Column(
                  children: [
                    _buildStatsHeader(dt, theme),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _payments.isEmpty
                        ? _buildEmptyState(dt)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _payments.length,
                            itemBuilder: (context, index) {
                              final p = _payments[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: theme?.buildGlowContainer(
                                  accentColor: KagemaColors.teacherGreen,
                                  borderRadius: 24,
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: dt.roleSoftBg(KagemaColors.teacherGreen),
                                      child: const Icon(Icons.account_balance_wallet_rounded, color: KagemaColors.teacherGreen, size: 20),
                                    ),
                                    title: Text(p['students']?['name'] ?? 'Unknown Pupil', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary)),
                                    subtitle: Text('${p['payment_method']} • ${p['payment_date']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dt.textSecondary)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Ksh ${p['amount_paid']}', style: const TextStyle(fontWeight: FontWeight.w900, color: KagemaColors.teacherGreen, fontSize: 15)),
                                        const SizedBox(width: 8),
                                        PopupMenuButton<String>(
                                          icon: Icon(Icons.more_vert, color: dt.iconInactive),
                                          color: dt.cardBg,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          onSelected: (val) {
                                            if (val == 'edit') _showPaymentDialog(dt, theme, paymentToEdit: p);
                                            if (val == 'delete') _confirmDelete(p);
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note_rounded, size: 20, color: dt.textPrimary), title: Text('Edit Info', style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary)), dense: true)),
                                            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever_rounded, color: KagemaColors.parentRed, size: 20), title: Text('Delete', style: TextStyle(color: KagemaColors.parentRed, fontWeight: FontWeight.bold)), dense: true)),
                                          ],
                                        ),
                                      ],
                                    ),
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
      ) ?? const SizedBox.shrink(),
      floatingActionButton: RolePlasma(
        color: KagemaColors.teacherGreen,
        child: FloatingActionButton.extended(
          onPressed: () => _showPaymentDialog(dt, theme),
          backgroundColor: KagemaColors.teacherGreen,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_card_rounded), 
          label: const Text('LOG NEURAL PAYMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(DT dt, GeminiThemeExtension? theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: theme?.buildGlowContainer(
        accentColor: KagemaColors.teacherGreen,
        borderRadius: 28,
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL REVENUE COLLECTED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('Ksh ${NumberFormat('#,###.##').format(_totalCollected)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: KagemaColors.teacherGreen)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.teacherGreen), shape: BoxShape.circle),
              child: const Icon(Icons.trending_up_rounded, color: KagemaColors.teacherGreen, size: 30),
            ),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO CLOUD RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
