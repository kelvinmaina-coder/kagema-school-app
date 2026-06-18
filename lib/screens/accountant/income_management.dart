import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class IncomeManagementScreen extends StatefulWidget {
  const IncomeManagementScreen({super.key});

  @override
  State<IncomeManagementScreen> createState() => _IncomeManagementScreenState();
}

class _IncomeManagementScreenState extends State<IncomeManagementScreen> {
  List<Map<String, dynamic>> _income = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncome();
  }

  Future<void> _loadIncome() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getIncomeEntries();
      if (mounted) {
        setState(() {
          _income = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDialog({Map<String, dynamic>? item}) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isEditing = item != null;
    
    final sourceCtrl = TextEditingController(text: item?['source']);
    final amountCtrl = TextEditingController(text: item?['amount']?.toString());
    final refCtrl = TextEditingController(text: item?['reference']);
    String category = item?['category'] ?? 'Tuition';
    String method = item?['payment_method'] ?? 'Cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: gemini?.buildCreativeBackground(
          isDark: theme.brightness == Brightness.dark,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text(isEditing ? 'MODIFY REVENUE' : 'NEW INCOME ENTRY', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                  ),
                  const SizedBox(height: 32),
                  _buildInputField('Income Source / Payer', Icons.person_pin_rounded, sourceCtrl, theme),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInputField('Amount (Ksh)', Icons.payments_rounded, amountCtrl, theme, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: method,
                          items: ['Cash', 'M-Pesa', 'Bank', 'Check'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (v) => method = v!,
                          decoration: _inputDecoration('Method', Icons.payment_rounded, theme),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInputField('Reference / Receipt No.', Icons.sticky_note_2_rounded, refCtrl, theme),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    items: ['Tuition', 'Uniform', 'Transport', 'Donation', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => category = v!,
                    decoration: _inputDecoration('Revenue Category', Icons.category_rounded, theme),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (sourceCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                          final data = {
                            'income_id': item?['income_id'] ?? const Uuid().v4(),
                            'source': sourceCtrl.text.trim(),
                            'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                            'reference': refCtrl.text.trim(),
                            'category': category,
                            'payment_method': method,
                            'date': item?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          };
                          await SupabaseService.instance.upsertIncome(data);
                          if (mounted) {
                            Navigator.pop(context);
                            _loadIncome();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Revenue Recorded Successfully', style: TextStyle(fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.green.shade800,
                                behavior: SnackBarBehavior.floating,
                              )
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 8),
                      child: Text(isEditing ? 'COMMIT UPDATES' : 'SAVE INCOME', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ) ?? const SizedBox(),
      ),
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController ctrl, ThemeData theme, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: _inputDecoration(label, icon, theme),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, color: theme.primaryColor, size: 20),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }

  Future<void> _deleteIncome(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Record?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Remove entry for "${item['source']}" from the audit records?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed == true) {
      await SupabaseService.instance.deleteIncome(item['income_id'].toString());
      _loadIncome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Revenue Management', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.green.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.account_balance_wallet_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _income.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _income.length,
                  itemBuilder: (context, index) {
                    final item = _income[index];
                    final content = ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.add_chart_rounded, color: Colors.green, size: 24),
                      ),
                      title: Text(item['source'] ?? 'Income', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      subtitle: Text('${item['category']} • ${item['payment_method']}\n${item['date']}', style: const TextStyle(fontSize: 11, height: 1.4)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Ksh ${NumberFormat('#,###').format(item['amount'])}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(item['reference'] ?? '', style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      onLongPress: () => _deleteIncome(item),
                      onTap: () => _showAddDialog(item: item),
                    );
                    return Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content));
                  },
                ),
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: theme.primaryColor,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Revenue', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.money_off_rounded, size: 80, color: Colors.grey), SizedBox(height: 16), Text('NO REVENUE RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5))]));
  }
}
