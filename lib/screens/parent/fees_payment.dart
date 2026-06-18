import 'package:flutter/material.dart';
import 'dart:ui';
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
  String selectedMethod = 'M-Pesa (STK Push)';

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
    if (_amountController.text.isEmpty) {
      _showError("PLEASE ENTER AN AMOUNT");
      return;
    }
    
    setState(() => _isProcessing = true);
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (selectedMethod == 'M-Pesa (STK Push)' || selectedMethod == 'Visa/Mastercard') {
      final response = await PesapalService.instance.initiatePayment(
        phoneNumber: widget.student.parentPhone,
        amount: amount,
        email: widget.student.parentEmail ?? 'finance@kagema.edu',
        reference: "FEES-${widget.student.admissionNumber}-${DateTime.now().millisecondsSinceEpoch}",
        studentName: widget.student.name,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (response['success']) {
          final url = Uri.parse(response['redirect_url']);
          
          // SHOW TRANSITION OVERLAY
          _showPaymentTransition(url, amount, response['order_tracking_id']);
        } else {
          _showError(response['message'] ?? "GATEWAY TEMPORARILY UNAVAILABLE");
        }
      }
      return;
    }

    _finalizeManualPayment(amount);
  }

  void _showPaymentTransition(Uri url, double amount, String trackingId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 40),
              const Icon(Icons.security_rounded, size: 64, color: Color(0xFF00E676)),
              const SizedBox(height: 24),
              const Text('SECURE CHECKOUT READY', 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)
              ),
              const SizedBox(height: 12),
              Text('You are being redirected to Pesapal for a secure Ksh ${amount.toInt()} payment.', 
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.5)
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  onPressed: () async {
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                      if (mounted) Navigator.pop(context);
                      
                      // Log as pending
                      final payment = {
                        'student_id': widget.student.studentId,
                        'student_name': widget.student.name,
                        'amount_paid': amount,
                        'term': selectedTerm,
                        'year': DateTime.now().year,
                        'payment_date': DateTime.now().toIso8601String(),
                        'receipt_number': 'TRK-$trackingId',
                        'payment_method': 'Pesapal (Pending)',
                      };
                      await SupabaseService.instance.insertFeePayment(payment);
                      _amountController.clear();
                      _tabController.animateTo(1);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('PROCEED TO PAYMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)), 
        backgroundColor: const Color(0xFFFF3D00), 
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )
    );
  }

  Future<void> _finalizeManualPayment(double amount) async {
    final receiptNo = 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
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
      _showError("OFFLINE: TRANSACTION QUEUED");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('FEES PORTAL', 
          style: TextStyle(
            fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 4, color: Colors.white, 
            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)]
          )
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF00E676)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
              Positioned(right: -30, top: -10, child: Icon(Icons.account_balance_wallet_rounded, size: 160, color: Colors.white.withValues(alpha: 0.12))),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 4, indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2),
          labelColor: Colors.white, unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
          tabs: const [Tab(text: 'PAYMENT'), Tab(text: 'HISTORY')],
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: theme.primaryColor, strokeWidth: 3))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPaymentTab(theme, gemini, isDark),
                  _buildHistoryTab(theme, gemini, isDark),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildPaymentTab(ThemeData theme, GeminiThemeExtension? gemini, bool isDark) {
    double balance = _totalExpected - _totalPaid;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryHeader(theme, gemini, balance, isDark),
          const SizedBox(height: 40),
          _buildSectionLabel('SECURE TRANSACTION'),
          const SizedBox(height: 16),
          _buildPaymentForm(theme, gemini, isDark),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(ThemeData theme, GeminiThemeExtension? gemini, bool isDark) {
    final content = Column(
      children: [
        _buildDropdown('SELECT TERM', selectedTerm, ['Term 1', 'Term 2', 'Term 3'], (v) => setState(() => selectedTerm = v!), Icons.layers_rounded, theme, isDark),
        const SizedBox(height: 20),
        _buildDropdown('PAYMENT METHOD', selectedMethod, ['M-Pesa (STK Push)', 'Visa/Mastercard', 'Bank Transfer'], (v) => setState(() => selectedMethod = v!), Icons.hub_rounded, theme, isDark),
        const SizedBox(height: 20),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'PAYMENT AMOUNT', 
            labelStyle: TextStyle(color: theme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
            prefixIcon: Icon(Icons.payments_rounded, color: theme.primaryColor),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: theme.primaryColor, width: 2)),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 65,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 5))]),
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
              child: Ink(
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF00E676)], begin: Alignment.centerLeft, end: Alignment.centerRight), borderRadius: BorderRadius.circular(22)),
                child: Container(
                  alignment: Alignment.center,
                  child: _isProcessing 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                    : const Text('INITIATE SECURE PAYMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Colors.white)),
                ),
              ),
            ),
          ),
        )
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 35, borderThickness: 1.5,
      backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
      padding: const EdgeInsets.all(24),
      child: content,
    ) ?? Container(decoration: BoxDecoration(color: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF), borderRadius: BorderRadius.circular(35)), padding: const EdgeInsets.all(24), child: content);
  }

  Widget _buildSummaryHeader(ThemeData theme, GeminiThemeExtension? gemini, double balance, bool isDark) {
    final content = Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('OUTSTANDING BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 2)),
            Icon(Icons.verified_rounded, color: balance <= 0 ? const Color(0xFF00E676) : Colors.blueGrey.withValues(alpha: 0.3), size: 18),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
          children: [
            Text('KSH', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 1)),
            const SizedBox(width: 8),
            Text(NumberFormat('#,###').format(balance), style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -2, color: isDark ? Colors.white : Colors.black87, shadows: [if (balance > 0) Shadow(color: const Color(0xFFFF3D00).withValues(alpha: 0.3), blurRadius: 15)])),
          ],
        ),
        const SizedBox(height: 24),
        Container(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1)),
        const SizedBox(height: 20),
        Row(
          children: [
            _miniStat('TOTAL INVOICED', 'Ksh ${NumberFormat('#,###').format(_totalExpected)}', isDark),
            Container(width: 1, height: 30, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1), margin: const EdgeInsets.symmetric(horizontal: 20)),
            _miniStat('PAID TO DATE', 'Ksh ${NumberFormat('#,###').format(_totalPaid)}', isDark, color: const Color(0xFF00E676)),
          ],
        ),
      ],
    );
    return gemini?.buildGlowContainer(borderRadius: 35, borderThickness: 2.5, backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF), padding: const EdgeInsets.all(28), useAIBorder: balance > 0, child: content) 
           ?? Container(decoration: BoxDecoration(color: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF), borderRadius: BorderRadius.circular(35)), padding: const EdgeInsets.all(28), child: content);
  }

  Widget _miniStat(String l, String v, bool isDark, {Color? color}) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 1)), const SizedBox(height: 4), Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color ?? (isDark ? Colors.white70 : Colors.black54)))]));
  }

  Widget _buildHistoryTab(ThemeData theme, GeminiThemeExtension? gemini, bool isDark) {
    if (_history.isEmpty) return _buildEmptyState(isDark);
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final content = ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF00E676).withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.2))), child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF00E676), size: 22)),
          title: Text('Ksh ${NumberFormat('#,###').format(item['amount_paid'])}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          subtitle: Text('${item['term'].toString().toUpperCase()}  |  REF: ${item['receipt_number']}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 0.5)),
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white12 : Colors.black12),
        );
        return Padding(padding: const EdgeInsets.only(bottom: 16), child: gemini?.buildGlowContainer(borderRadius: 28, borderThickness: 1.2, backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: content) 
               ?? Container(decoration: BoxDecoration(color: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF), borderRadius: BorderRadius.circular(28)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: content));
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged, IconData icon, ThemeData theme, bool isDark) {
    return DropdownButtonFormField<String>(
      value: value, dropdownColor: isDark ? const Color(0xFF1A1C22) : Colors.white,
      style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, fontSize: 14),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: theme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
        prefixIcon: Icon(icon, color: theme.primaryColor, size: 20), filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: theme.primaryColor, width: 2)),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(children: [Container(width: 4, height: 14, decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 8), Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2.5))]);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_edu_rounded, size: 80, color: isDark ? Colors.white12 : Colors.black12), const SizedBox(height: 24), const Text('NO TRANSACTION HISTORY', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 3, fontSize: 12))]));
  }
}
