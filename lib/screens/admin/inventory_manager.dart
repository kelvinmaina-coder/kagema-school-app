import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class InventoryManagerScreen extends StatefulWidget {
  const InventoryManagerScreen({super.key});

  @override
  State<InventoryManagerScreen> createState() => _InventoryManagerScreenState();
}

class _InventoryManagerScreenState extends State<InventoryManagerScreen> {
  List<Map<String, dynamic>> _inventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      // Switched to Supabase Service
      final data = await SupabaseService.instance.getInventory();
      if (mounted) {
        setState(() {
          _inventory = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Inventory Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStock(String itemId, int currentQty, int change) async {
    final newQty = currentQty + change;
    if (newQty < 0) return;

    try {
      await SupabaseService.instance.updateStock(itemId, newQty);
      _fetchInventory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cloud sync failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Stores'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _inventory.length,
              itemBuilder: (context, index) {
                final item = _inventory[index];
                final qty = item['quantity'] ?? 0;
                final isLow = qty <= 5;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Icon(
                      isLow ? Icons.warning_amber_rounded : Icons.inventory_2, 
                      color: isLow ? Colors.red : Colors.brown
                    ),
                    title: Text(item['name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Category: ${item['category'] ?? 'General'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateStock(item['item_id'], qty, -1)),
                        Text('$qty', style: TextStyle(fontWeight: FontWeight.bold, color: isLow ? Colors.red : null)),
                        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateStock(item['item_id'], qty, 1)),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
