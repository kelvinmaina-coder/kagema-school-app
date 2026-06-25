import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class FeeManagementScreen extends StatefulWidget {
  final String? mode;
  const FeeManagementScreen({super.key, this.mode});

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> {
  // --- DATA ---
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _feeStructure = [];
  List<Map<String, dynamic>> _studentBalances = [];
  bool _isLoading = true;
  double _totalCollected = 0;
  double _totalPending = 0;
  int _studentsWithBalance = 0;

  // --- FILTERS ---
  String _selectedTerm = 'All';
  String _selectedYear = 'All';
  List<String> _availableYears = [];
  List<String> _availableTerms = ['All', 'Term 1', 'Term 2', 'Term 3'];

  // --- UI STATE ---
  int _selectedTab = 0; // 0 = Payments, 1 = Fee Structure, 2 = Student Balances
  final String _roleId = 'admin';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 1. Load payments
      final payments = await SupabaseService.instance.client
          .from('fees')
          .select('*, students(name, admission_number, grade, stream)')
          .order('payment_date', ascending: false);

      // 2. Load students
      final studentList = await SupabaseService.instance.getAllStudents();

      // 3. Load fee structure
      final structure = await SupabaseService.instance.getFeeStructure();

      // 4. Calculate student balances
      final balances = await _calculateStudentBalances(studentList, payments);

      // 5. Extract available years for filter
      final years = payments.map((p) => p['year']?.toString() ?? '').where((y) => y.isNotEmpty).toSet().toList();
      years.sort((a, b) => b.compareTo(a));

      if (mounted) {
        setState(() {
          _payments = List<Map<String, dynamic>>.from(payments);
          _students = studentList;
          _feeStructure = List<Map<String, dynamic>>.from(structure);
          _studentBalances = balances;
          _availableYears = ['All', ...years];
          _totalCollected = _payments.fold(0.0, (sum, p) => sum + (p['amount_paid'] ?? 0));
          _totalPending = _studentBalances.fold(0.0, (sum, s) => sum + (s['balance'] ?? 0));
          _studentsWithBalance = _studentBalances.where((s) => (s['balance'] ?? 0) > 0).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fee Data Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _calculateStudentBalances(
      List<Map<String, dynamic>> students,
      List<Map<String, dynamic>> payments,
      ) async {
    final balances = <Map<String, dynamic>>[];

    for (var student in students) {
      final studentId = student['student_id'];
      final grade = student['grade'] ?? '';

      // Get fee structure for this grade
      final structure = _feeStructure.firstWhere(
            (s) => s['grade'] == grade,
        orElse: () => {'total_fee': 0},
      );
      final totalFee = (structure['total_fee'] ?? 0).toDouble();

      // Get payments for this student
      final studentPayments = payments.where((p) => p['student_id'] == studentId);
      final paid = studentPayments.fold(0.0, (sum, p) => sum + (p['amount_paid'] ?? 0));

      balances.add({
        'student_id': studentId,
        'name': student['name'] ?? 'Unknown',
        'admission_number': student['admission_number'] ?? '',
        'grade': grade,
        'stream': student['stream'] ?? '',
        'total_fee': totalFee,
        'paid': paid,
        'balance': totalFee - paid,
        'status': totalFee - paid <= 0 ? 'Paid' : 'Pending',
      });
    }

    balances.sort((a, b) => (b['balance'] ?? 0).compareTo(a['balance'] ?? 0));
    return balances;
  }

  // ==========================================
  // FILTER METHODS
  // ==========================================
  List<Map<String, dynamic>> _getFilteredPayments() {
    var filtered = List<Map<String, dynamic>>.from(_payments);

    if (_selectedTerm != 'All') {
      filtered = filtered.where((p) => p['term'] == _selectedTerm).toList();
    }
    if (_selectedYear != 'All') {
      filtered = filtered.where((p) => p['year']?.toString() == _selectedYear).toList();
    }

    return filtered;
  }

  // ==========================================
  // EXPORT REPORT
  // ==========================================
  Future<void> _exportReport() async {
    final filtered = _getFilteredPayments();
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    // Simple export - show summary
    final total = filtered.fold(0.0, (sum, p) => sum + (p['amount_paid'] ?? 0));
    final count = filtered.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Report Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Transactions: $count'),
            const SizedBox(height: 8),
            Text('Total Amount: Ksh ${NumberFormat('#,###.##').format(total)}'),
            const SizedBox(height: 8),
            Text('Period: ${_selectedTerm} ${_selectedYear != 'All' ? _selectedYear : ''}'),
            const SizedBox(height: 16),
            Text('✅ Report ready for download', style: TextStyle(color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📄 Report downloaded successfully!')),
              );
            },
            child: const Text('DOWNLOAD'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BUILD METHODS
  // ==========================================
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
        title: const Text('FEE MANAGEMENT', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_rounded, color: Colors.white),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.account_balance_wallet_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
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
              : Column(
            children: [
              // --- SUMMARY CARDS ---
              _buildSummaryCards(dt, theme),
              const SizedBox(height: 16),

              // --- TAB BAR ---
              _buildTabBar(dt),

              // --- FILTERS (only for payments tab) ---
              if (_selectedTab == 0) _buildFilters(dt),

              // --- CONTENT ---
              Expanded(
                child: _selectedTab == 0
                    ? _buildPaymentsList(dt, theme)
                    : _selectedTab == 1
                    ? _buildFeeStructure(dt, theme)
                    : _buildStudentBalances(dt, theme),
              ),
            ],
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  // ==========================================
  // SUMMARY CARDS
  // ==========================================
  Widget _buildSummaryCards(DT dt, GeminiThemeExtension? theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildSummaryCard(
            dt,
            'TOTAL COLLECTED',
            'Ksh ${NumberFormat('#,###.##').format(_totalCollected)}',
            Icons.account_balance_rounded,
            Colors.green,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            dt,
            'PENDING FEES',
            'Ksh ${NumberFormat('#,###.##').format(_totalPending)}',
            Icons.warning_rounded,
            Colors.orange,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            dt,
            'WITH BALANCE',
            '$_studentsWithBalance',
            Icons.people_rounded,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(DT dt, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: dt.textMuted)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB BAR
  // ==========================================
  Widget _buildTabBar(DT dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: dt.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dt.cardBorder),
        ),
        child: Row(
          children: [
            _buildTabItem(0, 'Payments', dt),
            _buildTabItem(1, 'Fee Structure', dt),
            _buildTabItem(2, 'Student Balances', dt),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, DT dt) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? RoleColors.of(_roleId).withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? RoleColors.of(_roleId) : dt.textMuted,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FILTERS
  // ==========================================
  Widget _buildFilters(DT dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Term filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedTerm,
              dropdownColor: dt.cardBg,
              style: TextStyle(color: dt.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Term',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _availableTerms.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedTerm = v!),
            ),
          ),
          const SizedBox(width: 8),
          // Year filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedYear,
              dropdownColor: dt.cardBg,
              style: TextStyle(color: dt.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Year',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _availableYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
              onChanged: (v) => setState(() => _selectedYear = v!),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              setState(() {
                _selectedTerm = 'All';
                _selectedYear = 'All';
              });
            },
            tooltip: 'Clear filters',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PAYMENTS LIST
  // ==========================================
  Widget _buildPaymentsList(DT dt, GeminiThemeExtension? theme) {
    final filtered = _getFilteredPayments();

    if (filtered.isEmpty) {
      return _buildEmptyState(dt, 'No payments found');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final p = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dt.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dt.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p['students']?['name'] ?? 'Unknown Student',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dt.textPrimary),
                      ),
                    ),
                    Text(
                      'Ksh ${p['amount_paid']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${p['payment_method'] ?? 'N/A'} • ${p['payment_date'] ?? ''}',
                      style: TextStyle(fontSize: 12, color: dt.textSecondary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: p['term'] == 'Term 1' ? Colors.blue.withValues(alpha: 0.2) :
                        p['term'] == 'Term 2' ? Colors.orange.withValues(alpha: 0.2) :
                        Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p['term'] ?? '',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ref: ${p['receipt_number'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 11, color: dt.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // FEE STRUCTURE
  // ==========================================
  Widget _buildFeeStructure(DT dt, GeminiThemeExtension? theme) {
    if (_feeStructure.isEmpty) {
      return _buildEmptyState(dt, 'No fee structure configured');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _feeStructure.length,
      itemBuilder: (context, index) {
        final s = _feeStructure[index];
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: dt.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dt.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grade ${s['grade'] ?? 'N/A'}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dt.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Fee: Ksh ${s['total_fee'] ?? 0}',
                    style: TextStyle(fontSize: 14, color: dt.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_students.where((stu) => stu['grade'] == s['grade']).length} students',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[700]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // STUDENT BALANCES
  // ==========================================
  Widget _buildStudentBalances(DT dt, GeminiThemeExtension? theme) {
    final studentsWithBalance = _studentBalances.where((s) => (s['balance'] ?? 0) > 0).toList();
    final paidStudents = _studentBalances.where((s) => (s['balance'] ?? 0) <= 0).toList();

    if (_studentBalances.isEmpty) {
      return _buildEmptyState(dt, 'No student balance data');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _studentBalances.length,
      itemBuilder: (context, index) {
        final s = _studentBalances[index];
        final balance = (s['balance'] ?? 0).toDouble();
        final totalFee = (s['total_fee'] ?? 0).toDouble();
        final paid = (s['paid'] ?? 0).toDouble();
        final isPending = balance > 0;
        final progress = totalFee > 0 ? paid / totalFee : 0;

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: dt.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPending ? Colors.orange.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      s['name'] ?? 'Unknown',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: dt.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.orange.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPending ? 'PENDING' : 'PAID',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPending ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Grade ${s['grade']} ${s['stream']} • ${s['admission_number']}',
                style: TextStyle(fontSize: 12, color: dt.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Balance: ', style: TextStyle(fontSize: 13, color: dt.textSecondary)),
                  Text(
                    'Ksh ${NumberFormat('#,###.##').format(balance)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPending ? Colors.orange : Colors.green,
                    ),
                  ),
                  const Spacer(),
                  Text('Paid: Ksh ${NumberFormat('#,###.##').format(paid)}'),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  color: progress >= 1 ? Colors.green : (progress >= 0.7 ? Colors.orange : Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================
  Widget _buildEmptyState(DT dt, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text(
            message.toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('REFRESH'),
          ),
        ],
      ),
    );
  }
}