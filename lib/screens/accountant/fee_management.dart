import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../services/pdf_generator_service.dart';
import '../../services/mpesa_service.dart';
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

      // OPTIMIZED: Process students in parallel to avoid "plain screen" hang
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
            'arrears': 0.0, 
          };
        } catch (e) {
          debugPrint("Neural processing error for student: $e");
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);
      final List<Map<String, dynamic>> validRecords = results.whereType<Map<String, dynamic>>().toList();

      if (mounted) {
        setState(() {
          studentRecords = validRecords;
          filteredRecords = validRecords;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fee Matrix Sync Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMsg = "Sync interrupted. Pull down to retry connection.";
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.mode == 'collection' ? 'Neural Collection' : 'Quantum Statements', 
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white, fontSize: 18)
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
              colors: [Colors.deepOrange.shade900, Colors.deepOrange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.account_balance_wallet_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchHeader(theme, gemini),
              if (errorMsg != null)
                _buildErrorPanel(errorMsg!),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                    : filteredRecords.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: Colors.deepOrange,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                              itemCount: filteredRecords.length,
                              itemBuilder: (context, index) {
                                final record = filteredRecords[index];
                                return _buildStudentRecordCard(theme, gemini, record);
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

  Widget _buildErrorPanel(String msg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red.withOpacity(0.1))),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.red, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = TextField(
      controller: _searchController,
      onChanged: _searchStudents,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: 'Neural search by name or ADM...',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.deepOrange),
        border: InputBorder.none,
        suffixIcon: _searchController.text.isNotEmpty 
          ? IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.grey), onPressed: () {
              _searchController.clear();
              _searchStudents('');
            })
          : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: gemini?.buildGlowContainer(
        borderRadius: 20,
        borderThickness: 1.5,
        backgroundColor: theme.cardColor.withOpacity(0.95),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: content,
      ) ?? Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]
        ),
        child: content,
      ),
    );
  }

  Widget _buildStudentRecordCard(ThemeData theme, GeminiThemeExtension? gemini, Map<String, dynamic> record) {
    final Student student = record['student'];
    final double balance = record['balance'] ?? 0.0;
    final double paid = record['totalPaid'] ?? 0.0;
    final double expected = record['totalExpected'] ?? 0.0;
    final double arrears = record['arrears'] ?? 0.0;

    final content = ExpansionTile(
      shape: const Border(),
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.deepOrange.withOpacity(0.1),
        child: Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : '?', 
          style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w900, fontSize: 20)
        ),
      ),
      title: Text(student.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      subtitle: Text('ADM: ${student.admissionNumber} • Grade ${student.grade}', 
        style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12, fontWeight: FontWeight.w700)
      ),
      childrenPadding: const EdgeInsets.all(20),
      children: [
        gemini?.buildGlowContainer(
          borderRadius: 24,
          borderThickness: 1,
          backgroundColor: Colors.deepOrange.withOpacity(0.02),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ledgerItem('Total Neural Invoice', expected, Colors.blueGrey),
                  _ledgerItem('Synchronized', paid, Colors.green),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ledgerItem('Arrears', arrears, Colors.orange.shade700),
                  _ledgerItem('Quantum Balance', balance, balance > 0 ? Colors.red : Colors.green, isBold: true),
                ],
              ),
              const Divider(height: 40, thickness: 1, color: Colors.white10),
              Text('NEURAL OPERATIONS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _operationButton('RECORD CASH', Icons.payments_rounded, Colors.green, () => _showPaymentDialog(student)),
                  _operationButton('STK PUSH', Icons.phonelink_ring_rounded, Colors.blue, () => _showStkPushDialog(student)),
                  _operationButton('WAIVER', Icons.stars_rounded, Colors.purple, () => _showWaiverDialog(student)),
                  _operationButton('LEDGER', Icons.list_alt_rounded, Colors.blueGrey, () => _viewHistory(student)),
                ],
              ),
            ],
          ),
        ) ?? const SizedBox(),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 1.5,
        backgroundColor: theme.cardColor.withOpacity(0.85),
        padding: EdgeInsets.zero,
        child: content,
      ) ?? Card(child: content),
    );
  }

  Widget _operationButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _ledgerItem(String label, double amount, Color color, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(
          'Ksh ${NumberFormat("#,##0.##").format(amount)}', 
          style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.w800, color: color, fontSize: 14, letterSpacing: 0.5)
        ),
      ],
    );
  }

  void _showPaymentDialog(Student student) {
    final theme = Theme.of(context);
    final amountController = TextEditingController();
    final refController = TextEditingController();
    String selectedMethod = 'Cash';
    String selectedCategory = 'Tuition';
    String selectedTerm = 'Term 1';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('NEURAL REVENUE ENTRY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(student.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 32),
                _buildNeuralDropdown('Target Cycle', selectedTerm, ['Term 1', 'Term 2', 'Term 3'], (v) => selectedTerm = v!, Icons.layers_rounded, theme),
                const SizedBox(height: 16),
                _buildNeuralDropdown('Payment Mode', selectedMethod, ['Cash', 'M-Pesa', 'Bank Deposit', 'Cheque'], (v) => selectedMethod = v!, Icons.hub_rounded, theme),
                const SizedBox(height: 16),
                _buildNeuralDropdown('Category', selectedCategory, ['Tuition', 'Transport', 'Boarding', 'Activities', 'Uniform'], (v) => selectedCategory = v!, Icons.category_rounded, theme),
                const SizedBox(height: 16),
                _buildNeuralField('Amount Received (Ksh)', Icons.payments_rounded, amountController, theme, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildNeuralField('Neural Ref / Note', Icons.qr_code_rounded, refController, theme),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (amountController.text.isNotEmpty) {
                        final amount = double.tryParse(amountController.text) ?? 0.0;
                        final receiptNo = 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
                        final paymentDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
                        
                        final payment = {
                          'student_id': student.studentId,
                          'student_name': student.name,
                          'amount_paid': amount,
                          'term': selectedTerm,
                          'year': DateTime.now().year,
                          'payment_method': selectedMethod,
                          'category': selectedCategory,
                          'reference': refController.text.trim(),
                          'receipt_number': receiptNo,
                          'payment_date': paymentDate,
                        };

                        try {
                          await SupabaseService.instance.insertFeePayment(payment);
                          if (context.mounted) {
                            Navigator.pop(context);
                            await PdfGeneratorService.generateReceipt(payment);
                            _showSuccessAndReceipt(payment);
                            _loadData();
                          }
                        } catch (e) {
                          if (mounted) _loadData();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade800, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                    child: const Text('AUTHORIZE & PRINT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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

  Widget _buildNeuralDropdown(String label, String value, List<String> items, Function(String?) onChanged, IconData icon, ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.deepOrange, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildNeuralField(String label, IconData icon, TextEditingController ctrl, ThemeData theme, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.deepOrange, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  void _showWaiverDialog(Student student) {
    final theme = Theme.of(context);
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('NEURAL GRANT AUTHORIZATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(student.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 32),
              _buildNeuralField('Waiver Quota (Ksh)', Icons.stars_rounded, amountController, theme, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildNeuralField('Intelligence Logic (Reason)', Icons.psychology_rounded, reasonController, theme),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isNotEmpty) {
                      final amount = double.tryParse(amountController.text) ?? 0.0;
                      final receiptNo = 'WAV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                      final paymentDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
                      
                      final payment = {
                        'student_id': student.studentId,
                        'student_name': student.name,
                        'amount_paid': amount,
                        'term': 'Annual',
                        'year': DateTime.now().year,
                        'payment_method': 'Waiver',
                        'category': 'Grant/Discount',
                        'reference': reasonController.text.trim(),
                        'receipt_number': receiptNo,
                        'payment_date': paymentDate,
                      };
                      
                      try {
                        await SupabaseService.instance.insertFeePayment(payment);
                        if (mounted) {
                          Navigator.pop(context);
                          await PdfGeneratorService.generateReceipt(payment);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Neural Grant Applied & Cataloged!', style: TextStyle(fontWeight: FontWeight.bold)), 
                              backgroundColor: Colors.purple.shade800,
                              behavior: SnackBarBehavior.floating,
                            )
                          );
                          _loadData();
                        }
                      } catch (e) {
                        if (mounted) _loadData();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade800, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8,
                  ),
                  child: const Text('AUTHORIZE GRANT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showStkPushDialog(Student student) {
    final theme = Theme.of(context);
    final phoneController = TextEditingController(text: student.parentPhone.replaceAll(' ', ''));
    final amountController = TextEditingController();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('STK QUANTUM PUSH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('M-Pesa Express Sync', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 32),
                _buildNeuralField('Verified Contact', Icons.phone_iphone_rounded, phoneController, theme, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildNeuralField('Neural Quota to Push', Icons.add_shopping_cart_rounded, amountController, theme, keyboardType: TextInputType.number),
                const SizedBox(height: 32),
                if (isProcessing) 
                  const Center(child: Column(children: [CircularProgressIndicator(color: Colors.green), SizedBox(height: 12), Text('Establishing Secure Handshake...', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic))])),
                const SizedBox(height: 40),
                if (!isProcessing)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (amountController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                          setDialogState(() => isProcessing = true);
                          final amount = double.tryParse(amountController.text) ?? 0.0;
                          final result = await MpesaService.instance.initiateStkPush(
                            phoneNumber: phoneController.text,
                            amount: amount,
                            reference: "FEES-${student.admissionNumber}",
                          );

                          if (context.mounted) {
                            if (result['success'] == true) {
                              final receiptNo = 'MPA-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
                              final payment = {
                                'student_id': student.studentId,
                                'student_name': student.name,
                                'amount_paid': amount,
                                'term': 'Term 1',
                                'year': DateTime.now().year,
                                'payment_method': 'M-Pesa',
                                'category': 'Tuition',
                                'reference': 'STK:${result['CheckoutRequestID']}',
                                'receipt_number': receiptNo,
                                'payment_date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                              };
                              await SupabaseService.instance.insertFeePayment(payment);
                              if (context.mounted) {
                                Navigator.pop(context);
                                await PdfGeneratorService.generateReceipt(payment);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('STK Push Initiated: ${result['message']}'), backgroundColor: Colors.green.shade800));
                                _loadData();
                              }
                            } else {
                              setDialogState(() => isProcessing = false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Push Error: ${result['message']}'), backgroundColor: Colors.red));
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: const Text('AUTHORIZE PUSH SIGNAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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

  void _showSuccessAndReceipt(Map<String, dynamic> payment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Neural Transaction Success: Logged & Verified!', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'RE-PRINT',
          textColor: Colors.white,
          onPressed: () => PdfGeneratorService.generateReceipt(payment),
        ),
      ),
    );
  }

  void _viewHistory(Student student) async {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final history = await SupabaseService.instance.getFeeHistory(student.studentId);
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        height: MediaQuery.of(context).size.height * 0.85,
        child: gemini?.buildCreativeBackground(
          isDark: theme.brightness == Brightness.dark,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                Text('NEURAL LEDGER MATRIX', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(student.name.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text('ADM IDENTIFIER: ${student.admissionNumber}', style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w900, fontSize: 11)),
                const Divider(height: 40, thickness: 1, color: Colors.white10),
                Expanded(
                  child: history.isEmpty 
                    ? const Center(child: Text('NO NEURAL RECORDS DISCOVERED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)))
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, i) {
                          final p = history[i];
                          final isWaiver = p['payment_method'] == 'Waiver';
                          final color = isWaiver ? Colors.purple : Colors.green;
                          final hContent = ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(isWaiver ? Icons.stars_rounded : Icons.receipt_long_rounded, color: color, size: 22),
                            ),
                            title: Text('Ksh ${NumberFormat("#,##0").format(p['amount_paid'])}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            subtitle: Text('${p['payment_method']} • ${p['category']}\n${p['payment_date']}', style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600, color: Colors.grey)),
                            trailing: IconButton(
                              icon: const Icon(Icons.print_rounded, color: Colors.blue),
                              onPressed: () => PdfGeneratorService.generateReceipt(p),
                            ),
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: gemini?.buildGlowContainer(
                              borderRadius: 24,
                              borderThickness: 1,
                              backgroundColor: theme.cardColor.withOpacity(0.85),
                              padding: EdgeInsets.zero,
                              child: hContent,
                            ) ?? Card(child: hContent),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ) ?? const SizedBox(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text('IDENTITY REGISTRY EMPTY', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 16, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
