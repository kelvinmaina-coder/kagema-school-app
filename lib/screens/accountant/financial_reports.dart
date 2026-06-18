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
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Financial Auditing', 
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
              colors: [Colors.blue.shade900, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.analytics_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildTypeSelector(theme, gemini),
              _buildAuditSummary(theme, gemini),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                    : _reportData.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: _reportData.length,
                            itemBuilder: (context, index) {
                              final item = _reportData[index];
                              final bool isWaiver = item['payment_method'] == 'Waiver';
                              return _buildTransactionCard(theme, gemini, item, isWaiver);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomStats(theme, gemini),
    );
  }

  Widget _buildTypeSelector(ThemeData theme, GeminiThemeExtension? gemini) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['Daily', 'Weekly', 'Monthly', 'Annual'].map((type) {
          bool isSelected = _selectedReportType == type;
          return ChoiceChip(
            label: Text(type, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
            selected: isSelected,
            selectedColor: Colors.blue.shade800,
            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.blue.shade800),
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            side: BorderSide(color: isSelected ? Colors.blue.shade800 : Colors.blue.withOpacity(0.2)),
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

  Widget _buildAuditSummary(ThemeData theme, GeminiThemeExtension? gemini) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _summaryBox(theme, gemini, 'Net Cash', _cashCollection, Icons.account_balance_wallet_rounded, Colors.green),
          const SizedBox(width: 12),
          _summaryBox(theme, gemini, 'Fee Waivers', _waiverAmount, Icons.stars_rounded, Colors.purple),
        ],
      ),
    );
  }

  Widget _summaryBox(ThemeData theme, GeminiThemeExtension? gemini, String label, double amount, IconData icon, Color color) {
    final content = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          'Ksh ${NumberFormat("#,##0").format(amount)}',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), 
          style: TextStyle(fontSize: 8, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w900, letterSpacing: 1)
        ),
      ],
    );

    return Expanded(
      child: gemini?.buildGlowContainer(
        borderRadius: 24,
        borderThickness: 1.5,
        backgroundColor: theme.cardColor.withOpacity(0.85),
        padding: const EdgeInsets.all(16),
        child: content,
      ) ?? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: content,
      ),
    );
  }

  Widget _buildTransactionCard(ThemeData theme, GeminiThemeExtension? gemini, Map<String, dynamic> item, bool isWaiver) {
    final color = isWaiver ? Colors.purple : Colors.blue;
    final content = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(isWaiver ? Icons.stars_rounded : Icons.receipt_long_rounded, color: color, size: 20),
      ),
      title: Text(
        item['students']?['name'] ?? 'Ref: ${item['receipt_number']}', 
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${item['payment_date']?.toString().split(' ')[0]} • ${item['category'] ?? 'General'}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Ksh ${item['amount_paid']}',
            style: TextStyle(fontWeight: FontWeight.w900, color: isWaiver ? Colors.purple : Colors.blue.shade800, fontSize: 14, letterSpacing: 0.5),
          ),
          Text(
            isWaiver ? 'FEE WAIVER' : (item['payment_method']?.toString().toUpperCase() ?? 'CASH'),
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1),
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
  }

  Widget _buildBottomStats(ThemeData theme, GeminiThemeExtension? gemini) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.98),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, -10))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GROSS VALUE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2, color: Colors.blueGrey.shade400)),
              Text(
                'Ksh ${NumberFormat("#,##0").format(_cashCollection + _waiverAmount)}', 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL REVENUE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: Colors.green)),
              Text(
                'Ksh ${NumberFormat("#,##0").format(_cashCollection)}', 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.green, letterSpacing: -0.5)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('NO TRANSACTION RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
