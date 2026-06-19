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
  final String _roleId = 'accountant';

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
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final roleColor = RoleColors.of(_roleId);
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
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 35,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(isEditing ? 'MODIFY REVENUE' : 'NEW INCOME ENTRY', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(isEditing ? 'Update Details' : 'Revenue Registration', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)
                ),
                const SizedBox(height: 32),
                _buildInputField(dt, 'Income Source / Payer', Icons.person_pin_rounded, sourceCtrl, roleColor),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildInputField(dt, 'Amount (Ksh)', Icons.payments_rounded, amountCtrl, roleColor, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: method,
                        dropdownColor: dt.cardBg,
                        style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                        items: ['Cash', 'M-Pesa', 'Bank', 'Check'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) => method = v!,
                        decoration: InputDecoration(labelText: 'Method', prefixIcon: Icon(Icons.payment_rounded, color: roleColor)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInputField(dt, 'Reference / Receipt No.', Icons.sticky_note_2_rounded, refCtrl, roleColor),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: dt.cardBg,
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  items: ['Tuition', 'Uniform', 'Transport', 'Donation', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => category = v!,
                  decoration: InputDecoration(labelText: 'Revenue Category', prefixIcon: Icon(Icons.category_rounded, color: roleColor)),
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
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: roleColor, foregroundColor: Colors.white),
                    child: Text(isEditing ? 'COMMIT UPDATES' : 'SAVE INCOME', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
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

  Widget _buildInputField(DT dt, String label, IconData icon, TextEditingController ctrl, Color roleColor, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: roleColor, size: 20),
      ),
    );
  }

  Future<void> _deleteIncome(Map<String, dynamic> item) async {
    final dt = context.dt;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Delete Record?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Text('Remove entry for "${item['source']}" from the audit records?', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: TextStyle(color: dt.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: KagemaColors.parentRed, fontWeight: FontWeight.bold))),
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
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('REVENUE MANAGEMENT', 
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
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.account_balance_wallet_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)))]),
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
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : _income.isEmpty 
                ? _buildEmptyState(dt)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _income.length,
                    itemBuilder: (context, index) {
                      final item = _income[index];
                      final methodColor = item['payment_method'] == 'M-Pesa' ? KagemaColors.teacherGreen : KagemaColors.staffSky;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: theme.buildGlowContainer(
                          accentColor: methodColor,
                          borderRadius: 24,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: dt.roleSoftBg(methodColor), shape: BoxShape.circle),
                              child: Icon(Icons.add_chart_rounded, color: methodColor, size: 24),
                            ),
                            title: Text(item['source']?.toString().toUpperCase() ?? 'INCOME', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('${item['category']} • ${item['payment_method']}\n${item['date']}', 
                                style: TextStyle(fontSize: 11, height: 1.4, fontWeight: FontWeight.w600, color: dt.textSecondary)
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Ksh ${NumberFormat('#,###').format(item['amount'])}', 
                                  style: TextStyle(fontWeight: FontWeight.w900, color: methodColor, fontSize: 16)
                                ),
                                const SizedBox(height: 4),
                                Text(item['reference']?.toString().toUpperCase() ?? '', 
                                  style: TextStyle(fontSize: 8, color: dt.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1)
                                ),
                              ],
                            ),
                            onLongPress: () => _deleteIncome(item),
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
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(),
          backgroundColor: roleColor,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('ADD REVENUE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
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
          Text('NO REVENUE RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
