import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../services/pesapal_service.dart';
import '../../app_theme.dart';

class FeeManagementScreen extends StatefulWidget {
  final String mode; // 'collection' or 'statements'
  const FeeManagementScreen({super.key, this.mode = 'collection'});

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> studentRecords = [];
  List<Map<String, dynamic>> filteredRecords = [];
  bool isLoading = false;
  String? errorMsg;
  final String _roleId = 'accountant';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    
    try {
      final studentsList = await SupabaseService.instance.getAllStudents();
      
      if (studentsList.isEmpty) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final List<Future<Map<String, dynamic>?>> futures = studentsList.map((sMap) async {
        try {
          final student = Student.fromMap(sMap);
          final balanceData = await SupabaseService.instance.getStudentBalance(
            student.studentId, 
            student.grade
          );
          
          return {
            'student': student,
            'totalExpected': (balanceData['total_fee'] as num? ?? 0.0).toDouble(),
            'totalPaid': (balanceData['total_paid'] as num? ?? 0.0).toDouble(),
            'balance': (balanceData['balance'] as num? ?? 0.0).toDouble(),
          };
        } catch (e) {
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);
      final validRecords = results.whereType<Map<String, dynamic>>().toList();

      if (mounted) {
        setState(() {
          studentRecords = validRecords;
          filteredRecords = validRecords;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMsg = "Sync failed. Please check connection.";
        });
      }
    }
  }

  void _searchStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRecords = studentRecords;
      } else {
        filteredRecords = studentRecords.where((r) {
          final s = r['student'] as Student;
          return s.name.toLowerCase().contains(query.toLowerCase()) || 
                 s.admissionNumber.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = DT.of(context);
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: Text(widget.mode == 'collection' ? 'COLLECTIONS' : 'STATEMENTS', 
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white, fontSize: 14)
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
      body: NeuralBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: SafeArea(
            child: Column(
              children: [
                _buildSearchHeader(dt, roleColor),
                if (errorMsg != null) _buildErrorBanner(errorMsg!),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator(color: roleColor, strokeWidth: 3))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: roleColor,
                          child: filteredRecords.isEmpty
                              ? _buildEmptyState(dt)
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                                  itemCount: filteredRecords.length,
                                  itemBuilder: (context, index) {
                                    final record = filteredRecords[index];
                                    return _buildStudentCard(dt, record);
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader(DT dt, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: LiquidGlassCard(
        borderRadius: 25,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: TextField(
          controller: _searchController,
          onChanged: _searchStudents,
          style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
          decoration: InputDecoration(
            hintText: 'SEARCH BY NAME / ADM NO',
            hintStyle: TextStyle(fontSize: 10, letterSpacing: 2, color: dt.hint),
            prefixIcon: Icon(Icons.search_rounded, color: roleColor),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(DT dt, Map<String, dynamic> record) {
    final Student student = record['student'];
    final double balance = record['balance'] ?? 0.0;
    final roleColor = RoleColors.of(_roleId);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LiquidGlassCard(
        accentColor: roleColor,
        borderRadius: 30,
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: dt.roleSoftBg(roleColor),
              child: Text(student.name[0].toUpperCase(), 
                style: TextStyle(color: roleColor, fontWeight: FontWeight.w900)
              ),
            ),
            title: Text(student.name.toUpperCase(), 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: dt.textPrimary)
            ),
            subtitle: Text('ADM: ${student.admissionNumber} • GRADE ${student.grade}', 
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1)
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('KSH ${NumberFormat('#,###').format(balance)}', 
                  style: TextStyle(fontWeight: FontWeight.w900, color: balance > 0 ? KagemaColors.parentRed : KagemaColors.teacherGreen, fontSize: 14)
                ),
                Text('BALANCE', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1)),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    Divider(color: dt.divider),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _actionIcon(dt, 'CASH', Icons.payments_rounded, KagemaColors.teacherGreen, () => _showManualPayment(student, 'Cash')),
                        _actionIcon(dt, 'PESAPAL', Icons.qr_code_scanner_rounded, KagemaColors.azure, () => _showPesapalPayment(student)),
                        _actionIcon(dt, 'WAIVER', Icons.card_giftcard_rounded, KagemaColors.secretaryViolet, () => _showManualPayment(student, 'Waiver')),
                        _actionIcon(dt, 'HISTORY', Icons.history_rounded, dt.textSecondary, () => _viewHistory(student)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(DT dt, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  void _showPesapalPayment(Student student) {
    final dt = DT.of(context);
    final amountController = TextEditingController();
    bool isProcessing = false;
    final roleColor = RoleColors.of(_roleId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => LiquidGlassCard(
          borderRadius: 40,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 32, right: 32, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 32),
                Text('INITIATE PESAPAL STK PUSH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: dt.textPrimary)),
                const SizedBox(height: 24),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: dt.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'COLLECTION AMOUNT',
                    prefixIcon: Icon(Icons.currency_exchange_rounded, color: roleColor),
                  ),
                ),
                const SizedBox(height: 32),
                if (isProcessing) 
                  const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: KagemaColors.azure))
                else SizedBox(
                  width: double.infinity, height: 65,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (amountController.text.isEmpty) return;
                      setModalState(() => isProcessing = true);
                      
                      final response = await PesapalService.instance.initiatePayment(
                        phoneNumber: student.parentPhone,
                        amount: double.parse(amountController.text),
                        email: student.parentEmail ?? 'finance@kagema.edu',
                        reference: "FEES-${student.admissionNumber}-${DateTime.now().millisecondsSinceEpoch}",
                        studentName: student.name,
                      );

                      if (mounted) {
                        setModalState(() => isProcessing = false);
                        if (response['success']) {
                          final url = Uri.parse(response['redirect_url']);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                            Navigator.pop(context);
                            _showSuccessToast("STK PUSH / CHECKOUT SENT");
                          }
                        } else {
                          _showErrorToast(response['message'] ?? "GATEWAY ERROR");
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KagemaColors.azure,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('TRIGGER PAYMENT NODE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showManualPayment(Student student, String method) {
    final dt = DT.of(context);
    final amountController = TextEditingController();
    final refController = TextEditingController();
    final color = method == 'Cash' ? KagemaColors.teacherGreen : KagemaColors.secretaryViolet;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LiquidGlassCard(
        borderRadius: 40,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 32, right: 32, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 32),
              Text('RECORD $method PAYMENT'.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: dt.textPrimary)),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: dt.textPrimary, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'AMOUNT (KSH)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: refController,
                style: TextStyle(color: dt.textPrimary, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'REFERENCE / RECEIPT NO',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 65,
                child: ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isNotEmpty) {
                      final data = {
                        'student_id': student.studentId,
                        'student_name': student.name,
                        'amount_paid': double.parse(amountController.text),
                        'payment_method': method,
                        'receipt_number': refController.text.isEmpty ? 'M-$method-${DateTime.now().millisecondsSinceEpoch}' : refController.text,
                        'payment_date': DateTime.now().toIso8601String(),
                        'term': 'Term 1', 
                        'year': DateTime.now().year,
                      };
                      await SupabaseService.instance.insertFeePayment(data);
                      if (mounted) { Navigator.pop(context); _loadData(); _showSuccessToast("RECORD SAVED"); }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('AUTHORIZE RECORD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _viewHistory(Student student) async {
    final dt = DT.of(context);
    final history = await SupabaseService.instance.getFeeHistory(student.studentId);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LiquidGlassCard(
        borderRadius: 40,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 32),
              Text('PAYMENT LEDGER: ${student.name.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, color: dt.textPrimary)),
              const SizedBox(height: 20),
              Expanded(
                child: history.isEmpty 
                  ? _buildEmptyState(dt)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: history.length,
                      itemBuilder: (context, i) {
                        final p = history[i];
                        final isManual = p['payment_method'] == 'Cash' || p['payment_method'] == 'Waiver';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: dt.roleSoftBg(dt.textSecondary),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: dt.cardBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('KSH ${NumberFormat('#,###').format(p['amount_paid'])}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: dt.textPrimary)),
                                    Text('${p['payment_method'].toString().toUpperCase()} • ${p['receipt_number']}', 
                                      style: TextStyle(fontSize: 8, color: dt.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1)
                                    ),
                                  ],
                                ),
                                Icon(isManual ? Icons.verified_user_rounded : Icons.cloud_done_rounded, color: dt.iconInactive, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10)),
      backgroundColor: KagemaColors.teacherGreen,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ));
  }

  void _showErrorToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10)),
      backgroundColor: KagemaColors.parentRed,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ));
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: KagemaColors.parentRed.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: KagemaColors.parentRed.withValues(alpha: 0.1))),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: KagemaColors.parentRed, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(color: KagemaColors.parentRed, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 24),
          Text('NO STUDENT MATCHES FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 3, fontSize: 12)),
        ],
      ),
    );
  }
}
