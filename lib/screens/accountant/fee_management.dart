import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final studentsList = await SupabaseService.instance.getAllStudents();
      
      List<Map<String, dynamic>> records = [];
      for (var sMap in studentsList) {
        final student = Student.fromMap(sMap);
        final balanceData = await SupabaseService.instance.getStudentBalance(
          student.studentId, 
          student.grade
        );
        
        records.add({
          'student': student,
          'totalExpected': balanceData['required'],
          'totalPaid': balanceData['paid'],
          'balance': balanceData['balance'],
        });
      }

      if (mounted) {
        setState(() {
          studentRecords = records;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fee Data Load Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _searchStudents(String query) {
    if (query.isEmpty) {
      _loadData();
      return;
    }
    setState(() {
      studentRecords = studentRecords.where((r) {
        final s = r['student'] as Student;
        return s.name.toLowerCase().contains(query.toLowerCase()) || 
               s.admissionNumber.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.mode == 'collection' ? 'Fee Collection' : 'Student Statements', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.deepOrange, Colors.deepOrange.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
          child: Column(
            children: [
              _buildSearchHeader(theme),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : studentRecords.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: studentRecords.length,
                            itemBuilder: (context, index) {
                              final record = studentRecords[index];
                              return _buildStudentRecordCard(theme, record);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchStudents,
        decoration: const InputDecoration(
          hintText: 'Search by name or ADM...',
          prefixIcon: Icon(Icons.search, color: Colors.deepOrange),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildStudentRecordCard(ThemeData theme, Map<String, dynamic> record) {
    final Student student = record['student'];
    final double balance = record['balance'];
    final double paid = record['totalPaid'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepOrange.withOpacity(0.1),
          child: Text(student.name[0], style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
        ),
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('ADM: ${student.admissionNumber} | Bal: Ksh $balance'),
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _infoItem('Total Fee', 'Ksh ${record['totalExpected']}'),
                    _infoItem('Paid', 'Ksh $paid', color: Colors.green),
                    _infoItem('Balance', 'Ksh $balance', color: Colors.red),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    if (widget.mode == 'collection')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showPaymentDialog(student),
                          icon: const Icon(Icons.add_card),
                          label: const Text('RECORD PAYMENT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, 
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewHistory(student),
                        icon: const Icon(Icons.history),
                        label: const Text('HISTORY'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14)),
      ],
    );
  }

  void _showPaymentDialog(Student student) {
    final amountController = TextEditingController();
    String selectedTerm = 'Term 1';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment: ${student.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedTerm,
              items: ['Term 1', 'Term 2', 'Term 3'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => selectedTerm = v!,
              decoration: const InputDecoration(labelText: 'Academic Term'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount Paid (Ksh)', prefixText: 'Ksh '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                final payment = {
                  'student_id': student.studentId,
                  'student_name': student.name,
                  'amount_paid': double.tryParse(amountController.text) ?? 0.0,
                  'term': selectedTerm,
                  'year': DateTime.now().year,
                  'payment_date': DateTime.now().toIso8601String(),
                  'receipt_number': 'RCP-${DateTime.now().millisecondsSinceEpoch}',
                };
                await SupabaseService.instance.insertFeePayment(payment);
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              }
            },
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  void _viewHistory(Student student) async {
    final history = await SupabaseService.instance.getFeeHistory(student.studentId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Text('Payment History: ${student.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            Expanded(
              child: history.isEmpty 
                ? const Center(child: Text('No cloud records found for this student.'))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, i) {
                      final p = history[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long, color: Colors.green),
                          title: Text('Ksh ${p['amount_paid']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('RCP: ${p['receipt_number']} • ${p['term']}'),
                          trailing: Text(p['payment_date'].toString().split('T')[0], style: const TextStyle(fontSize: 10, color: Colors.grey)),
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

  Widget _buildEmptyState() {
    return const Center(child: Text('No student records discovered.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)));
  }
}
