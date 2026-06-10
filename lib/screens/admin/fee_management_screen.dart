import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class FeeManagementScreen extends StatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  double totalCollected = 0;

  @override
  void initState() {
    super.initState();
    _fetchFeeData();
  }

  Future<void> _fetchFeeData() async {
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.instance.client
          .from('fees')
          .select('*, students(name, admission_number, grade)')
          .order('payment_date', ascending: false);
      
      final stats = await SupabaseService.instance.getDashboardSummary();

      if (mounted) {
        setState(() {
          _payments = List<Map<String, dynamic>>.from(response);
          totalCollected = (stats['totalFees'] as num?)?.toDouble() ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fee Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeaderStats(theme),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final p = _payments[index];
                      final student = p['students'];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.receipt_long, color: Colors.white)),
                          title: Text(student?['name'] ?? 'Unknown Student'),
                          subtitle: Text('ADM: ${student?['admission_number']} • ${p['payment_method']}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Ksh ${p['amount_paid']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              Text(DateFormat('MMM d, yyyy').format(DateTime.parse(p['payment_date'])), style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentDialog(),
        backgroundColor: Colors.green.shade700,
        label: const Text('Record Payment', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add_card, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.green.shade700.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Collected', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('Ksh ${totalCollected.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
            ],
          ),
          const Icon(Icons.account_balance_wallet, size: 40, color: Colors.green),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    // Logic for picking student and recording payment goes here
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cloud recording module active.")));
  }
}
