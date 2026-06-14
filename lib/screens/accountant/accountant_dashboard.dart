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
  Map<String, dynamic> _stats = {'total_income': 0.0, 'total_expenses': 0.0, 'total_waivers': 0.0};
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
          .limit(10);

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
          _errorMessage = "Financial sync paused. Swipe down to refresh.";
        });
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
        child: _currentIndex == 0 ? _buildOverviewTab(theme, gemini) : _buildOperationsTab(theme, gemini),
      ) ?? (_currentIndex == 0 ? _buildOverviewTab(theme, null) : _buildOperationsTab(theme, null)),
      bottomNavigationBar: _buildModernNavBar(theme, gemini),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return RefreshIndicator(
      onRefresh: _loadFinancialData,
      color: Colors.deepOrange,
      child: CustomScrollView(
        slivers: [
          _buildHeroAppBar(theme, gemini, 'TREASURY HUB'),
          if (_errorMessage != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red.withOpacity(0.1))),
                child: Row(
                  children: [
                    const Icon(Icons.sync_problem_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.red, size: 18), onPressed: _loadFinancialData),
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
                  const SizedBox(height: 24),
                  _buildBalanceCard(theme, gemini),
                  const SizedBox(height: 32),
                  _buildSectionLabel('CORE OPERATIONS'),
                  const SizedBox(height: 12),
                  _buildQuickGrid(theme, gemini),
                  const SizedBox(height: 32),
                  _buildSectionLabel('LIVE TRANSACTION STREAM'),
                  const SizedBox(height: 16),
                  _buildTransactionsList(theme, gemini),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 120),
      children: [
        _buildSectionLabel('INCOME & REVENUE'),
        _operationTile(theme, 'Fee Management', 'Collection, STK Push & Waivers', Icons.payments_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeManagementScreen()))),
        _operationTile(theme, 'Other Income', 'Grants, Donations & Canteen', Icons.add_business_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeManagementScreen()))),
        _operationTile(theme, 'Billing Structures', 'Manage grades & termly fees', Icons.account_tree_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeStructureScreen()))),
        const SizedBox(height: 32),
        _buildSectionLabel('OUTFLOW & PAYROLL'),
        _operationTile(theme, 'Expense Ledger', 'Log school operational costs', Icons.shopping_cart_checkout_rounded, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseManagementScreen()))),
        _operationTile(theme, 'Salary Treasury', 'Staff payments & deductions', Icons.badge_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRManagementScreen()))),
        const SizedBox(height: 32),
        _buildSectionLabel('ASSETS & AUDITING'),
        _operationTile(theme, 'Inventory Control', 'Manage school assets & stock', Icons.inventory_2_rounded, Colors.brown, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryManagement()))),
        _operationTile(theme, 'Audit Reports', 'Revenue, Waivers & Tax analytics', Icons.assessment_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialReportsScreen()))),
      ],
    );
  }

  Widget _operationTile(ThemeData theme, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini, String title) {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.deepOrange.shade900, Colors.deepOrange.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30, top: -20,
                child: Icon(Icons.account_balance_rounded, size: 200, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme, GeminiThemeExtension? gemini) {
    double income = (_stats['total_income'] as num? ?? 0.0).toDouble();
    double expenses = (_stats['total_expenses'] as num? ?? 0.0).toDouble();
    double waivers = (_stats['total_waivers'] as num? ?? 0.0).toDouble();
    double netBalance = income - expenses;
    
    final content = Column(
      children: [
        const Text('NET OPERATIONAL CAPITAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
        const SizedBox(height: 12),
        Text('Ksh ${NumberFormat('#,###.##').format(netBalance)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: theme.primaryColor)),
        const SizedBox(height: 24),
        Row(
          children: [
            _flowItem('Cash In', income, Colors.green, Icons.south_east_rounded),
            const SizedBox(width: 8),
            _flowItem('Cash Out', expenses, Colors.red, Icons.north_east_rounded),
            const SizedBox(width: 8),
            _flowItem('Waivers', waivers, Colors.purple, Icons.stars_rounded),
          ],
        ),
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 30,
      borderThickness: 2.5,
      backgroundColor: theme.cardColor.withOpacity(0.85),
      padding: const EdgeInsets.all(24),
      child: content,
    ) ?? Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.95), 
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: content,
    );
  }

  Widget _flowItem(String label, double val, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05), 
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(color: color.withOpacity(0.1))
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey)),
            const SizedBox(height: 4),
            FittedBox(child: Text('Ksh ${NumberFormat('#,###').format(val)}', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 11))),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickGrid(ThemeData theme, GeminiThemeExtension? gemini) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _quickCard(theme, gemini, 'FEE COLLECTION', Icons.add_card_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeManagementScreen()))),
        _quickCard(theme, gemini, 'LOG EXPENSE', Icons.trending_down_rounded, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseManagementScreen()))),
      ],
    );
  }

  Widget _quickCard(ThemeData theme, GeminiThemeExtension? gemini, String title, IconData icon, Color color, VoidCallback onTap) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Icon(icon, color: color, size: 32), 
        const SizedBox(height: 10), 
        Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 10, letterSpacing: 1.5))
      ]
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: gemini?.buildGlowContainer(
        borderRadius: 24,
        borderThickness: 1.5,
        backgroundColor: color.withOpacity(0.08),
        padding: EdgeInsets.zero,
        child: content,
      ) ?? Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)]
        ),
        child: content,
      ),
    );
  }

  Widget _buildTransactionsList(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_isLoading && _recentTransactions.isEmpty) return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
    if (_recentTransactions.isEmpty) return const Center(child: Text('No cloud transactions discovered.', style: TextStyle(color: Colors.grey, fontSize: 12)));
    return Column(
      children: _recentTransactions.map((tx) {
        final isWaiver = tx['payment_method'] == 'Waiver';
        final color = isWaiver ? Colors.purple : Colors.green;
        final content = ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(isWaiver ? Icons.stars_rounded : Icons.payments_rounded, color: color, size: 20),
          ),
          title: Text(tx['students']?['name'] ?? 'Ref: ${tx['receipt_number']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          subtitle: Text(tx['payment_date']?.toString().split(' ')[0] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${isWaiver ? '' : '+'}${tx['amount_paid']}', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
              Text(isWaiver ? 'GRANT' : 'CASH', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey.shade400)),
            ],
          ),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: gemini?.buildGlowContainer(
            borderRadius: 20,
            borderThickness: 1,
            backgroundColor: theme.cardColor.withOpacity(0.8),
            padding: EdgeInsets.zero,
            child: content,
          ) ?? Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: theme.dividerColor.withOpacity(0.05))),
            child: content,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernNavBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 70,
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.95), 
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, spreadRadius: -10)],
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected ? BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? Theme.of(context).primaryColor : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12.0),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.blueGrey)),
    );
  }
}
