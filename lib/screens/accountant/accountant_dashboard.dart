import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';
import 'fee_management.dart';
import 'income_management.dart';
import 'expense_management.dart';
import 'financial_reports.dart';
import 'fee_structure_screen.dart';

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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final statsResponse = await SupabaseService.instance.client
          .from('financial_summary')
          .select()
          .maybeSingle();

      final payments = await SupabaseService.instance.client
          .from('fees')
          .select('*, students(name)')
          .order('payment_date', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          if (statsResponse != null) _stats = statsResponse;
          _recentTransactions = List<Map<String, dynamic>>.from(payments);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFinancialData,
              child: CustomScrollView(
                slivers: [
                  _buildHeroAppBar(theme, gemini),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildBalanceCard(theme),
                          const SizedBox(height: 24),
                          _buildActionGrid(context, theme),
                          const SizedBox(height: 32),
                          _buildSectionLabel('RECENT CLOUD TRANSACTIONS'),
                          const SizedBox(height: 16),
                          _buildTransactionsList(theme),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 140.0,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Treasury Intelligence', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: gemini?.primaryGradient ?? LinearGradient(colors: [theme.primaryColor, Colors.black87]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
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
      ),
      child: Column(
        children: [
          const Text('CURRENT NET LIQUIDITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(
            'Ksh ${NumberFormat('#,###').format(balance)}',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: theme.primaryColor),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniFlowStat('Revenue', _stats['total_income'] ?? 0.0, Colors.green),
              _miniFlowStat('Expenses', _stats['total_expenses'] ?? 0.0, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniFlowStat(String label, double val, Color color) {
    return Column(
      children: [
        Text('Ksh ${NumberFormat('#,###').format(val)}', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context, ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _toolBtn('Collect Fees', Icons.add_card_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeManagementScreen()))),
        _toolBtn('Add Income', Icons.trending_up_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeManagementScreen()))),
        _toolBtn('Log Expense', Icons.trending_down_rounded, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseManagementScreen()))),
        _toolBtn('Reports', Icons.assessment_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialReportsScreen()))),
        _toolBtn('Fee Setup', Icons.settings_suggest_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeStructureScreen()))),
        _toolBtn('Statements', Icons.history_edu_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeManagementScreen(mode: 'statements')))),
      ],
    );
  }

  Widget _toolBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(ThemeData theme) {
    if (_recentTransactions.isEmpty) return const Center(child: Text('No transactions synced yet.', style: TextStyle(color: Colors.grey)));
    return Column(
      children: _recentTransactions.map((tx) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.payments, color: Colors.white, size: 16)),
          title: Text(tx['students']?['name'] ?? 'Unknown Pupil', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(DateFormat('MMM d').format(DateTime.parse(tx['payment_date']))),
          trailing: Text('+${tx['amount_paid']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900)),
        ),
      )).toList(),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
    );
  }
}
