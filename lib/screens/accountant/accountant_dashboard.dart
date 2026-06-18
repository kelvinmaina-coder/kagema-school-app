import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../../services/supabase_service.dart';
import '../../services/authentication_service.dart';
import 'fee_management.dart';
import 'income_management.dart';
import 'expense_management.dart';
import 'financial_reports.dart';
import 'fee_structure_screen.dart';
import 'inventory_management.dart';
import '../admin/hr_management_screen.dart';
import '../settings/settings_screen.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

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

  final Color primaryAccent = const Color(0xFFFF5722); 
  final Color slateDark = const Color(0xFF1A1C2E);

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });
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
      if (mounted) setState(() { _isLoading = false; _errorMessage = "FINANCIAL SYNC PAUSED. SWIPE TO REFRESH."; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // RESPONSIVE MAX WIDTH
    double maxWidth = screenWidth > 1200 ? 1100 : (screenWidth > 800 ? 850 : screenWidth);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0E12) : const Color(0xFFF4F7FA),
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        maxWidth: maxWidth,
        child: Stack(
          children: [
            _currentIndex == 0 ? _buildOverviewTab(theme, isDark, screenWidth) : _buildOperationsTab(theme, isDark, screenWidth),
            _buildBottomNav(isDark, screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, bool isDark, double screenWidth) {
    return RefreshIndicator(
      onRefresh: _loadFinancialData,
      color: primaryAccent,
      edgeOffset: 120,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildElegantHeader('TREASURY HUB', Icons.account_balance_rounded),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 32 : 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) _buildErrorBanner(),
                  _buildMainMetricCard(isDark, screenWidth),
                  const SizedBox(height: 40),
                  _buildSectionHeader('CORE OPERATIONS'),
                  const SizedBox(height: 20),
                  _buildQuickActionGrid(isDark),
                  const SizedBox(height: 40),
                  _buildSectionHeader('LIVE TRANSACTION STREAM'),
                  const SizedBox(height: 20),
                  _buildTransactionList(isDark, screenWidth),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantHeader(String title, IconData icon) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryAccent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(title, 
          style: const TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 18, 
            letterSpacing: 4, 
            color: Colors.white,
          )
        ),
        background: Stack(
          children: [
            Container(color: primaryAccent),
            Positioned(
              right: -20, top: -10,
              child: Icon(icon, size: 180, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMetricCard(bool isDark, double screenWidth) {
    double income = (_stats['total_income'] as num? ?? 0.0).toDouble();
    double expenses = (_stats['total_expenses'] as num? ?? 0.0).toDouble();
    double netBalance = income - expenses;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Text('NET OPERATIONAL CAPITAL', 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 2)
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('KSH', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryAccent)),
              const SizedBox(width: 12),
              Text(NumberFormat('#,###.##').format(netBalance), 
                style: TextStyle(fontSize: screenWidth > 600 ? 48 : 36, fontWeight: FontWeight.w900, color: isDark ? Colors.white : slateDark, letterSpacing: -1.5)
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _metricSubItem('CASH IN', income, const Color(0xFF10B981), Icons.arrow_downward_rounded, isDark),
              const SizedBox(width: 16),
              _metricSubItem('CASH OUT', expenses, const Color(0xFFEF4444), Icons.arrow_upward_rounded, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricSubItem(String label, double value, Color color, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 8),
            Text('KSH ${NumberFormat('#,###').format(value)}', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : slateDark)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid(bool isDark) {
    return Row(
      children: [
        _actionCard('FEE COLLECTION', Icons.payments_rounded, const Color(0xFF10B981), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeManagementScreen()))),
        const SizedBox(width: 16),
        _actionCard('LOG EXPENSE', Icons.shopping_bag_rounded, const Color(0xFFEF4444), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseManagementScreen()))),
      ],
    );
  }

  Widget _actionCard(String title, IconData icon, Color accent, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: accent, size: 32),
              ),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : slateDark, fontSize: 11, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(bool isDark, double screenWidth) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_recentTransactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1C2E).withOpacity(0.5) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: Text('NO RECENT TRANSACTIONS', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey, fontSize: 10, letterSpacing: 1.5))),
      );
    }

    if (screenWidth > 900) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 12,
          mainAxisExtent: 90,
        ),
        itemCount: _recentTransactions.length,
        itemBuilder: (context, index) => _buildTransactionTile(_recentTransactions[index], isDark),
      );
    }

    return Column(
      children: _recentTransactions.map((tx) => _buildTransactionTile(tx, isDark)).toList(),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx, bool isDark) {
    final bool isWaiver = tx['payment_method'] == 'Waiver';
    final color = isWaiver ? const Color(0xFF8B5CF6) : const Color(0xFF10B981);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(isWaiver ? Icons.auto_awesome_rounded : Icons.receipt_long_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tx['students']?['name']?.toString().toUpperCase() ?? 'REF: ${tx['receipt_number']}', 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : slateDark)
                ),
                const SizedBox(height: 2),
                Text(tx['payment_date']?.toString().split(' ')[0] ?? '', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black38)
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('KSH ${NumberFormat('#,###').format(tx['amount_paid'])}', 
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)
              ),
              Text(isWaiver ? 'WAIVER' : 'COLLECTED', 
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 1)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsTab(ThemeData theme, bool isDark, double screenWidth) {
    int crossAxisCount = screenWidth > 900 ? 3 : (screenWidth > 600 ? 2 : 1);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildElegantHeader('OPERATIONS', Icons.grid_view_rounded),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 32 : 20, vertical: 24),
          sliver: crossAxisCount == 1 
            ? SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader('INCOME & REVENUE'),
                  const SizedBox(height: 12),
                  _opTile('Fee Management', 'Collection & STK Push', Icons.payments_rounded, const Color(0xFF10B981), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeManagementScreen()))),
                  _opTile('Other Income', 'Grants & Canteen', Icons.add_business_rounded, const Color(0xFF3B82F6), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeManagementScreen()))),
                  _opTile('Billing Structures', 'Manage termly fees', Icons.account_tree_rounded, const Color(0xFF8B5CF6), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeStructureScreen()))),
                  const SizedBox(height: 24),
                  _buildSectionHeader('OUTFLOW & PAYROLL'),
                  const SizedBox(height: 12),
                  _opTile('Expense Ledger', 'Operational costs', Icons.shopping_cart_checkout_rounded, const Color(0xFFEF4444), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseManagementScreen()))),
                  _opTile('Salary Treasury', 'Staff payments', Icons.badge_rounded, const Color(0xFF009688), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRManagementScreen()))),
                  const SizedBox(height: 24),
                  _buildSectionHeader('ASSETS & AUDITING'),
                  const SizedBox(height: 12),
                  _opTile('Inventory Control', 'School assets', Icons.inventory_2_rounded, const Color(0xFF795548), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryManagement()))),
                  _opTile('Audit Reports', 'Revenue analytics', Icons.assessment_rounded, const Color(0xFFF59E0B), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialReportsScreen()))),
                  const SizedBox(height: 140),
                ]),
              )
            : SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 90,
                ),
                delegate: SliverChildListDelegate([
                   _opTile('Fee Portal', 'Collections', Icons.payments_rounded, const Color(0xFF10B981), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeManagementScreen()))),
                   _opTile('Income', 'Grants', Icons.add_business_rounded, const Color(0xFF3B82F6), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeManagementScreen()))),
                   _opTile('Fee Setup', 'Structures', Icons.account_tree_rounded, const Color(0xFF8B5CF6), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeStructureScreen()))),
                   _opTile('Expenses', 'Cost Control', Icons.shopping_cart_checkout_rounded, const Color(0xFFEF4444), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseManagementScreen()))),
                   _opTile('Payroll', 'Staff pay', Icons.badge_rounded, const Color(0xFF009688), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRManagementScreen()))),
                   _opTile('Inventory', 'Assets', Icons.inventory_2_rounded, const Color(0xFF795548), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryManagement()))),
                   _opTile('Auditing', 'Analytics', Icons.assessment_rounded, const Color(0xFFF59E0B), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialReportsScreen()))),
                ]),
              ),
        ),
      ],
    );
  }

  Widget _opTile(String title, String sub, IconData icon, Color color, bool isDark, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : slateDark)),
                      const SizedBox(height: 2),
                      Text(sub.toUpperCase(), style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white12 : Colors.black12, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark, double screenWidth) {
    double navWidth = screenWidth > 800 ? 500 : screenWidth - 40;

    return Positioned(
      bottom: 25, left: 0, right: 0,
      child: Center(
        child: Container(
          width: navWidth,
          height: 70,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1C2E).withOpacity(0.95) : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(0, Icons.account_balance_wallet_rounded, 'TREASURY'),
              _navItem(1, Icons.grid_view_rounded, 'OPERATIONS'),
              _navItem(2, Icons.settings_rounded, 'SETUP'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
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
          Icon(icon, color: isSelected ? primaryAccent : Colors.grey.withOpacity(0.5), size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? primaryAccent : Colors.grey.withOpacity(0.5), letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: primaryAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: Color(0xFF475569))),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFCDD2))),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F)),
          const SizedBox(width: 12),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 11, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}
