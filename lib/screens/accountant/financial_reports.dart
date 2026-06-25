import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  String _selectedReportType = 'Daily';
  List<Map<String, dynamic>> _reportData = [];
  double _cashCollection = 0;
  double _waiverAmount = 0;
  bool _isLoading = true;
  final String _roleId = 'accountant';

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    String dateFilter = '';
    final now = DateTime.now();

    if (_selectedReportType == 'Daily') {
      dateFilter = DateFormat('yyyy-MM-dd').format(now);
    } else if (_selectedReportType == 'Weekly') {
      dateFilter = DateFormat('yyyy-MM').format(now); 
    } else if (_selectedReportType == 'Monthly') {
      dateFilter = DateFormat('yyyy-MM').format(now);
    } else if (_selectedReportType == 'Annual') {
      dateFilter = DateFormat('yyyy').format(now);
    }

    try {
      final results = await SupabaseService.instance.getFeeReports(dateFilter);
      double cash = 0;
      double waivers = 0;
      
      for (var r in results) {
        double amt = (r['amount_paid'] as num? ?? 0.0).toDouble();
        if (r['payment_method'] == 'Waiver') {
          waivers += amt;
        } else {
          cash += amt;
        }
      }

      if (mounted) {
        setState(() {
          _reportData = results;
          _cashCollection = cash;
          _waiverAmount = waivers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Report Generation Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('FINANCIAL AUDITING', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
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
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.analytics_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: SafeArea(
            child: Column(
              children: [
                _buildTypeSelector(dt, roleColor),
                _buildAuditSummary(dt, theme, roleColor),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: roleColor))
                      : _reportData.isEmpty
                          ? _buildEmptyState(dt)
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: _reportData.length,
                              itemBuilder: (context, index) {
                                final item = _reportData[index];
                                final bool isWaiver = item['payment_method'] == 'Waiver';
                                return _buildTransactionCard(dt, theme, item, isWaiver);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
      bottomNavigationBar: _buildBottomStats(dt),
    );
  }

  Widget _buildTypeSelector(DT dt, Color roleColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: dt.cardBg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dt.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['Daily', 'Weekly', 'Monthly', 'Annual'].map((type) {
          bool isSelected = _selectedReportType == type;
          return ChoiceChip(
            label: Text(type, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
            selected: isSelected,
            selectedColor: roleColor,
            labelStyle: TextStyle(color: isSelected ? Colors.white : roleColor),
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            side: BorderSide(color: isSelected ? Colors.transparent : roleColor.withValues(alpha: 0.2)),
            onSelected: (val) {
              if (val) {
                setState(() => _selectedReportType = type);
                _generateReport();
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAuditSummary(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _summaryBox(dt, theme, 'Net Cash', _cashCollection, Icons.account_balance_wallet_rounded, KagemaColors.teacherGreen),
          const SizedBox(width: 12),
          _summaryBox(dt, theme, 'Fee Waivers', _waiverAmount, Icons.stars_rounded, KagemaColors.secretaryViolet),
        ],
      ),
    );
  }

  Widget _summaryBox(DT dt, GeminiThemeExtension? theme, String label, double amount, IconData icon, Color color) {
    return Expanded(
      child: theme?.buildGlowContainer(
        accentColor: color,
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              'Ksh ${NumberFormat("#,##0").format(amount)}',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color, letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(label.toUpperCase(), 
              style: TextStyle(fontSize: 8, color: dt.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1)
            ),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildTransactionCard(DT dt, GeminiThemeExtension? theme, Map<String, dynamic> item, bool isWaiver) {
    final color = isWaiver ? KagemaColors.secretaryViolet : KagemaColors.staffSky;
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
            child: Icon(isWaiver ? Icons.stars_rounded : Icons.receipt_long_rounded, color: color, size: 20),
          ),
          title: Text(
            item['students']?['name'] ?? 'Ref: ${item['receipt_number']}', 
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary)
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${item['payment_date']?.toString().split(' ')[0]} â€¢ ${item['category'] ?? 'General'}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dt.textSecondary),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Ksh ${item['amount_paid']}',
                style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14, letterSpacing: 0.5),
              ),
              Text(
                isWaiver ? 'FEE WAIVER' : (item['payment_method']?.toString().toUpperCase() ?? 'CASH'),
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildBottomStats(DT dt) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: dt.cardBg.withValues(alpha: 0.98),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, -10))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        border: Border.all(color: dt.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GROSS VALUE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2, color: dt.textMuted)),
              Text(
                'Ksh ${NumberFormat("#,##0").format(_cashCollection + _waiverAmount)}', 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5, color: dt.textPrimary)
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: dt.divider),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL REVENUE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: dt.success)),
              Text(
                'Ksh ${NumberFormat("#,##0").format(_cashCollection)}', 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: dt.success, letterSpacing: -0.5)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO TRANSACTION RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
