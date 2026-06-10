import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class AccountantDashboard extends StatefulWidget {
  const AccountantDashboard({super.key});

  @override
  State<AccountantDashboard> createState() => _AccountantDashboardState();
}

class _AccountantDashboardState extends State<AccountantDashboard> {
  Map<String, dynamic> _stats = {'total_income': 0.0, 'total_expenses': 0.0};
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch from the SQL view we created
      final statsResponse = await SupabaseService.instance.client
          .from('financial_summary')
          .select()
          .maybeSingle();

      // 2. Fetch recent fee payments
      final payments = await SupabaseService.instance.client
          .from('fees')
          .select('*, students(name)')
          .order('payment_date', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          if (statsResponse != null) {
            _stats = statsResponse;
          }
          _recentTransactions = List<Map<String, dynamic>>.from(payments);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Financial Load Error: $e");
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
        title: const Text('Treasury & Finance', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: RefreshIndicator(
          onRefresh: _loadFinancialData,
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20,
                  left: 20, right: 20, bottom: 40
                ),
                child: Column(
                  children: [
                    _buildBalanceCard(theme),
                    const SizedBox(height: 30),
                    _buildQuickStats(theme),
                    const SizedBox(height: 30),
                    _buildRecentTransactions(theme),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme) {
    double balance = (_stats['total_income'] ?? 0.0) - (_stats['total_expenses'] ?? 0.0);
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Text('CURRENT NET BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
          const SizedBox(height: 10),
          Text(
            'Ksh ${NumberFormat('#,###').format(balance)}',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: theme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    return Row(
      children: [
        _statBox('Revenue', _stats['total_income'] ?? 0.0, Colors.green, Icons.arrow_downward),
        const SizedBox(width: 16),
        _statBox('Expenses', _stats['total_expenses'] ?? 0.0, Colors.red, Icons.arrow_upward),
      ],
    );
  }

  Widget _statBox(String label, double val, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text('Ksh ${NumberFormat('#,###').format(val)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RECENT FEE PAYMENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        ..._recentTransactions.map((tx) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person, size: 18)),
            title: Text(tx['students']?['name'] ?? 'Unknown Pupil', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('MMM d, yyyy').format(DateTime.parse(tx['payment_date']))),
            trailing: Text('+${tx['amount_paid']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        )),
      ],
    );
  }
}
