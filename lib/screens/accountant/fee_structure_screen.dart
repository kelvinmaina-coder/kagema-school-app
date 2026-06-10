import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class FeeStructureScreen extends StatefulWidget {
  const FeeStructureScreen({super.key});

  @override
  State<FeeStructureScreen> createState() => _FeeStructureScreenState();
}

class _FeeStructureScreenState extends State<FeeStructureScreen> {
  List<Map<String, dynamic>> _feeStructure = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStructure();
  }

  Future<void> _loadStructure() async {
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

  void _editFee(String grade, double currentAmount) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: currentAmount.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Fee for $grade', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Total Fee Amount (Ksh)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await SupabaseService.instance.updateFeeStructure(grade, double.parse(controller.text));
                  if (mounted) {
                    Navigator.pop(context);
                    _loadStructure();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee structure updated in cloud')));
                  }
                } catch (e) {
                  debugPrint("Update Fee Error: $e");
                }
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Fee Structure Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo, Colors.indigo.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _feeStructure.length,
                  itemBuilder: (context, index) {
                    final item = _feeStructure[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                          child: const Icon(Icons.account_tree, color: Colors.indigo),
                        ),
                        title: Text(item['grade'] ?? 'Unknown Grade', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Total Term Fee'),
                        trailing: Text('Ksh ${item['total_fee']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo, fontSize: 16)),
                        onTap: () => _editFee(item['grade'], (item['total_fee'] as num).toDouble()),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
