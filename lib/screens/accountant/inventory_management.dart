import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class InventoryManagement extends StatefulWidget {
  const InventoryManagement({super.key});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement> {
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final list = await SupabaseService.instance.getInventory();
      if (mounted) {
        setState(() {
          items = list;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Inventory Sync Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showItemForm({Map<String, dynamic>? item}) {
    final theme = Theme.of(context);
    final nameCtrl = TextEditingController(text: item?['name']);
    final qtyCtrl = TextEditingController(text: item?['quantity']?.toString());
    final valCtrl = TextEditingController(text: item?['value']?.toString());
    String category = item?['category'] ?? 'Furniture';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item == null ? 'Register New Asset' : 'Edit Asset Details',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.primaryColor),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Asset Name', prefixIcon: Icon(Icons.inventory_2_rounded)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: category,
              items: ['Furniture', 'Electronics', 'Books', 'Sports', 'Lab'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => category = v!,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity', prefixIcon: Icon(Icons.numbers_rounded)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: valCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Unit Value', prefixIcon: Icon(Icons.payments_rounded), prefixText: 'Ksh '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                    final data = {
                      'item_id': item?['item_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      'name': nameCtrl.text.trim(),
                      'category': category,
                      'quantity': int.tryParse(qtyCtrl.text) ?? 0,
                      'value': double.tryParse(valCtrl.text) ?? 0.0,
                    };
                    await SupabaseService.instance.insertInventory(data);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadInventory();
                    }
                  }
                },
                child: Text(item == null ? 'ADD TO REGISTER' : 'SAVE CHANGES', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeroAppBar(theme, gemini),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(theme),
                    const SizedBox(height: 32),
                    Text('REGISTERED ASSETS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor.withOpacity(0.5), letterSpacing: 2)),
                    const SizedBox(height: 16),
                    _buildInventoryList(theme),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemForm(),
        backgroundColor: theme.primaryColor,
        label: const Text('ADD ASSET', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 160.0,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ASSET TRACKING', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text('Property Register', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white)),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.brown.shade800]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    double totalValue = items.fold(0.0, (sum, item) => sum + ((item['value'] ?? 0.0) * (item['quantity'] ?? 0)));
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(28)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: theme.primaryColor.withOpacity(0.1), child: Icon(Icons.analytics_rounded, color: theme.primaryColor)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ESTIMATED ASSET VALUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('Ksh ${totalValue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(ThemeData theme) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return const Center(child: Text('No records in cloud database.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)));

    return Column(
      children: items.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.category_rounded, color: theme.primaryColor, size: 20),
            ),
            title: Text(item['name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${item['category']} • ${item['quantity']} units'),
            trailing: Text('Ksh ${item['value']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green)),
            onTap: () => _showItemForm(item: item),
          ),
        );
      }).toList(),
    );
  }
}
