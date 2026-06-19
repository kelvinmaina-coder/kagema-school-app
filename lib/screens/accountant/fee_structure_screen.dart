import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../services/pdf_generator_service.dart';
import '../../app_theme.dart';

class FeeStructureScreen extends StatefulWidget {
  const FeeStructureScreen({super.key});

  @override
  State<FeeStructureScreen> createState() => _FeeStructureScreenState();
}

class _FeeStructureScreenState extends State<FeeStructureScreen> {
  List<Map<String, dynamic>> _feeStructure = [];
  bool _isLoading = true;
  final String _currentYear = DateTime.now().year.toString();
  final String _roleId = 'accountant';

  @override
  void initState() {
    super.initState();
    _loadStructure();
  }

  Future<void> _loadStructure() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final structure = await SupabaseService.instance.getFeeStructure();
      if (mounted) {
        setState(() {
          _feeStructure = structure;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fee Structure Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditDialog({String? grade, double? amount}) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final roleColor = RoleColors.of(_roleId);
    
    final List<String> availableGrades = [
      'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6',
      'JSS 1', 'JSS 2', 'JSS 3', 'Form 1', 'Form 2', 'Form 3', 'Form 4'
    ];
    
    String? selectedGrade = grade;
    final controller = TextEditingController(text: amount?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 35,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(grade == null ? 'NEW FEE ENTRY' : 'EDIT STRUCTURE', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(grade == null ? 'Configure Fees' : 'Update Grade Fees', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)
                ),
                const SizedBox(height: 32),
                if (grade == null)
                  DropdownButtonFormField<String>(
                    value: selectedGrade,
                    dropdownColor: dt.cardBg,
                    style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                    decoration: _inputDecoration(dt, 'Select Grade', Icons.school_rounded, roleColor),
                    items: availableGrades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) => selectedGrade = v,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dt.roleSoftBg(roleColor),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: roleColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: roleColor, size: 20),
                        const SizedBox(width: 12),
                        Text('Managing fees for $grade', style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary)),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  decoration: _inputDecoration(dt, 'Termly Fee (Ksh)', Icons.payments_rounded, roleColor),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedGrade != null && controller.text.isNotEmpty) {
                        try {
                          await SupabaseService.instance.updateFeeStructure(
                            selectedGrade!, 
                            double.parse(controller.text)
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            _loadStructure();
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed. Please check connection.')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: roleColor, foregroundColor: Colors.white),
                    child: Text(grade == null ? 'SAVE FEE' : 'UPDATE STRUCTURE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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

  InputDecoration _inputDecoration(DT dt, String label, IconData icon, Color roleColor) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: roleColor, size: 20),
    );
  }

  void _deleteStructure(String grade) async {
    final dt = context.dt;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Delete Fee Record?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Text('This will erase the fee structure for $grade. Student balances might be affected.', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: TextStyle(color: dt.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE', style: TextStyle(color: KagemaColors.parentRed, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.client.from('fee_structure').delete().eq('grade', grade);
        _loadStructure();
      } catch (e) {
        debugPrint("Delete Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('FEE CONFIGURATION', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
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
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.account_tree_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Colors.white),
            tooltip: 'Generate PDF',
            onPressed: () => PdfGeneratorService.generateFeeStructure(_feeStructure, _currentYear),
          ),
        ],
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : Column(
                  children: [
                    _buildHeaderStats(dt, theme, roleColor),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _feeStructure.isEmpty
                          ? _buildEmptyState(dt)
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: _feeStructure.length,
                              itemBuilder: (context, index) {
                                final item = _feeStructure[index];
                                return _buildStructureCard(dt, theme, item, roleColor);
                              },
                            ),
                    ),
                  ],
                ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showEditDialog(),
          backgroundColor: roleColor,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('ADD FEE RECORD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildHeaderStats(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    double totalAnnualPotential = _feeStructure.fold(0.0, (sum, item) => sum + ((item['total_fee'] as num? ?? 0.0).toDouble() * 3));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: 28,
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GRADES CONFIGURED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('${_feeStructure.length}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dt.textPrimary)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('AVG ANNUAL FEE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(
                  'Ksh ${NumberFormat("#,##0").format(_feeStructure.isEmpty ? 0 : totalAnnualPotential / _feeStructure.length)}', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: roleColor)
                ),
              ],
            ),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildStructureCard(DT dt, GeminiThemeExtension? theme, Map<String, dynamic> item, Color roleColor) {
    final String grade = item['grade'] ?? 'Unknown';
    final double amount = (item['total_fee'] as num? ?? 0.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: theme?.buildGlowContainer(
        accentColor: KagemaColors.staffSky,
        borderRadius: 24,
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.staffSky), shape: BoxShape.circle),
            child: const Icon(Icons.school_rounded, color: KagemaColors.staffSky, size: 24),
          ),
          title: Text(grade.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary, letterSpacing: 0.5)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Termly: Ksh ${NumberFormat("#,##0").format(amount)}', 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dt.textSecondary)
              ),
              Text('Annual Total: Ksh ${NumberFormat("#,##0").format(amount * 3)}', 
                style: TextStyle(fontSize: 10, color: dt.textMuted, fontWeight: FontWeight.w800, letterSpacing: 0.5)
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: KagemaColors.staffSky),
                onPressed: () => _showEditDialog(grade: grade, amount: amount),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: KagemaColors.parentRed),
                onPressed: () => _deleteStructure(grade),
              ),
            ],
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO FEE STRUCTURES DEFINED', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
