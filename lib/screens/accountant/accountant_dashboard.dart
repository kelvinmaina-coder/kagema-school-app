import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';
import 'fee_management.dart';
import 'income_management.dart';
import 'expense_management.dart';
import 'financial_reports.dart';
import 'fee_structure_screen.dart';
import 'inventory_management.dart';
import '../admin/hr_management_screen.dart';
import '../settings/settings_screen.dart';

class AccountantDashboard extends StatefulWidget {
  const AccountantDashboard({super.key});

  @override
  State<AccountantDashboard> createState() => _AccountantDashboardState();
}

class _AccountantDashboardState extends State<AccountantDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic> _stats = {'total_income': 0.0, 'total_expenses': 0.0};
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final summary = await SupabaseService.instance.getFinancialSummary();
      final payments = await SupabaseService.instance.client
          .from('fees')
          .select('*, students(name)')
          .order('payment_date', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _stats = summary;
          _recentTransactions = List<Map<String, dynamic>>.from(payments);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Accountant Sync Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Financial data sync failed. Swipe down to retry.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.red),
        );
      }
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
        child: _currentIndex == 0 ? _buildOverviewTab(theme, gemini) : _buildOperationsTab(theme),
      ),
      bottomNavigationBar: _buildModernNavBar(theme),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return RefreshIndicator(
      onRefresh: _loadFinancialData,
      child: CustomScrollView(
        slivers: [
          _buildHeroAppBar(theme, gemini, 'TREASURY INTEL'),
          if (_errorMessage != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.red, size: 20), onPressed: _loadFinancialData),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildBalanceCard(theme),
                  const SizedBox(height: 30),
                  _buildSectionLabel('QUICK ACCESS'),
                  const SizedBox(height: 12),
                  _buildQuickGrid(theme),
                  const SizedBox(height: 32),
                  _buildSectionLabel('RECENT CLOUD SYNC'),
                  const SizedBox(height: 16),
                  _buildTransactionsList(theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      children: [
        _buildSectionLabel('REVENUE MANAGEMENT'),
        _operationTile(theme, 'Fee Collection', 'Pupil payments & balances', Icons.payments_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeManagementScreen()))),
        _operationTile(theme, 'External Income', 'Donations & other sources', Icons.add_business_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeManagementScreen()))),
        _operationTile(theme, 'Fee Structures', 'Configure termly rates', Icons.account_tree_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeStructureScreen()))),
        const SizedBox(height: 24),
        _buildSectionLabel('EXPENDITURE & PAYROLL'),
        _operationTile(theme, 'Expense Tracker', 'Log operational costs', Icons.shopping_cart_checkout_rounded, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseManagementScreen()))),
        _operationTile(theme, 'Staff Payroll', 'Salaries & leave treasury', Icons.badge_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRManagementScreen()))),
        const SizedBox(height: 24),
        _buildSectionLabel('ASSETS & ANALYTICS'),
        _operationTile(theme, 'Asset Register', 'School property & inventory', Icons.inventory_2_rounded, Colors.brown, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryManagement()))),
        _operationTile(theme, 'Financial Reports', 'Balance sheets & statements', Icons.assessment_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialReportsScreen()))),
        _operationTile(theme, 'Audit Trail', 'Transaction history logs', Icons.history_edu_rounded, Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeManagementScreen(mode: 'statements')))),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _operationTile(ThemeData theme, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
      ),
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini, String title) {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: Colors.white)),
        background: Container(decoration: BoxDecoration(gradient: gemini?.primaryGradient, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)))),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme) {
    double income = (_stats['total_income'] as num? ?? 0.0).toDouble();
    double expenses = (_stats['total_expenses'] as num? ?? 0.0).toDouble();
    double balance = income - expenses;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Text('CURRENT TREASURY BALANCE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text('Ksh ${NumberFormat('#,###').format(balance)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: theme.primaryColor)),
          const SizedBox(height: 24),
          Row(
            children: [
              _flowItem('Revenue', income, Colors.green, Icons.arrow_upward_rounded),
              const SizedBox(width: 12),
              _flowItem('Expenses', expenses, Colors.red, Icons.arrow_downward_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flowItem(String label, double val, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: color, size: 12), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))]),
            const SizedBox(height: 4),
            Text('Ksh ${NumberFormat('#,###').format(val)}', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickGrid(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _quickCard(theme, 'FEES', Icons.add_card_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeManagementScreen()))),
        _quickCard(theme, 'LOG EXPENSE', Icons.trending_down_rounded, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseManagementScreen()))),
      ],
    );
  }

  Widget _quickCard(ThemeData theme, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 24), const SizedBox(height: 6), Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 10, letterSpacing: 1))]),
      ),
    );
  }

  Widget _buildTransactionsList(ThemeData theme) {
    if (_isLoading && _recentTransactions.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_recentTransactions.isEmpty) return const Center(child: Text('No cloud transactions found.', style: TextStyle(color: Colors.grey, fontSize: 12)));
    return Column(
      children: _recentTransactions.map((tx) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: const Icon(Icons.payments_rounded, color: Colors.green, size: 16)),
          title: Text(tx['students']?['name'] ?? 'Ref: ${tx['receipt_number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(DateFormat('MMM d, yyyy').format(DateTime.parse(tx['payment_date'])), style: const TextStyle(fontSize: 10)),
          trailing: Text('+${tx['amount_paid']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 14)),
        ),
      )).toList(),
    );
  }

  Widget _buildModernNavBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 70,
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, Icons.account_balance_rounded, 'Treasury'),
          _navItem(1, Icons.grid_view_rounded, 'Operations'),
          _navItem(2, Icons.settings_rounded, 'Settings'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Accountant')));
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? Theme.of(context).primaryColor : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey)),
    );
  }
}
