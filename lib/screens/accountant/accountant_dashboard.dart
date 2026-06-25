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

  final String _roleId = 'accountant';

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
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);
    final screenWidth = context.sw;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    double maxWidth = screenWidth > 1200 ? 1100 : (screenWidth > 800 ? 850 : screenWidth);

    return Scaffold(
      backgroundColor: dt.pageBg,
      body: theme?.buildCreativeBackground(
        isDark: context.isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: RoleAuraLayer(
              roleColor: roleColor,
              isDark: context.isDark,
              child: Stack(
                children: [
                  _currentIndex == 0 ? _buildOverviewTab(dt, theme) : _buildOperationsTab(dt, theme),
                  _buildBottomNav(dt),
                ],
              ),
            ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildOverviewTab(DT dt, GeminiThemeExtension? theme) {
    final greeter = TimeGreeter.now;
    final isMobile = context.sw < 600;
    final isTablet = context.sw >= 600 && context.sw < 1200;

    return RefreshIndicator(
      onRefresh: _loadFinancialData,
      color: RoleColors.of(_roleId),
      edgeOffset: 120,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildElegantHeader(greeter.greet('Accountant'), Icons.account_balance_rounded, dt),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : (isTablet ? 24 : 32),
                  vertical: isMobile ? 16 : 24
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) _buildErrorBanner(dt),

                  Padding(
                    padding: EdgeInsets.only(bottom: isMobile ? 16 : 24, left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeter.tailline.toUpperCase(),
                          style: TextStyle(
                              fontSize: isMobile ? 8 : 9,
                              fontWeight: FontWeight.w900,
                              color: dt.textMuted,
                              letterSpacing: 2.5
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${greeter.greet('Accountant')} ðŸ‘‹',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: dt.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildMainMetricCard(dt, theme),
                  SizedBox(height: isMobile ? 24 : 40),
                  _buildSectionHeader('CORE OPERATIONS', dt),
                  SizedBox(height: isMobile ? 12 : 20),
                  _buildQuickActionGrid(dt, theme),
                  SizedBox(height: isMobile ? 24 : 40),
                  _buildSectionHeader('LIVE TRANSACTION STREAM', dt),
                  SizedBox(height: isMobile ? 12 : 20),
                  _buildTransactionList(dt, theme),
                  SizedBox(height: isMobile ? 80 : 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantHeader(String title, IconData icon, DT dt) {
    final roleColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return SliverAppBar(
      expandedHeight: isMobile ? 100 : 140,
      pinned: true,
      elevation: 0,
      backgroundColor: roleColor,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 14 : 16,
                  letterSpacing: 4,
                  color: Colors.white,
                )
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: isMobile ? 30 : 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            )
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: roleColor),
            Center(
              child: Opacity(
                opacity: 0.08,
                child: Icon(icon, size: isMobile ? 120 : 200, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMetricCard(DT dt, GeminiThemeExtension? theme) {
    double income = (_stats['total_income'] as num? ?? 0.0).toDouble();
    double expenses = (_stats['total_expenses'] as num? ?? 0.0).toDouble();
    double netBalance = income - expenses;
    final roleColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return theme?.buildGlowContainer(
      accentColor: roleColor,
      accentColor2: RoleColors.complement(_roleId),
      borderRadius: isMobile ? 24 : 35,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up_rounded, color: roleColor, size: isMobile ? 16 : 20),
              const SizedBox(width: 8),
              Text(
                  'NET OPERATIONAL CAPITAL',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w900,
                    color: dt.textMuted,
                    letterSpacing: 2,
                  )
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'KSH',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w900,
                    color: roleColor,
                  )
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  NumberFormat('#,###.##').format(netBalance),
                  style: TextStyle(
                    fontSize: isMobile ? 28 : (context.sw < 900 ? 38 : 48),
                    fontWeight: FontWeight.w900,
                    color: dt.textPrimary,
                    letterSpacing: -1.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 32),
          Row(
            children: [
              _metricSubItem('CASH IN', income, KagemaColors.teacherGreen, Icons.arrow_downward_rounded, dt, isMobile),
              SizedBox(width: isMobile ? 8 : 16),
              _metricSubItem('CASH OUT', expenses, KagemaColors.parentRed, Icons.arrow_upward_rounded, dt, isMobile),
            ],
          ),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _metricSubItem(String label, double value, Color color, IconData icon, DT dt, bool isMobile) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        decoration: BoxDecoration(
          color: dt.roleSoftBg(color),
          borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: isMobile ? 12 : 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 8 : 9,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 4 : 8),
            Text(
              'KSH ${NumberFormat('#,###').format(value)}',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w900,
                color: dt.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid(DT dt, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;
    final roleColor = RoleColors.of(_roleId);

    final actions = [
      {
        'title': 'FEE COLLECTION',
        'icon': Icons.payments_rounded,
        'color': KagemaColors.teacherGreen,
        'route': const FeeManagementScreen(),
      },
      {
        'title': 'LOG EXPENSE',
        'icon': Icons.shopping_bag_rounded,
        'color': KagemaColors.parentRed,
        'route': const ExpenseManagementScreen(),
      },
    ];

    if (!isMobile) {
      actions.addAll([
        {
          'title': 'INCOME',
          'icon': Icons.add_business_rounded,
          'color': KagemaColors.staffSky,
          'route': const IncomeManagementScreen(),
        },
        {
          'title': 'REPORTS',
          'icon': Icons.assessment_rounded,
          'color': KagemaColors.accountantAmber,
          'route': const FinancialReportsScreen(),
        },
      ]);
    }

    return isMobile
        ? Column(
      children: [
        Row(
          children: actions.take(2).map((action) {
            return _actionCard(
              action['title'] as String,
              action['icon'] as IconData,
              action['color'] as Color,
              dt,
              theme,
                  () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => action['route'] as Widget)
              ),
            );
          }).toList(),
        ),
      ],
    )
        : GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: context.sw > 900 ? 4 : 2,
      crossAxisSpacing: isMobile ? 12 : 16,
      mainAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: isMobile ? 1.2 : 1.1,
      children: actions.map((action) {
        return _actionCard(
          action['title'] as String,
          action['icon'] as IconData,
          action['color'] as Color,
          dt,
          theme,
              () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => action['route'] as Widget)
          ),
        );
      }).toList(),
    );
  }

  Widget _actionCard(String title, IconData icon, Color accent, DT dt, GeminiThemeExtension? theme, VoidCallback onTap) {
    final isMobile = context.sw < 600;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: isMobile ? 8 : 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
          child: theme?.buildGlowContainer(
            accentColor: accent,
            accentColor2: RoleColors.complement(_roleId),
            borderRadius: isMobile ? 16 : 24,
            padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 32),
            child: Column(
              children: [
                RolePlasma(
                  color: accent,
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: dt.roleSoftBg(accent),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: accent,
                      size: isMobile ? 24 : 32,
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: dt.textPrimary,
                    fontSize: isMobile ? 10 : 11,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width: isMobile ? 20 : 30,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(DT dt, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            color: RoleColors.of(_roleId),
          ),
        ),
      );
    }

    if (_recentTransactions.isEmpty) {
      return theme?.buildGlowContainer(
        accentColor: RoleColors.of(_roleId),
        borderRadius: isMobile ? 16 : 24,
        padding: EdgeInsets.all(isMobile ? 40 : 60),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: isMobile ? 40 : 60, color: dt.textMuted),
            const SizedBox(height: 16),
            Text(
              'NO RECENT TRANSACTIONS',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: dt.textMuted,
                fontSize: isMobile ? 9 : 10,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ) ?? const SizedBox.shrink();
    }

    return Column(
      children: _recentTransactions.map((tx) => _buildTransactionTile(tx, dt, theme)).toList(),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx, DT dt, GeminiThemeExtension? theme) {
    final bool isWaiver = tx['payment_method'] == 'Waiver';
    final color = isWaiver ? KagemaColors.secretaryViolet : KagemaColors.teacherGreen;
    final isMobile = context.sw < 600;

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: theme?.buildGlowContainer(
        accentColor: color,
        borderRadius: isMobile ? 16 : 20,
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: dt.roleSoftBg(color),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isWaiver ? Icons.auto_awesome_rounded : Icons.receipt_long_rounded,
                color: color,
                size: isMobile ? 18 : 20,
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tx['students']?['name']?.toString().toUpperCase() ?? 'REF: ${tx['receipt_number']}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: isMobile ? 13 : 14,
                      color: dt.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx['payment_date']?.toString().split(' ')[0] ?? '',
                    style: TextStyle(
                      fontSize: isMobile ? 9 : 10,
                      fontWeight: FontWeight.w700,
                      color: dt.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'KSH ${NumberFormat('#,###').format(tx['amount_paid'])}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
                Text(
                  isWaiver ? 'WAIVER' : 'COLLECTED',
                  style: TextStyle(
                    fontSize: isMobile ? 7 : 8,
                    fontWeight: FontWeight.w900,
                    color: dt.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsTab(DT dt, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildElegantHeader('OPERATIONS', Icons.grid_view_rounded, dt),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : (context.sw < 900 ? 24 : 32),
            vertical: isMobile ? 16 : 24,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader('INCOME & REVENUE', dt),
              SizedBox(height: isMobile ? 8 : 12),
              _opTile(
                'Fee Management',
                'Collection & STK Push',
                Icons.payments_rounded,
                KagemaColors.teacherGreen,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeeManagementScreen())
                ),
              ),
              _opTile(
                'Other Income',
                'Grants & Canteen',
                Icons.add_business_rounded,
                KagemaColors.staffSky,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IncomeManagementScreen())
                ),
              ),
              _opTile(
                'Billing Structures',
                'Manage termly fees',
                Icons.account_tree_rounded,
                KagemaColors.secretaryViolet,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeeStructureScreen())
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              _buildSectionHeader('OUTFLOW & PAYROLL', dt),
              SizedBox(height: isMobile ? 8 : 12),
              _opTile(
                'Expense Ledger',
                'Operational costs',
                Icons.shopping_cart_checkout_rounded,
                KagemaColors.parentRed,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpenseManagementScreen())
                ),
              ),
              _opTile(
                'Salary Treasury',
                'Staff payments',
                Icons.badge_rounded,
                KagemaColors.teacherGreen,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HRManagementScreen())
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              _buildSectionHeader('ASSETS & AUDITING', dt),
              SizedBox(height: isMobile ? 8 : 12),
              _opTile(
                'Inventory Control',
                'School assets',
                Icons.inventory_2_rounded,
                dt.textSecondary,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryManagement())
                ),
              ),
              _opTile(
                'Audit Reports',
                'Revenue analytics',
                Icons.assessment_rounded,
                KagemaColors.accountantAmber,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FinancialReportsScreen())
                ),
              ),
              const SizedBox(height: 140),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _opTile(
      String title,
      String sub,
      IconData icon,
      Color color,
      DT dt,
      GeminiThemeExtension? theme,
      VoidCallback onTap,
      ) {
    final isMobile = context.sw < 600;

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: theme?.buildGlowContainer(
        accentColor: color,
        accentColor2: RoleColors.complement(_roleId),
        borderRadius: isMobile ? 16 : 20,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: dt.roleSoftBg(color),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isMobile ? 18 : 20,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isMobile ? 13 : 14,
                          color: dt.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub.toUpperCase(),
                        style: TextStyle(
                          fontSize: isMobile ? 8 : 9,
                          color: dt.textMuted,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: dt.iconInactive,
                  size: isMobile ? 18 : 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(DT dt) {
    final isMobile = context.sw < 600;
    final roleColor = RoleColors.of(_roleId);

    double navWidth = context.fluid(context.sw - 40, 500);
    double navHeight = isMobile ? 60 : 70;

    return Positioned(
      bottom: isMobile ? 16 : 25,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: navWidth,
          height: navHeight,
          decoration: BoxDecoration(
            color: dt.cardBg.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: dt.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(0, Icons.account_balance_wallet_rounded, 'TREASURY', dt),
              _navItem(1, Icons.grid_view_rounded, 'OPERATIONS', dt),
              _navItem(2, Icons.settings_rounded, 'SETUP', dt),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, DT dt) {
    bool isSelected = _currentIndex == index;
    final activeColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return GestureDetector(
      onTap: () {
        if (index == 2) {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Accountant'))
          );
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 4 : 0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : dt.iconInactive,
              size: isMobile ? 22 : 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 8 : 9,
                fontWeight: FontWeight.w900,
                color: isSelected ? activeColor : dt.iconInactive,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, DT dt) {
    final roleColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return Row(
      children: [
        Container(
          width: 4,
          height: isMobile ? 14 : 16,
          decoration: BoxDecoration(
            color: roleColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 10 : 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: dt.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(DT dt) {
    final isMobile = context.sw < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: dt.roleSoftBg(KagemaColors.parentRed),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(color: KagemaColors.parentRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: KagemaColors.parentRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: KagemaColors.parentRed,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (!isMobile)
            IconButton(
              onPressed: _loadFinancialData,
              icon: Icon(Icons.refresh_rounded, color: KagemaColors.parentRed),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              iconSize: 20,
            ),
        ],
      ),
    );
  }
}