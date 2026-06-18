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
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
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
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: gemini?.buildCreativeBackground(
          isDark: theme.brightness == Brightness.dark,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(grade == null ? 'NEW FEE ENTRY' : 'EDIT STRUCTURE', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(grade == null ? 'Configure Fees' : 'Update Grade Fees', 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                ),
                const SizedBox(height: 32),
                if (grade == null)
                  DropdownButtonFormField<String>(
                    value: selectedGrade,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    decoration: _inputDecoration('Select Grade', Icons.school_rounded, theme),
                    items: availableGrades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) => selectedGrade = v,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: theme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Text('Managing fees for $grade', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: _inputDecoration('Termly Fee (Ksh)', Icons.payments_rounded, theme),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Fees updated for $selectedGrade'), 
                                backgroundColor: Colors.green.shade800,
                                behavior: SnackBarBehavior.floating,
                              )
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed. Please check connection.')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade800, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                    child: Text(grade == null ? 'SAVE FEE' : 'UPDATE STRUCTURE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox(),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.indigo, size: 20),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }

  void _deleteStructure(String grade) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Fee Record?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('This will erase the fee structure for $grade. Student balances might be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
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
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Fee Management', 
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
              colors: [Colors.indigo.shade900, Colors.indigo.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.account_tree_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
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
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
            : Column(
                children: [
                  _buildHeaderStats(theme, gemini),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _feeStructure.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: _feeStructure.length,
                            itemBuilder: (context, index) {
                              final item = _feeStructure[index];
                              return _buildStructureCard(theme, gemini, item);
                            },
                          ),
                  ),
                ],
              ),
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: Colors.indigo.shade800,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showEditDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Fee Record', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildHeaderStats(ThemeData theme, GeminiThemeExtension? gemini) {
    double totalAnnualPotential = _feeStructure.fold(0.0, (sum, item) => sum + ((item['total_fee'] as num? ?? 0.0).toDouble() * 3));
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GRADES CONFIGURED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('${_feeStructure.length}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('AVERAGE ANNUAL FEE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(
              'Ksh ${NumberFormat("#,##0").format(_feeStructure.isEmpty ? 0 : totalAnnualPotential / _feeStructure.length)}', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.primaryColor)
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 28,
        borderThickness: 1.5,
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

  Widget _buildStructureCard(ThemeData theme, GeminiThemeExtension? gemini, Map<String, dynamic> item) {
    final String grade = item['grade'] ?? 'Unknown';
    final double amount = (item['total_fee'] as num? ?? 0.0).toDouble();

    final content = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.school_rounded, color: Colors.indigo, size: 24),
      ),
      title: Text(grade, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Termly: Ksh ${NumberFormat("#,##0").format(amount)}', 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
          ),
          Text('Annual Total: Ksh ${NumberFormat("#,##0").format(amount * 3)}', 
            style: TextStyle(fontSize: 10, color: Colors.indigo.withOpacity(0.6), fontWeight: FontWeight.w900, letterSpacing: 0.5)
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
            onPressed: () => _showEditDialog(grade: grade, amount: amount),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () => _deleteStructure(grade),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('NO FEE STRUCTURES DEFINED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
