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
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
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
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          child: Container(
            decoration: BoxDecoration(
              gradient: gemini?.primaryGradient ?? LinearGradient(colors: [Colors.deepOrange.shade900, Colors.deepOrange.shade600]),
            ),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchHeader(theme, gemini, isDark),
              if (errorMsg != null) _buildErrorBanner(errorMsg!),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: theme.primaryColor, strokeWidth: 3))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: theme.primaryColor,
                        child: filteredRecords.isEmpty
                            ? _buildEmptyState(isDark)
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                                itemCount: filteredRecords.length,
                                itemBuilder: (context, index) {
                                  final record = filteredRecords[index];
                                  return _buildStudentCard(theme, gemini, record, isDark);
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme, GeminiThemeExtension? gemini, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: gemini?.buildGlowContainer(
        borderRadius: 25,
        borderThickness: 1.5,
        backgroundColor: isDark ? const Color(0xF2121418) : const Color(0xF2FFFFFF),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: TextField(
          controller: _searchController,
          onChanged: _searchStudents,
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'SEARCH BY NAME / ADM NO',
            hintStyle: TextStyle(fontSize: 10, letterSpacing: 2, color: isDark ? Colors.white24 : Colors.black26),
            prefixIcon: Icon(Icons.search_rounded, color: theme.primaryColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ) ?? const SizedBox(),
    );
  }

  Widget _buildStudentCard(ThemeData theme, GeminiThemeExtension? gemini, Map<String, dynamic> record, bool isDark) {
    final Student student = record['student'];
    final double balance = record['balance'] ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 1.2,
        backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
        padding: EdgeInsets.zero,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              child: Text(student.name[0].toUpperCase(), 
                style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900)
              ),
            ),
            title: Text(student.name.toUpperCase(), 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: isDark ? Colors.white : Colors.black87)
            ),
            subtitle: Text('ADM: ${student.admissionNumber} • GRADE ${student.grade}', 
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 1)
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('KSH ${NumberFormat('#,###').format(balance)}', 
                  style: TextStyle(fontWeight: FontWeight.w900, color: balance > 0 ? const Color(0xFFFF3D00) : const Color(0xFF00E676), fontSize: 14)
                ),
                const Text('BALANCE', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    Container(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _actionIcon('CASH', Icons.payments_rounded, const Color(0xFF00E676), () => _showManualPayment(student, 'Cash')),
                        _actionIcon('PESAPAL', Icons.qr_code_scanner_rounded, const Color(0xFF2979FF), () => _showPesapalPayment(student)),
                        _actionIcon('WAIVER', Icons.card_giftcard_rounded, const Color(0xFF7C4DFF), () => _showManualPayment(student, 'Waiver')),
                        _actionIcon('HISTORY', Icons.history_rounded, Colors.blueGrey, () => _viewHistory(student)),
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

  Widget _actionIcon(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  void _showPesapalPayment(Student student) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final amountController = TextEditingController();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 32, right: 32, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 32),
              const Text('INITIATE PESAPAL STK PUSH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                decoration: InputDecoration(
                  labelText: 'COLLECTION AMOUNT',
                  labelStyle: TextStyle(color: theme.primaryColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
                  prefixIcon: Icon(Icons.currency_exchange_rounded, color: theme.primaryColor),
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.03),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: theme.primaryColor, width: 2)),
                ),
              ),
              const SizedBox(height: 32),
              if (isProcessing) 
                const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF2979FF)))
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
                    backgroundColor: const Color(0xFF2979FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 0,
                  ),
                  child: const Text('TRIGGER PAYMENT NODE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualPayment(Student student, String method) {
    final theme = Theme.of(context);
    final amountController = TextEditingController();
    final refController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 32, right: 32, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 32),
            Text('RECORD $method PAYMENT'.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'AMOUNT (KSH)',
                labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: refController,
              decoration: InputDecoration(
                labelText: 'REFERENCE / RECEIPT NO',
                labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
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
                      'term': 'Term 1', // Simplified for now
                      'year': DateTime.now().year,
                    };
                    await SupabaseService.instance.insertFeePayment(data);
                    if (mounted) { Navigator.pop(context); _loadData(); _showSuccessToast("RECORD SAVED"); }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: method == 'Cash' ? const Color(0xFF00E676) : const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text('AUTHORIZE RECORD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _viewHistory(Student student) async {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isDark = theme.brightness == Brightness.dark;
    final history = await SupabaseService.instance.getFeeHistory(student.studentId);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 32),
            Text('PAYMENT LEDGER: ${student.name.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 20),
            Expanded(
              child: history.isEmpty 
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: history.length,
                    itemBuilder: (context, i) {
                      final p = history[i];
                      final isManual = p['payment_method'] == 'Cash' || p['payment_method'] == 'Waiver';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('KSH ${NumberFormat('#,###').format(p['amount_paid'])}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                Text('${p['payment_method'].toString().toUpperCase()} • ${p['receipt_number']}', 
                                  style: TextStyle(fontSize: 8, color: Colors.blueGrey, fontWeight: FontWeight.w900, letterSpacing: 1)
                                ),
                              ],
                            ),
                            Icon(isManual ? Icons.verified_user_rounded : Icons.cloud_done_rounded, color: Colors.blueGrey.withValues(alpha: 0.3), size: 20),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10)),
      backgroundColor: const Color(0xFF00E676),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ));
  }

  void _showErrorToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10)),
      backgroundColor: const Color(0xFFFF3D00),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ));
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFF3D00).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFFF3D00).withValues(alpha: 0.1))),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF3D00), size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(color: Color(0xFFFF3D00), fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 24),
          const Text('NO STUDENT MATCHES FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 3, fontSize: 12)),
        ],
      ),
    );
  }
}
