import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class IncomeManagementScreen extends StatefulWidget {
  const IncomeManagementScreen({super.key});

  @override
  State<IncomeManagementScreen> createState() => _IncomeManagementScreenState();
}

class _IncomeManagementScreenState extends State<IncomeManagementScreen> {
  List<Map<String, dynamic>> _incomes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await SupabaseService.instance.getIncomeEntries();
      if (mounted) {
        setState(() {
          _incomes = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Income Load Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Sync Error: Treasury link unstable.";
        });
      }
    }
  }

  void _showAddIncomeDialog({Map<String, dynamic>? incomeToEdit}) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isEditing = incomeToEdit != null;
    final sourceCtrl = TextEditingController(text: incomeToEdit?['source']);
    final amountCtrl = TextEditingController(text: incomeToEdit?['amount']?.toString());
    final refCtrl = TextEditingController(text: incomeToEdit?['reference']);
    String category = incomeToEdit?['category'] ?? 'Miscellaneous';
    String method = incomeToEdit?['method'] ?? 'Cash';

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
                  Text(isEditing ? 'MODIFY REVENUE' : 'NEURAL INCOME ENTRY', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                  ),
                  const SizedBox(height: 8),
                  Text(isEditing ? 'Update Source Intel' : 'Authorize New Revenue', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                  const SizedBox(height: 32),
                  _buildNeuralField('Income Source / Payer', Icons.person_pin_rounded, sourceCtrl, theme),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    decoration: _neuralInputDecoration('Revenue Category', Icons.category_rounded, theme),
                    items: ['Canteen', 'Uniforms', 'Donations', 'Grants', 'Rentals', 'Miscellaneous']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => category = v!,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountCtrl, 
                          keyboardType: TextInputType.number, 
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: _neuralInputDecoration('Amount (Ksh)', Icons.payments_rounded, theme),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: method,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          decoration: _neuralInputDecoration('Method', Icons.hub_rounded, theme),
                          items: ['Cash', 'Bank', 'M-Pesa', 'Cheque'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => method = v!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNeuralField('Reference / Receipt No.', Icons.sticky_note_2_rounded, refCtrl, theme),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (sourceCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                          final data = {
                            'income_id': incomeToEdit?['income_id'],
                            'source': sourceCtrl.text.trim(),
                            'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                            'category': category,
                            'method': method,
                            'reference': refCtrl.text.trim(),
                            'date': incomeToEdit?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          };
                          
                          try {
                            await SupabaseService.instance.upsertIncome(data);
                            if (mounted) {
                              Navigator.pop(context);
                              _loadIncomes();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Neural Pulse Synced: Revenue Recorded', style: TextStyle(fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.green.shade800,
                                  behavior: SnackBarBehavior.floating,
                                )
                              );
                            }
                          } catch (e) {
                            if (mounted) _loadIncomes();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800, 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: Text(isEditing ? 'COMMIT UPDATES' : 'AUTHORIZE CLOUD SYNC', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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

  InputDecoration _neuralInputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.green, size: 20),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }

  Widget _buildNeuralField(String label, IconData icon, TextEditingController ctrl, ThemeData theme) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: _neuralInputDecoration(label, icon, theme),
    );
  }

  Future<void> _deleteIncome(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Void Record?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Remove entry for "${item['source']}" from the neural audit trail?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ABORT')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('VOID', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.deleteIncome(item['income_id'].toString());
      _loadIncomes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Revenue Matrix', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)
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
              colors: [Colors.green.shade900, Colors.green.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
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
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildSummaryHeader(theme, gemini),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : RefreshIndicator(
                      onRefresh: _loadIncomes,
                      color: Colors.green,
                      child: _incomes.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: _incomes.length,
                              itemBuilder: (context, index) {
                                final item = _incomes[index];
                                return _buildIncomeCard(theme, gemini, item);
                              },
                            ),
                    ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: Colors.green.shade800,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddIncomeDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Authorize Revenue', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    double total = _incomes.fold(0.0, (sum, item) => sum + (item['amount'] as num? ?? 0.0).toDouble());
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GROSS NON-FEE REVENUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.trending_up_rounded, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text('Ksh ${NumberFormat("#,##0.##").format(total)}', 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.insights_rounded, color: Colors.green, size: 26),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: gemini?.buildGlowContainer(
        borderRadius: 28,
        borderThickness: 2,
        backgroundColor: theme.cardColor.withOpacity(0.9),
        padding: const EdgeInsets.all(24),
        child: content,
      ) ?? Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24)),
        child: content,
      ),
    );
  }

  Widget _buildIncomeCard(ThemeData theme, GeminiThemeExtension? gemini, Map<String, dynamic> item) {
    final content = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 24),
      ),
      title: Text(item['source'] ?? 'General Revenue', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text('${item['category']} • ${item['date']}', 
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Ksh ${item['amount']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 16)),
              Text(item['method']?.toString().toUpperCase() ?? 'CASH', 
                style: TextStyle(fontSize: 8, color: Colors.grey.shade500, fontWeight: FontWeight.w900, letterSpacing: 1)
              ),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (val) {
              if (val == 'edit') _showAddIncomeDialog(incomeToEdit: item);
              if (val == 'delete') _deleteIncome(item);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note_rounded, size: 20), title: Text('Edit Info', style: TextStyle(fontWeight: FontWeight.bold)), dense: true)),
              const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20), title: Text('Void Entry', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), dense: true)),
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: gemini?.buildGlowContainer(
        borderRadius: 24,
        borderThickness: 1,
        backgroundColor: theme.cardColor.withOpacity(0.85),
        padding: EdgeInsets.zero,
        child: content,
      ) ?? Card(child: content),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('NO REVENUE DATA DISCOVERED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
