import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../services/pesapal_service.dart';
import '../../app_theme.dart';

class FeesPaymentScreen extends StatefulWidget {
  final Student student;
  const FeesPaymentScreen({super.key, required this.student});

  @override
  State<FeesPaymentScreen> createState() => _FeesPaymentScreenState();
}

class _FeesPaymentScreenState extends State<FeesPaymentScreen> {
  bool _isLoading = true;
  double _totalFee = 0;
  double _paidAmount = 0;
  double _balance = 0;
  List<Map<String, dynamic>> _paymentHistory = [];
  final String _roleId = 'parent';

  @override
  void initState() {
    super.initState();
    _loadFeeData();
  }

  Future<void> _loadFeeData() async {
    setState(() => _isLoading = true);
    try {
      final balanceData = await SupabaseService.instance.getStudentBalance(
        widget.student.studentId, 
        widget.student.grade
      );
      final history = await SupabaseService.instance.getFeeHistory(widget.student.studentId);

      if (mounted) {
        setState(() {
          _totalFee = (balanceData['total_fee'] as num).toDouble();
          _paidAmount = (balanceData['total_paid'] as num).toDouble();
          _balance = (balanceData['balance'] as num).toDouble();
          _paymentHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPaymentModal() {
    final dt = DT.of(context);
    final theme = context.kagemaTheme;
    final amountController = TextEditingController(
      text: _balance > 0 ? _balance.toStringAsFixed(0) : ''
    );
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 32),
              Text('M-PESA STK PUSH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13, color: dt.textPrimary)),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: dt.textPrimary),
                decoration: InputDecoration(
                  labelText: 'AMOUNT TO PAY',
                  prefixText: 'Ksh ',
                  prefixStyle: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary),
                ),
              ),
              const SizedBox(height: 32),
              if (isProcessing)
                const CircularProgressIndicator(color: KagemaColors.teacherGreen)
              else
                SizedBox(
                  width: double.infinity, height: 65,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (amountController.text.isEmpty) return;
                      setModalState(() => isProcessing = true);
                      
                      try {
                        final response = await PesapalService.instance.initiatePayment(
                          phoneNumber: widget.student.parentPhone,
                          amount: double.parse(amountController.text),
                          email: widget.student.parentEmail ?? 'finance@kagema.edu',
                          reference: "FEES-${widget.student.admissionNumber}-${DateTime.now().millisecondsSinceEpoch}",
                          studentName: widget.student.name,
                        );

                        if (mounted) {
                          setModalState(() => isProcessing = false);
                          if (response['success']) {
                            final url = Uri.parse(response['redirect_url']);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                              Navigator.pop(context);
                            } else {
                              throw 'Could not launch payment gateway';
                            }
                          } else {
                            throw response['message'] ?? 'Gateway Error';
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          setModalState(() => isProcessing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Payment failed: $e'), backgroundColor: KagemaColors.parentRed)
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KagemaColors.teacherGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('AUTHORIZE PAYMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ),
            ],
          );

          return theme?.buildGlowContainer(
            borderRadius: 40,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 40,
              left: 32, right: 32, top: 24
            ),
            child: content,
          ) ?? Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 40,
              left: 32, right: 32, top: 24
            ),
            decoration: BoxDecoration(color: dt.cardBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
            child: content,
          );
        },
      ),
    );
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
        title: const Text('FEE PORTAL', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 4, color: Colors.white)
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
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
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
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: roleColor))
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20,
                  left: 20, right: 20, bottom: 40
                ),
                children: [
                  _buildBalanceHero(dt, theme),
                  const SizedBox(height: 32),
                  _buildPaymentBreakdown(dt, theme),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 16),
                    child: Text('TRANSACTION HISTORY', 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2.5)
                    ),
                  ),
                  ..._paymentHistory.map((p) => _buildHistoryCard(dt, theme, p)),
                  const SizedBox(height: 140),
                ],
              ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: RolePlasma(
        color: KagemaColors.teacherGreen,
        child: FloatingActionButton.extended(
          onPressed: _showPaymentModal,
          backgroundColor: KagemaColors.teacherGreen,
          icon: const Icon(Icons.account_balance_wallet_rounded),
          label: const Text('INITIATE STK PUSH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildBalanceHero(DT dt, GeminiThemeExtension? theme) {
    final color = _balance > 0 ? dt.error : dt.success;
    return theme?.buildGlowContainer(
      accentColor: color,
      borderRadius: 40,
      padding: const EdgeInsets.all(32),
      useAIBorder: _balance > 0,
      child: Column(
        children: [
          Text('OUTSTANDING BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 2)),
          const SizedBox(height: 12),
          Text('Ksh ${NumberFormat('#,###').format(_balance)}', 
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(_balance <= 0 ? 'ACCOUNT CLEARED' : 'PAYMENT REQUIRED', 
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)
            ),
          ),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildPaymentBreakdown(DT dt, GeminiThemeExtension? theme) {
    return theme?.buildGlowContainer(
      accentColor: dt.info,
      borderRadius: 30,
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _breakdownItem(dt, 'Invoiced', _totalFee, dt.textPrimary),
          _vDivider(dt),
          _breakdownItem(dt, 'Paid', _paidAmount, dt.success),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _breakdownItem(DT dt, String label, double amount, Color color) {
    return Column(
      children: [
        Text('Ksh ${NumberFormat('#,###').format(amount)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1)),
      ],
    );
  }

  Widget _vDivider(DT dt) => Container(width: 1, height: 30, color: dt.divider);

  Widget _buildHistoryCard(DT dt, GeminiThemeExtension? theme, Map<String, dynamic> p) {
    final isWaiver = p['payment_method'] == 'Waiver';
    final color = isWaiver ? KagemaColors.secretaryViolet : KagemaColors.teacherGreen;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: theme?.buildGlowContainer(
        accentColor: color,
        borderRadius: 24,
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
            child: Icon(isWaiver ? Icons.auto_awesome_rounded : Icons.receipt_long_rounded, color: color, size: 20),
          ),
          title: Text('Ref: ${p['receipt_number']}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)),
          subtitle: Text('${p['payment_date'].toString().split('T')[0]} â€¢ ${p['payment_method']}', 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dt.textSecondary)
          ),
          trailing: Text('Ksh ${p['amount_paid']}', 
            style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15)
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }
}
