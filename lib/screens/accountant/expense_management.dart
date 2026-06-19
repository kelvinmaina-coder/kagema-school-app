import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  final String _roleId = 'accountant';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getExpenses();
      if (mounted) {
        setState(() {
          _expenses = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDialog({Map<String, dynamic>? item}) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final roleColor = RoleColors.of(_roleId);
    final isEditing = item != null;
    
    final descCtrl = TextEditingController(text: item?['description']);
    final amountCtrl = TextEditingController(text: item?['amount']?.toString());
    final refCtrl = TextEditingController(text: item?['reference']);
    String category = item?['category'] ?? 'Operations';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: KagemaColors.parentRed,
          borderRadius: 35,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(isEditing ? 'MODIFY EXPENDITURE' : 'NEW EXPENSE ENTRY', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(isEditing ? 'Update Details' : 'Financial Outflow', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)
                ),
                const SizedBox(height: 32),
                _buildInputField(dt, 'Expense Description', Icons.description_rounded, descCtrl, KagemaColors.parentRed),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildInputField(dt, 'Amount (Ksh)', Icons.payments_rounded, amountCtrl, KagemaColors.parentRed, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: category,
                        dropdownColor: dt.cardBg,
                        style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                        items: ['Operations', 'Maintenance', 'Salaries', 'Supplies', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => category = v!,
                        decoration: InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded, color: KagemaColors.parentRed)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInputField(dt, 'Reference / Receipt No.', Icons.sticky_note_2_rounded, refCtrl, KagemaColors.parentRed),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (descCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                        final data = {
                          'expense_id': item?['expense_id'] ?? const Uuid().v4(),
                          'description': descCtrl.text.trim(),
                          'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                          'reference': refCtrl.text.trim(),
                          'category': category,
                          'date': item?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        };
                        await SupabaseService.instance.upsertExpense(data);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadExpenses();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: KagemaColors.parentRed, foregroundColor: Colors.white),
                    child: Text(isEditing ? 'COMMIT UPDATES' : 'SAVE EXPENSE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildInputField(DT dt, String label, IconData icon, TextEditingController ctrl, Color color, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Future<void> _deleteExpense(Map<String, dynamic> item) async {
    final dt = context.dt;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Delete Record?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Text('Remove entry for "${item['description']}" from the audit records?', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: TextStyle(color: dt.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: KagemaColors.parentRed, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed == true) {
      await SupabaseService.instance.deleteExpense(item['expense_id'].toString());
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('EXPENSE TRACKER', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.shopping_cart_checkout_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)))]),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: KagemaColors.parentRed))
              : _expenses.isEmpty 
                ? _buildEmptyState(dt)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final item = _expenses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: theme.buildGlowContainer(
                          accentColor: KagemaColors.parentRed,
                          borderRadius: 24,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.parentRed), shape: BoxShape.circle),
                              child: const Icon(Icons.outbound_rounded, color: KagemaColors.parentRed, size: 24),
                            ),
                            title: Text(item['description']?.toString().toUpperCase() ?? 'EXPENSE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('${item['category']} • ${item['date']}', 
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dt.textSecondary)
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Ksh ${NumberFormat('#,###').format(item['amount'])}', 
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: KagemaColors.parentRed, fontSize: 16)
                                ),
                                const SizedBox(height: 4),
                                Text(item['reference']?.toString().toUpperCase() ?? '', 
                                  style: TextStyle(fontSize: 8, color: dt.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1)
                                ),
                              ],
                            ),
                            onLongPress: () => _deleteExpense(item),
                            onTap: () => _showAddDialog(item: item),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: RolePlasma(
        color: KagemaColors.parentRed,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(),
          backgroundColor: KagemaColors.parentRed,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text('LOG EXPENDITURE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO EXPENSE RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
