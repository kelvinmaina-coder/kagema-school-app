import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../services/pesapal_service.dart';
import 'package:url_launcher/url_launcher.dart';
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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final balanceData = await SupabaseService.instance.getStudentBalance(
        widget.student.studentId, 
        widget.student.grade
      );
      final history = await SupabaseService.instance.getFeeHistory(widget.student.studentId);
      
      if (mounted) {
        setState(() {
          _totalExpected = (balanceData['total_fee'] ?? 0.0).toDouble();
          _totalPaid = (balanceData['total_paid'] ?? 0.0).toDouble();
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processPayment() async {
    if (_amountController.text.isEmpty) return;
    
    setState(() => _isProcessing = true);
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (selectedMethod == 'M-Pesa (Stk Push)' || selectedMethod == 'Visa Card') {
      final response = await PesapalService.instance.initiatePayment(
        phoneNumber: widget.student.parentPhone,
        amount: amount,
        email: widget.student.parentEmail ?? 'parent@kagema.edu',
        reference: "FEES-${widget.student.admissionNumber}-${DateTime.now().millisecondsSinceEpoch}",
        studentName: widget.student.name,
      );

      if (response['success']) {
        final url = Uri.parse(response['redirect_url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          
          final receiptNo = 'PEN-${DateTime.now().millisecondsSinceEpoch}';
          final payment = {
            'student_id': widget.student.studentId,
            'student_name': widget.student.name,
            'amount_paid': amount,
            'term': selectedTerm,
            'year': DateTime.now().year,
            'payment_date': DateTime.now().toIso8601String(),
            'receipt_number': receiptNo,
            'payment_method': 'Pesapal (${response['order_tracking_id']})',
          };
          await SupabaseService.instance.insertFeePayment(payment);
          
          if (mounted) {
            setState(() => _isProcessing = false);
            _amountController.clear();
            _tabController.animateTo(1);
          }
        } else {
          _showError("System Error: Could not launch payment gateway.");
        }
      } else {
        _showError(response['message'] ?? "Payment Gateway Offline");
      }
      return;
    }

    _finalizeManualPayment(amount);
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)
    );
  }

  Future<void> _finalizeManualPayment(double amount) async {
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
      }
    } catch (e) {
      _showError("Sync Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('School Fees Portal', 
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
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'MAKE PAYMENT', icon: Icon(Icons.add_card_rounded, size: 18)),
            Tab(text: 'HISTORY', icon: Icon(Icons.history_edu_rounded, size: 18)),
          ],
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPaymentTab(theme, gemini),
                  _buildHistoryTab(theme, gemini),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildPaymentTab(ThemeData theme, GeminiThemeExtension? gemini) {
    double balance = _totalExpected - _totalPaid;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryHeader(theme, gemini, balance),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('PAYMENT DETAILS', 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentForm(theme, gemini),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Column(
      children: [
        _buildDropdown('Select Term', selectedTerm, ['Term 1', 'Term 2', 'Term 3'], (v) => setState(() => selectedTerm = v!), Icons.layers_rounded, theme),
        const SizedBox(height: 20),
        _buildDropdown('Payment Method', selectedMethod, ['M-Pesa (Stk Push)', 'Visa Card', 'Bank Transfer'], (v) => setState(() => selectedMethod = v!), Icons.hub_rounded, theme),
        const SizedBox(height: 20),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green),
          decoration: InputDecoration(
            labelText: 'Amount to Pay (Ksh)', 
            labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            prefixIcon: const Icon(Icons.payments_rounded, color: Colors.green, size: 20),
            filled: true,
            fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: Colors.green.withOpacity(0.4),
            ),
            child: _isProcessing 
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
              : const Text('CONFIRM PAYMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
          ),
        )
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 30,
      borderThickness: 1.5,
      backgroundColor: theme.cardColor.withOpacity(0.9),
      padding: const EdgeInsets.all(24),
      child: content,
    ) ?? Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(28)),
      child: content,
    );
  }

  Widget _buildSummaryHeader(ThemeData theme, GeminiThemeExtension? gemini, double balance) {
    final content = Column(
      children: [
        _summaryRow('Total Term Fees', 'Ksh ${NumberFormat('#,###').format(_totalExpected)}'),
        const Divider(color: Colors.white10),
        _summaryRow('Amount Paid', 'Ksh ${NumberFormat('#,###').format(_totalPaid)}', color: Colors.green),
        const Divider(color: Colors.white10),
        _summaryRow('Outstanding Balance', 'Ksh ${NumberFormat('#,###').format(balance)}', color: balance > 0 ? Colors.red : Colors.green, bold: true),
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 30,
      borderThickness: 2,
      backgroundColor: theme.primaryColor.withOpacity(0.05),
      padding: const EdgeInsets.all(24),
      child: content,
    ) ?? Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: content,
    );
  }

  Widget _summaryRow(String l, String v, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.blueGrey)),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w800, color: color, fontSize: bold ? 20 : 15, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_history.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final content = ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.green, size: 24),
          ),
          title: Text('Ksh ${NumberFormat('#,###').format(item['amount_paid'])}', 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)
          ),
          subtitle: Text('${item['term']} • Ref: ${item['receipt_number']}', 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item['payment_date'].toString().split('T')[0], 
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
            ],
          ),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: gemini?.buildGlowContainer(
            borderRadius: 28,
            borderThickness: 1,
            backgroundColor: theme.cardColor.withOpacity(0.85),
            padding: EdgeInsets.zero,
            child: content,
          ) ?? Card(child: content),
        );
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged, IconData icon, ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.green, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
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
          Text('NO PAYMENT RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
