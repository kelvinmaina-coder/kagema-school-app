import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  String _selectedReportType = 'Daily';
  List<Map<String, dynamic>> _reportData = [];
  double _totalAmount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    String dateFilter = '';
    final now = DateTime.now();

    if (_selectedReportType == 'Daily') {
      dateFilter = DateFormat('yyyy-MM-dd').format(now);
    } else if (_selectedReportType == 'Weekly') {
      dateFilter = DateFormat('yyyy-MM').format(now); 
    } else if (_selectedReportType == 'Monthly') {
      dateFilter = DateFormat('yyyy-MM').format(now);
    } else if (_selectedReportType == 'Annual') {
      dateFilter = DateFormat('yyyy').format(now);
    }

    try {
      final results = await SupabaseService.instance.getFeeReports(dateFilter);
      double total = 0;
      for (var r in results) {
        total += (r['amount_paid'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _reportData = results;
          _totalAmount = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Report Generation Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Financial Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blueAccent.withOpacity(0.8)]),
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
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Daily', 'Weekly', 'Monthly', 'Annual'].map((type) {
                    bool isSelected = _selectedReportType == type;
                    return ChoiceChip(
                      label: Text(type, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.blueAccent),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedReportType = type);
                          _generateReport();
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              _buildSummaryHeader(theme),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _reportData.isEmpty
                        ? const Center(child: Text('No records for this period in cloud.', style: TextStyle(fontWeight: FontWeight.bold)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _reportData.length,
                            itemBuilder: (context, index) {
                              final item = _reportData[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.receipt_long, color: Colors.white)),
                                  title: Text(item['students']?['name'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(item['payment_date'] ?? ''),
                                  trailing: Text(
                                    'Ksh ${item['amount_paid']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.95),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TOTAL COLLECTION:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
            Text('Ksh $_totalAmount', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.blueAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _summaryCard(theme, 'Transactions', '${_reportData.length}', Icons.numbers, Colors.orange),
          const SizedBox(width: 16),
          _summaryCard(theme, 'Avg Payment', 'Ksh ${_reportData.isEmpty ? 0 : (_totalAmount / _reportData.length).toStringAsFixed(0)}', Icons.payments, Colors.green),
        ],
      ),
    );
  }

  Widget _summaryCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
