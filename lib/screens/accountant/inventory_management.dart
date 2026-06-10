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
    final nameCtrl = TextEditingController(text: item?['name']);
    final qtyCtrl = TextEditingController(text: item?['quantity']?.toString());
    final valCtrl = TextEditingController(text: item?['value']?.toString());
    String category = item?['category'] ?? 'Furniture';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
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
            if (item != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () => _confirmDelete(item['item_id']),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  child: const Text('REMOVE ASSET', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset?'),
        content: const Text('This action will permanently remove the item from the cloud register.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.instance.deleteInventory(id);
              if (mounted) {
                Navigator.pop(context); // dialog
                Navigator.pop(context); // sheet
                _loadInventory();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroAppBar(theme, gemini),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryGlow(theme, gemini),
                  const SizedBox(height: 32),
                  Text('REGISTERED ASSETS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor.withOpacity(0.5), letterSpacing: 2)),
                  const SizedBox(height: 16),
                  _buildInventoryList(theme, gemini),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
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
      backgroundColor: theme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ASSET TRACKING', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text('Property Register', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5, color: Colors.white)),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: gemini?.primaryGradient ?? LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -10,
                child: Icon(Icons.account_balance_wallet_rounded, size: 200, color: Colors.white.withOpacity(0.05)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryGlow(ThemeData theme, GeminiThemeExtension? gemini) {
    double totalValue = items.fold(0.0, (sum, item) => sum + ((item['value'] ?? 0.0) * (item['quantity'] ?? 0)));

    return gemini?.buildGlowContainer(
      backgroundColor: theme.cardColor,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.analytics_rounded, color: theme.primaryColor),
          ),
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
    ) ?? Container();
  }

  Widget _buildInventoryList(ThemeData theme, GeminiThemeExtension? gemini) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text('No school property recorded yet in cloud', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.category_rounded, color: theme.primaryColor, size: 20),
            ),
            title: Text(item['name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            subtitle: Text('${item['category']} • ${item['quantity']} units', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            trailing: Text('Ksh ${item['value']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green)),
            onTap: () => _showItemForm(item: item),
          ),
        );
      }).toList(),
    );
  }
}
